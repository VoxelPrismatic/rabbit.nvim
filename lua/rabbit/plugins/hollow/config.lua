--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

---@class (exact) Rabbit*Hollow.Options: Rabbit.Plugin.Options
---@field sort
---| "time" # Most recently opened workspace
---| "name" # Sort by workspace name
---| "none" # Custom sorting algorithm

---@type Rabbit*Hollow.Options
local PLUGIN_CONFIG = {
	color = "#b4b433",
	keys = {
		switch = "w",
	},

	sort = "time",
}

return PLUGIN_CONFIG
