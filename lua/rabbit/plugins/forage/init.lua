local LIST = require("rabbit.plugins.forage.list")

---@class (exact) Rabbit*Forage: Rabbit.Plugin
---@field opts Rabbit*Forage.Options
---@field _env Rabbit*Forage.Environment

---@type Rabbit*Forage
local PLUG = {
	synopsis = "Forage through the filesystem until you find what you're looking for",
	version = "r0.0a1",
	empty = {
		msg = "Whoops! Something went disasterously wrong, this message should never appear!",
		actions = {},
	},
	name = "forage",
	actions = require("rabbit.plugins.forage.actions"),
	events = require("rabbit.plugins.forage.autocmd"),
	save = "forage.json",
	_env = require("rabbit.plugins.forage.env"),
	opts = require("rabbit.plugins.forage.config"),
	requires = {
		"trail",
	},
}
