---@class (exact) Rabbit*Harpoon.Options: Rabbit.Plugin.Options
---@field default_color Rabbit.Colors.Paint Color to use for new collections
---@field by_buffer boolean Separate Harpoon listings by buffer

---@type Rabbit*Harpoon.Options
local PLUGIN_CONFIG = {
	color = "#696ac2",
	default_color = "iris",
	by_buffer = false,
	keys = {
		switch = "h",
	},
	cwd = require("rabbit.util.paths").git,
}

return PLUGIN_CONFIG
