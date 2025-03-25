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
			if #word > 7 then
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

return TERM
