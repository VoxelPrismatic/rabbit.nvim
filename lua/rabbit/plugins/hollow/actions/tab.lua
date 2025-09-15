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

---@param entry Rabbit*Hollow.C.Tab
function ACTIONS.children(entry)
	local tab = entry.ctx.real
	local leaf = entry.ctx.leaf
	local bound = NVIM.bind(MAKE.win, leaf, tab)
	local winobjs = {} ---@type Rabbit*Hollow.SaveFile.Win[]
	local bufids = SET.new() ---@type Rabbit.Table.Set<integer>
	local layout = { vim.deepcopy(tab.layout) }
	while #layout > 0 do
		local part = table.remove(layout, 1) ---@type vim.fn.winlayout.ret
		if part[1] == "leaf" then
			local win = leaf.win_specs[tostring(part[2])]
			table.insert(winobjs, win)
			bufids:add(win.bufs)
		else
			part = part --[[@as vim.fn.winlayout.branch]]
			for i, branch in ipairs(part[2]) do
				table.insert(layout, i, branch)
			end
		end
	end

	local ret = SET.imap(winobjs, bound) --[[@as Rabbit.Entry[]=]]

	if ret[ENV.default] ~= nil then
		ret[ENV.default].default = true
	end

	ENV.default = 0

	local up = { ---@type Rabbit.Entry.Collection
		class = "entry",
		type = "collection",
		idx = GLOBAL_CONFIG.icons.entry_up,
		label = {
			text = "All Tabs",
			hl = { "rabbit.types.collection", "rabbit.paint.gold" },
		},
		tail = {
			text = tab.name .. " ",
			hl = { "rabbit.types.index" },
			align = "right",
		},
		ctx = {
			type = "leaf",
			real = leaf,
		},
		actions = {
			children = true,
			parent = ACTIONS.parent,
			select = true,
		},
	}

	table.insert(ret, 1, up)

	for _, bufnr in ipairs(bufids) do
		local buf = leaf.buf_order[bufnr]
		local b = LIST.bufs[buf]
		---@type Rabbit*Trail.Buf
		local a = {
			class = "entry",
			type = "file",
			actions = {
				select = true,
				hover = true,
				parent = ACTIONS.parent,
			},
			closed = b.closed,
			ctx = {
				listed = true,
				leaf = leaf,
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

---@param entry Rabbit*Hollow.C.Tab
function ACTIONS.parent(entry)
	ENV.default = SET.idx(LIST.hollow[ENV.last_cwd], entry.ctx.leaf) or 0
	return MAKE.leaf(entry.ctx.leaf)
end

return ACTIONS
