---@class (exact) Rabbit*Carrot.Options: Rabbit.Plugin.Options
---@field default_color Rabbit.Colors.Paint Color to use for new collections
---@field separate "never" | "buffer" | "window" Separate collections by buffer, window, or never

---@type Rabbit*Carrot.Options
local PLUGIN_CONFIG = {
	color = "#696ac2",
	default_color = "iris",
	separate = "never",
	keys = {
		switch = "h",
	},
	cwd = require("rabbit.util.paths").git,
}

return PLUGIN_CONFIG
