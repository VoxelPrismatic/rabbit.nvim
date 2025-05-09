local LIST = require("rabbit.plugins.hollow.list")
local ENV = require("rabbit.plugins.hollow.env")
local MEM = require("rabbit.util.mem")
local SET = require("rabbit.util.set")
local GLOBAL_CONFIG = require("rabbit.config")
local MAKE = require("rabbit.plugins.hollow.make")
local NVIM = require("rabbit.util.nvim")

---@type Rabbit.Plugin.Actions
local ACTIONS = {}

---@param entry Rabbit*Hollow.C.Leaf
function ACTIONS.children(entry)
	local leaf = entry.ctx.real
	local bound = NVIM.bind(MAKE.tab, leaf)
	local ret = SET.imap(leaf.tab_layout, bound)

	local up = { ---@type Rabbit.Entry.Collection
		class = "entry",
		type = "collection",
		idx = GLOBAL_CONFIG.icons.entry_up,
		label = {
			text = "All Workspaces",
			hl = { "rabbit.types.collection", "rabbit.paint.gold" },
		},
		ctx = {
			type = "major",
			key = ENV.last_cwd,
			real = LIST.hollow[ENV.last_cwd],
		},
		actions = {
			children = true,
			parent = true,
			select = true,
		},
	}

	table.insert(ret, 1, up)

	for _, buf in ipairs(leaf.buf_order) do
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

function ACTIONS.parent(_)
	return LIST.hollow[ENV.last_cwd]
end

---@param entry Rabbit*Hollow.C.Leaf
local function collection_collect_names(entry)
	local names = {}
	for _, sv in ipairs(LIST.hollow[ENV.last_cwd]) do
		names[sv.name] = true
	end
	names[entry.ctx.real.name] = false
	return names
end

---@param entry Rabbit*Hollow.C.Leaf
---@param name string
local function check_rename(entry, name)
	if name == "" then
		name = string.format("%04x", math.random(0, 65535))
	end

	local names = collection_collect_names(entry)

	return MEM.next_name(names, name)
end

---@param entry Rabbit*Hollow.C.Leaf
---@param name string
local function apply_rename(entry, name)
	name = check_rename(entry, name)
	entry.ctx.real.name = name
	entry.label.text = name

	LIST.hollow:__Save()
	return name
end

local function apply_color(entry, color)
	entry.ctx.real.color = color
	entry.label.hl = {
		"rabbit.types.collection",
		"rabbit.paint." .. color,
	}
	LIST.hollow:__Save()
end

---@param entry Rabbit*Hollow.C.Leaf
function ACTIONS.rename(entry)
	entry = entry --[[@as Rabbit*Hollow.C.Leaf]]
	return { ---@type Rabbit.Message.Rename
		class = "message",
		type = "rename",
		apply = apply_rename,
		check = check_rename,
		color = {
			class = "message",
			type = "color",
			apply = apply_color,
			color = entry.ctx.real.color,
		},
		name = entry.ctx.real.name,
		entry = entry,
	}
end

---@param entry Rabbit*Hollow.C.Major | Rabbit*Hollow.C.Leaf
function ACTIONS.collect(entry)
	local folder = LIST.hollow[ENV.last_cwd]
	local new_save = LIST.save("", "iris")

	local new_collection = MAKE.leaf(new_save)

	if entry._env == nil then
		table.insert(folder, new_save)
	else
		table.insert(folder, math.max(1, entry._env.idx - 1), new_save)
	end

	LIST.hollow:__Save()
	return LIST.major[ENV.last_cwd], ACTIONS.rename(new_collection)
end

return ACTIONS
