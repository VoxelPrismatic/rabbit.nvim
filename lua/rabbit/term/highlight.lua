-- Will create a new highlight group
---@param color Color | NvimHlKwargs The color to use for the highlight group. If a string, it will create a new table with [key] = color
---@param key? "fg" | "bg" The key to use for the color. If [color] is a table, this is ignored.
---@return vim.api.keyset.highlight The highlight group
local function get_hl_group(color, key)
	if type(color) == "string" then
		color = { [key or "fg"] = color }
	end
	return color
end
