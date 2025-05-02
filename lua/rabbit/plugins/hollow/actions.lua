local LIST = require("rabbit.plugins.hollow.list")
local ENV = require("rabbit.plugins.hollow.env")
local MEM = require("rabbit.util.mem")
local SET = require("rabbit.util.set")

---@type Rabbit.Plugin.Actions
local ACTIONS = {}

---@param entry Rabbit*Hollow.Collection | Rabbit*Hollow.Major
function ACTIONS.children(entry)
	assert(entry.ctx ~= nil, "Unknown collection type")
	if entry.ctx.type == "major" then
		entry = entry --[[@as Rabbit*Hollow.Major]]

		ENV.last_cwd = entry.ctx.key

		return SET.imap(entry.ctx.real, LIST.make_collection)
	end

	error("Not implemented")
end

function ACTIONS.parent(entry)
	return LIST.major[ENV.last_cwd]
end

---@param entry Rabbit*Hollow.Collection
local function collection_collect_names(entry)
	local names = {}
	for _, sv in ipairs(LIST.hollow[ENV.last_cwd]) do
		names[sv.name] = true
	end
	names[entry.ctx.real.name] = false
	return names
end

---@param entry Rabbit*Hollow.Collection
---@param name string
local function check_rename(entry, name)
	if name == "" then
		name = string.format("%04x", math.random(0, 65535))
	end

	local names = collection_collect_names(entry)

	return MEM.next_name(names, name)
end

---@param entry Rabbit*Hollow.Collection
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

---@param entry Rabbit*Hollow.Collection
function ACTIONS.rename(entry)
	if entry.ctx.type == "leaf" then
		entry = entry --[[@as Rabbit*Hollow.Collection]]
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

	error("Not implemented")
end

---@param entry Rabbit*Hollow.Major | Rabbit*Hollow.Collection
function ACTIONS.collect(entry)
	local folder = LIST.hollow[ENV.last_cwd]
	local new_save = LIST.save("", "iris")
	local new_collection = LIST.make_collection(new_save)

	if entry._env == nil then
		table.insert(folder, new_save)
	else
		table.insert(folder, math.max(1, entry._env.idx - 1), new_save)
	end

	LIST.hollow:__Save()
	return LIST.major[ENV.last_cwd], ACTIONS.rename(new_collection)
end

return ACTIONS
