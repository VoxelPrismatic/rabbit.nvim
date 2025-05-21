--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

local LIST = require("rabbit.plugins.hollow.list")
local NVIM = require("rabbit.util.nvim")
local MAKE = require("rabbit.plugins.hollow.make")
local SET = require("rabbit.util.set")
local ENV = require("rabbit.plugins.hollow.env")
local GLOBAL_CONFIG = require("rabbit.config")

---@type Rabbit.Plugin.Actions
local ACTIONS = {}

---@param entry Rabbit*Hollow.C.Win
function ACTIONS.children(entry)
	local ret = {} ---@type Rabbit.Entry[]
	local win = entry.ctx.real
	local tab = entry.ctx.tab
	local leaf = entry.ctx.leaf

	local up = { ---@type Rabbit.Entry.Collection
		class = "entry",
		type = "collection",
		idx = GLOBAL_CONFIG.icons.entry_up,
		label = {
			text = "All Windows",
			hl = { "rabbit.types.collection", "rabbit.paint.gold" },
		},
		tail = {
			text = win.name .. " ",
			hl = { "rabbit.types.index" },
			align = "right",
		},
		ctx = {
			type = "tab",
			real = tab,
			leaf = leaf,
		},
		actions = {
			children = true,
			parent = true,
			select = true,
		},
	}

	table.insert(ret, 1, up)

	for _, bufnr in ipairs(win.bufs) do
		local buf = leaf.buf_order[bufnr]
		local b = LIST.bufs[buf]
		---@type Rabbit*Trail.Buf
		local a = {
			class = "entry",
			type = "file",
			actions = {
				select = true,
				hover = true,
			},
			closed = b.closed,
			ctx = {
				listed = true,
			},
			target_winid = ENV.winid,
			bufid = b.bufid,
			path = b.path,
			as = b.as,
		}
		table.insert(ret, a)
	end

	return ret
end

---@param entry Rabbit*Hollow.C.Win
function ACTIONS.parent(entry)
	return MAKE.tab(entry.ctx.leaf, entry.ctx.tab)
end

return ACTIONS
