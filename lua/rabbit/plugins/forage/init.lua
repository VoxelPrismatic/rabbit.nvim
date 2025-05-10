--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

local LIST = require("rabbit.plugins.forage.list")
local GLOBAL_CONFIG = require("rabbit.config")

---@class (exact) Rabbit*Forage: Rabbit.Plugin
---@field opts Rabbit*Forage.Options
---@field _env Rabbit*Forage.Environment

---@type Rabbit*Forage
local PLUG = {
	synopsis = "Forage through the filesystem until you find what you're looking for",
	version = "r0.0b1",
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

function PLUG.setup(opts)
	PLUG.opts = vim.tbl_deep_extend("force", PLUG.opts, opts)
	LIST.load(GLOBAL_CONFIG.system.data .. PLUG.save)
end

function PLUG.list()
	return LIST.default
end

return PLUG
