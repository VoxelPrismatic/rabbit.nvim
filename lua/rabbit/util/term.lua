local TERM = {}

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
