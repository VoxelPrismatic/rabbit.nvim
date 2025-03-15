---@class (exact) Rabbit*Trail.Options: Rabbit.Plugin.Options
---@field ignore_unlisted boolean Ignore unlisted buffers

---@type Rabbit*Trail.Options
local PLUGIN_CONFIG = {
	color = "#d875a7",
	keys = {
		switch = "t",
	},

	ignore_unlisted = true,
}

return PLUGIN_CONFIG
