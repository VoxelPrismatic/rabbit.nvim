local TERM = {}

-- Wraps text into lines
---@param text string The text to wrap
---@param width number The width of the terminal
---@return string[]
function TERM.wrap(text, width)
	local lines = { "" }
	for _, word in text:gmatch("[^%s]+") do
		if #(lines[#lines] .. " " .. word) > width then
			table.insert(lines, "")
		end
		lines[#lines] = lines[#lines] .. " " .. word
	end
	return lines
end

return TERM
