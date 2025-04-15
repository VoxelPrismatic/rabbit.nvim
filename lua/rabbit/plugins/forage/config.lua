---@class (exact) Rabbit*Forage.Options: Rabbit.Plugin.Options
---@field fuzzy boolean Enable fuzzy find with `fzf`.
---@field grep boolean Enable grep-based search with `rg`.
---@field find boolean Enable classic-find with `find`.
---@field history_length integer Length of the history. Set to 0 to disable history.
---@field restore
---| "global" # All search tools will restore the last searched term among any search tool
---| "split" # Each search tool will restore its own last searched term
---| "never" # Search tools will open without restoring the last searched term

---@type Rabbit*Forage.Options
local PLUGIN_CONFIG = {
	color = "#33b473",
	keys = {
		switch = "f",
	},
	fuzzy = true,
	grep = true,
	find = true,
	history_length = 128,
	restore = "split",
}

return PLUGIN_CONFIG
