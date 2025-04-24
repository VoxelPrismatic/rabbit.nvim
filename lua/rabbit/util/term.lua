local WINCONFIG = require("rabbit.term.stack.winconfig")
local TERM = {}

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

-- Returns the syllables of a word
---@type table<string, string[]>
TERM.syllables = setmetatable({}, {
	---@param self table<string, string[]>
	---@param word string
	__index = function(self, word)
		assert(type(word) == "string", "Expected string, got " .. type(word))
		assert(word:find("%s") == nil, "Words cannot contain spaces")
		assert(#word > 0, "Words cannot be empty")

		local syllables = {}
		local ptr = 1
		local vowels = "[aeiou]"
		local consts = "[^aeiou]"

		while ptr <= #word do
			-- Next vowel group
			local vowel_start, vowel_end = word:find(vowels .. "+", ptr)

			if vowel_start == nil then
				break
			end

			-- Grab consonants around vowel group
			local before_vowel = word:sub(ptr, vowel_start - 1)
			local vowel_group = word:sub(vowel_start, vowel_end)
			local after_vowel = ""

			local const_start, const_end = word:find(consts .. "*", vowel_end + 1)
			if const_start ~= nil then
				after_vowel = word:sub(const_start, const_end)
			else
				const_end = vowel_end
			end

			-- Check if there are more vowels after const group
			local next_vowel = word:find(vowels, const_end + 1)
			if next_vowel and #after_vowel > 0 then
				after_vowel = after_vowel:sub(1, -2) -- Remove last char
				const_end = const_end - 1
			end

			table.insert(syllables, before_vowel .. vowel_group .. after_vowel)
			ptr = const_end + 1
		end

		if ptr <= #word then
			table.insert(syllables, word:sub(ptr))
		end

		self[word] = syllables
		return syllables
	end,
})

return TERM
