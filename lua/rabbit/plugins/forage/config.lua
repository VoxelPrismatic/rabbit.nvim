---@class (exact) Rabbit*Forage.Options: Rabbit.Plugin.Options
---@field fuzzy boolean Enable fuzzy find with `fzr`.
---@field grep boolean Enable grep-based search with `rg`.
---@field find boolean Enable classic-find with `find`.
---@field history_length integer Length of the history. Set to 0 to disable history.
---@field oxide Rabbit*Forage.Options.Oxide

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
	fuzzy = true,
	grep = true,
	find = true,
	history_length = 128,
	cwd = require("rabbit.util.paths").git,
	oxide = {
		max_age = 1000,
		children_only = true,
	},
}

return PLUGIN_CONFIG
