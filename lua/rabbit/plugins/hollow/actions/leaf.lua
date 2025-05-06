local LIST = require("rabbit.plugins.hollow.list")
local ENV = require("rabbit.plugins.hollow.env")
local MEM = require("rabbit.util.mem")
local SET = require("rabbit.util.set")
local GLOBAL_CONFIG = require("rabbit.config")

local ACTIONS = {}

---@type { [string]: Rabbit*Hollow.C.Tab }
local collection_cache = {}

---@param tabfile Rabbit*Hollow.SaveFile.Tab
---@return Rabbit*Hollow.C.Tab
function ACTIONS.Make_collection(tabfile)
	local addr = tostring(tabfile)
	if collection_cache[addr] == nil then
		---@class Rabbit*Hollow.C.Tab: Rabbit.Entry.Collection
		collection_cache[addr] = {
			class = "entry",
			type = "collection",
			idx = true,
			label = {
				text = tabfile.name,
				hl = {
					"rabbit.types.collection",
					"rabbit.paint." .. tabfile.color,
				},
			},
			actions = {
				children = true,
				select = true,
				parent = true,
				collect = true,
				rename = true,
			},
			---@class Rabbit*Hollow.C.Tab.Ctx
			ctx = {
				---@type string
				type = "tab",

				---@type Rabbit*Hollow.SaveFile.Tab
				real = tabfile,
			},
		}
	end

	return collection_cache[addr]
end

---@param entry Rabbit*Hollow.C.Leaf
function ACTIONS.children(entry)
	local ret = SET.imap(entry.ctx.real.tab_layout, ACTIONS.Make_collection)

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
			real = LIST.major[ENV.last_cwd],
		},
		actions = {
			children = true,
			parent = true,
		},
	}

	table.insert(ret, 1, up)
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
	local new_collection = require("rabbit.plugins.hollow.actions.major").Make_collection(new_save)

	if entry._env == nil then
		table.insert(folder, new_save)
	else
		table.insert(folder, math.max(1, entry._env.idx - 1), new_save)
	end

	LIST.hollow:__Save()
	return LIST.major[ENV.last_cwd], ACTIONS.rename(new_collection)
end

return ACTIONS
