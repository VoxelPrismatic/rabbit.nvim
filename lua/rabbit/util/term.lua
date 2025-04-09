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
---@return vim.api.keyset.win_config | nil "Nil if window doesn't exist"
function TERM.win_config(winid)
	local ok, conf = pcall(vim.api.nvim_win_get_config, winid)
	if not ok then
		return nil
	end

	conf.width = conf.width or vim.api.nvim_win_get_width(winid)
	conf.height = conf.height or vim.api.nvim_win_get_height(winid)
	if conf.row == nil or conf.col == nil then
		conf.row, conf.col = unpack(vim.api.nvim_win_get_position(winid))
	end

	return setmetatable(conf, {
		__call = function(self)
			local new_conf = TERM.win_config(winid)
			assert(new_conf ~= nil, "Invalid window ID: " .. winid)
			for k, v in pairs(new_conf) do
				self[k] = v
			end
			return self
		end,
	})
end
return TERM
