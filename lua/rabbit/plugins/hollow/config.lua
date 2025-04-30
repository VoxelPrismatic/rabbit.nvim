---@class (exact) Rabbit*Hollow.Options: Rabbit.Plugin.Options
---@field sort_by_name
---| false # Sort by most recent
---| true # Sort by workspace name

---@type Rabbit*Hollow.Options
local PLUGIN_CONFIG = {
	color = "#b4b433",
	keys = {
		switch = "w",
	},

	sort_by_name = false,
}

return PLUGIN_CONFIG
