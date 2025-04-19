local WINCONFIG = require("rabbit.term.stack.winconfig")
local TERM = {}

-- Wraps text into lines
---@param text string The text to wrap
---@param width number The width of the terminal
---@return string[]
function TERM.wrap(text, width)
	local line = " "
	local lines = {}
	for word in text:gmatch("%S+") do
		if #(line .. word) + 1 >= width then
			local continue = ""
			local remainder = ""
			if #word / width > 0.1 then
				for syllable in word:gmatch("([aeiou]*[^aeiou]+)") do
					if #remainder > 0 then
						remainder = remainder .. syllable
					elseif #(continue .. syllable .. line) + 1 >= width then
						remainder = remainder .. syllable
					else
						continue = continue .. syllable
					end
				end

				if #continue < 5 then
					continue = ""
					remainder = word
				else
					continue = continue .. "—"
					remainder = "—" .. remainder
				end
			else
				remainder = word
			end

			table.insert(lines, line .. continue)
			line = " "
			word = remainder
		end

		line = line .. word .. " "
	end

	if #line > 0 then
		table.insert(lines, line)
	end
	return lines
end

-- Shorthand for vim.fn.feedkeys(vim.api.nvim_replace_termcodes(...), "n")
---@param keys string The text to feed
function TERM.feed(keys)
	vim.fn.feedkeys(vim.api.nvim_replace_termcodes(keys, true, true, true), "n")
end

-- Returns the current window configuration
---@return Rabbit.Stack.WinConfig | nil "Nil if window doesn't exist"
function TERM.win_config(winid)
	if not vim.api.nvim_win_is_valid(winid) then
		return nil
	end

	return WINCONFIG.New(winid)
end

-- Returns the real column number, taking into account UTF-8 characters
function TERM.realcol()
	local line = vim.fn.line(".")
	local col = vim.fn.col(".")

	return vim.fn.strdisplaywidth(vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1]:sub(1, col - 1))
end

-- Places the cursor at the real position
---@param row integer
---@param col integer
---@param win? integer Window ID (will use current buffer ID)
function TERM.realplace(row, col, win)
	win = win or 0
	local buf = vim.api.nvim_win_get_buf(win)
	local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]
	local chars = vim.fn.str2list(line)
	local real_col = 0
	for i = 1, math.min(col, #chars) do
		real_col = real_col + #vim.fn.nr2char(chars[i])
	end

	vim.api.nvim_win_set_cursor(win, { row, real_col })
end

-- String case functions
TERM.case = {
	-- UPPER CASE
	upper = string.upper,

	-- lower case
	lower = string.lower,

	-- Title Case
	---@param text string
	---@return string "The String In Title Case"
	---@return integer count
	title = function(text)
		return text:gsub("(%w)(%w*)", function(a, b)
			return string.upper(a) .. string.lower(b)
		end)
	end,

	-- Unchanged text
	---@param text string
	---@return string
	unchanged = function(text)
		return text
	end,
}

-- Returns the start and end indexes, and exits visual mode
---@param escape? boolean Exit visual mode (default: true)
---@return integer start_idx
---@return integer end_idx
function TERM.get_yank(escape)
	if escape == nil or escape then
		TERM.feed("<Esc>")
	end
	local start_idx = vim.fn.getpos("v")[2]
	local end_idx = vim.fn.getpos(".")[2]
	if start_idx > end_idx then
		start_idx, end_idx = end_idx, start_idx
	end

	return start_idx, end_idx
end

return TERM
