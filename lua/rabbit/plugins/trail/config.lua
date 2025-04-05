---@class (exact) Rabbit*Trail.Options: Rabbit.Plugin.Options
---@field ignore_unlisted boolean Ignore unlisted buffers
---@field sort_wins boolean Sort by Window Name

---@type Rabbit*Trail.Options
local PLUGIN_CONFIG = {
	color = "#d875a7",
	keys = {
		switch = "t",
	},

	ignore_unlisted = true,
	sort_wins = false,
}

return PLUGIN_CONFIG
