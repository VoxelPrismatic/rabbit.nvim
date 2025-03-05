local HL = {}

-- Will create a new highlight group
---@param color Color | NvimHlKwargs The color to use for the highlight group. If a string, it will create a new table with [key] = color
---@param key? "fg" | "bg" The key to use for the color. If [color] is a table, this is ignored.
---@return vim.api.keyset.highlight The highlight group
function HL.gen_group(color, key)
	if type(color) == "string" then
		color = { [key or "fg"] = color }
	end

	if type(color) ~= "table" then
		error("Expected string or table, got " .. type(color))
	end

	for k, v in pairs(color) do
		if type(v) == "string" and v:sub(1, 1) == ":" then
			color[k] = vim.fn.synIDattr(vim.fn.hlID(v:sub(2)), k)
		end
	end

	return color
end

function HL.apply()
	local hl = require("rabbit.config").colors

	for k, v in pairs(hl.types) do
		vim.api.nvim_set_hl(0, "rabbit.type." .. k, HL.gen_group(v))
	end

	for k, v in pairs(hl.paint) do
		vim.api.nvim_set_hl(0, "rabbit.paint." .. k, HL.gen_group(v))
	end

	for k, v in pairs(hl.popup) do
		vim.api.nvim_set_hl(0, "rabbit.popup." .. k, HL.gen_group(v))
	end
end

return HL
