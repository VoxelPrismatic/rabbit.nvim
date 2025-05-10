--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

local LIST = require("rabbit.plugins.hollow.list")
local GLOBAL_CONFIG = require("rabbit.config")

---@class (exact) Rabbit*Hollow: Rabbit.Plugin
---@field opts Rabbit*Hollow.Options
---@field _env Rabbit*Hollow.Environment

---@type Rabbit*Hollow
local PLUG = {
	synopsis = "Create and restore workspaces, including window layout and buffer history",
	version = "r0.0a",
	empty = {
		msg = "There's no workspace to restore! Get started by creating a workspace",
		actions = {
			collect = true,
		},
	},
	name = "hollow",
	actions = require("rabbit.plugins.hollow.actions"),
	events = require("rabbit.plugins.hollow.autocmd"),
	save = "hollow.json",
	_env = require("rabbit.plugins.hollow.env"),
	opts = require("rabbit.plugins.hollow.config"),
	requires = {
		"trail",
	},
}

function PLUG.setup(opts)
	PLUG.opts = vim.tbl_deep_extend("force", PLUG.opts, opts)
	LIST.load(GLOBAL_CONFIG.system.data .. PLUG.save)
end

function PLUG.list()
	return LIST.major[PLUG._env.cwd.value]
end

return PLUG
