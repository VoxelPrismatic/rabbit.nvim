--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

---@class (exact) Rabbit*Obsidian: Rabbit.Plugin
---@field opts Rabbit*Obisdian.Options
---@field _env Rabbit*Obsidian.Environment

---@type Rabbit*Obsidian
local PLUG = {
	synopsis = "Picker for Obsidian.nvim",
	version = "r0.0a",
	empty = {
		msg = "Something went disasterously wrong",
		actions = {},
	},
	name = "obsidian",
}
