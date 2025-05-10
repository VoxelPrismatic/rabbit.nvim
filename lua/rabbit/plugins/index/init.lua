--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

---@class (exact) Rabbit*Index: Rabbit.Plugin
---@field opts Rabbit*Index.Options

---@type Rabbit*Index
local PLUG = {
	synopsis = "List all the plugins you have installed and their synopses",
	version = "r1.0",
	empty = {
		msg = "You have no plugins installed!",
		actions = {},
	},
	name = "index",
	actions = require("rabbit.plugins.index.actions"),
	events = {},
	save = false,
	_env = {},
	opts = require("rabbit.plugins.index.config"),
}

function PLUG.setup(opts)
	PLUG.opts = vim.tbl_deep_extend("force", PLUG.opts, opts)
end

function PLUG.list()
	return { ---@type Rabbit.Entry.Collection
		class = "entry",
		type = "collection",
		label = {
			text = "All Plugins",
			hl = { "rabbit.paint.gold" },
		},
		actions = {
			select = true,
			children = true,
			parent = false,
			delete = false,
		},
	}
end

return PLUG
