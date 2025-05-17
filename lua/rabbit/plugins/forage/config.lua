--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

---@class (exact) Rabbit*Forage.Options: Rabbit.Plugin.Options
---@field fuzzy Rabbit*Forage.Options.Search Fuzzy find with `fzr`.
---@field grep Rabbit*Forage.Options.Search Enable grep-based search with `rg`.
---@field history_length integer Length of the history. Set to 0 to disable history.
---@field oxide Rabbit*Forage.Options.Oxide

---@class Rabbit*Forage.Options.Search
---@field enabled boolean Whether to enable this search format
---@field timeout integer How long the process can run for before dying

---@class (exact) Rabbit*Forage.Options.Oxide
---@field max_age integer Maximum age of a frequently accessed file, similar to Zoxide's AGING algorithm.
---@field children_only boolean Do not display files outside of the current working directory \
---Note: This only works if the `cwd` function returns a directory

---@type Rabbit*Forage.Options
local PLUGIN_CONFIG = {
	color = "#33b473",
	---@diagnostic disable-next-line: missing-fields
	keys = {
		switch = "f",
	},
	fuzzy = {
		enabled = true,
		timeout = 1000,
	},
	grep = {
		enabled = true,
		timeout = 1000,
	},
	history_length = 128,
	cwd = require("rabbit.util.paths").git,
	oxide = {
		max_age = 1000,
		children_only = true,
	},
}

return PLUGIN_CONFIG
