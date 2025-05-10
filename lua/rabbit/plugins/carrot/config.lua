--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

---@class (exact) Rabbit*Carrot.Options: Rabbit.Plugin.Options
---@field default_color Rabbit.Colors.Paint Color to use for new collections.
---@field separate: Separate collections by buffer or window.
---| "global" # All buffers and windows share the same list.
---| "buffer" # Each buffer will remember its last collection.
---| "window" # Each window will remember its last collection.
---| "never" # Always return the root collection. Recommended for building muscle memory.

---@type Rabbit*Carrot.Options
local PLUGIN_CONFIG = {
	color = "#696ac2",
	default_color = "iris",
	separate = "never",
	---@diagnostic disable-next-line: missing-fields
	keys = {
		switch = "h",
	},
	cwd = require("rabbit.util.paths").git,
}

return PLUGIN_CONFIG
