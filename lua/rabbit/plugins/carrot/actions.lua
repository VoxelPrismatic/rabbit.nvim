--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

local ENV = require("rabbit.plugins.carrot.env")
local LIST = require("rabbit.plugins.carrot.list")
local SET = require("rabbit.util.set")
local CONFIG = require("rabbit.config")
local ICONS = require("rabbit.util.icons")
local TERM = require("rabbit.util.term")
local MEM = require("rabbit.util.mem")
local NVIM = require("rabbit.util.nvim")
local INIT ---@type Rabbit*Carrot

-- Deep copy a collection
---@param id integer Collection ID
---@return table<integer, Rabbit*Carrot.Collection.Dump> collections Copied collections
---@return table<integer, integer> old_new_map Old ID -> New ID mapping
local function deep_copy_collection(id)
	---@type table<integer, Rabbit*Carrot.Collection.Dump>
	local copied = {}
	local to_copy = { id }
	---@type table<integer, integer>
	local id_map = {
		[id] = vim.uv.hrtime(),
	}

	while #to_copy > 0 do
		local old_id = table.remove(to_copy, 1)
		local collection = vim.deepcopy(LIST.collections[old_id].ctx.real)
		local folder = LIST.carrot[ENV.cwd.value]
		collection.parent = id_map[collection.parent]
		copied[id_map[old_id]] = collection

		for i, entry in ipairs(collection.list) do
			if type(entry) == "string" or id_map[entry] ~= nil then
				-- pass
			elseif type(entry) == "number" then
				table.insert(to_copy, entry)
				local new_id = vim.uv.hrtime()
				-- This should never happen, but I would like to avoid collisions
				while folder[tostring(new_id)] ~= nil do
					new_id = vim.uv.hrtime()
				end

				id_map[entry] = new_id
				collection.list[i] = new_id
			else
				error("Unreachable; " .. vim.inspect(entry))
			end
		end
	end

	return copied, id_map
end

---@param entry Rabbit*Carrot.Collection
---@return Rabbit*Carrot.Collection.Dump real
local function real_target(entry)
	local real = LIST.collections[entry.ctx.id].ctx.real
	entry.ctx.real = real
	return real
end

---@type Rabbit.Plugin.Actions
---@diagnostic disable-next-line: missing-fields
local ACTIONS = {}

---@param entry Rabbit*Carrot.Collection
function ACTIONS.children(entry)
	INIT = INIT or require("rabbit.plugins.carrot")
	local entries = {}
	local env = entry._env
	entry = LIST.collections[entry.ctx.id]
	entry._env = env
	LIST.buffers[LIST.scope()] = entry

	entry._env = entry._env or { cwd = ENV.cwd.value }

	local real = real_target(entry)
	local parent_idx = 0

	assert(real ~= nil, "Unreachable: Rabbit Collection should have a Twig Collection")

	INIT.empty.actions.paste = #LIST.yank > 0

	local recent = LIST.recent
	if recent ~= nil and recent.type == "collection" and entry.ctx ~= nil then
		recent = recent --[[@as Rabbit*Carrot.Yank.Collection]]
		if recent.id == entry.ctx.id or recent.id_map[recent.id] == entry.ctx.id then
			-- Do not permit moving a collection to itself
			LIST.recent = nil
			INIT.empty.actions.insert = false
		end
	end

	if real.parent ~= -1 then
		local c = vim.deepcopy(LIST.collections[real.parent])
		local parent = real.parent
		if parent <= 0 then
			c.label = {
				{ text = "/", hl = "rabbit.paint.rose" },
				{ text = real.name, hl = "rabbit.files.path" },
			}
		else
			c.label = {
				{ text = "/", hl = "rabbit.files.path" },
				c.label,
				{ text = "/" .. real.name, hl = "rabbit.files.path" },
			}
			parent = c.ctx.real.parent
			while parent > 0 do
				local p = LIST.collections[parent]
				if #c.label >= 4 then
					table.insert(c.label, 1, {
						text = CONFIG.window.overflow.travel_trunc,
						hl = "rabbit.files.path",
					})
					break
				else
					table.insert(c.label, 2, {
						text = p.ctx.real.name .. "/",
						hl = "rabbit.files.path",
					})
				end
				parent = LIST.collections[parent].ctx.real.parent
			end
		end
		c.idx = CONFIG.icons.entry_up
		c.actions.rename = false
		c.actions.delete = false
		c.actions.visual = false
		c.actions.insert = LIST.recent ~= nil
		c.actions.paste = #LIST.yank > 0
		table.insert(entries, c)
	end

	local to_remove = {}
	local top_level = LIST.collections[0] == entry
	for i, e in ipairs(real.list) do
		if e == vim.NIL or e == nil then
			table.insert(to_remove, i)
		elseif type(e) == "string" then
			local c = LIST.files[e]
			c.actions.parent = not top_level
			c.actions.insert = LIST.recent ~= nil
			c.actions.paste = #LIST.yank > 0
			local fakename = real.filename[c.path]
			if fakename then
				c.label = {
					{ text = ICONS[c.path] .. " ", hl = "rabbit.files.path" },
					{ text = fakename, hl = "rabbit.files.file" },
				}
			end
			table.insert(entries, c)
		else
			local c = LIST.collections[e]
			c.default = false
			c.actions.parent = not top_level
			c.actions.rename = true
			c.actions.insert = LIST.recent ~= nil
			c.actions.paste = #LIST.yank > 0
			c.ctx.real.parent = entry.ctx.id
			table.insert(entries, c)
			if c == entry._env.parent then
				parent_idx = #entries
			end
		end
	end

	for j = #to_remove, 1, -1 do
		table.remove(real.list, to_remove[j])
	end

	if entries[ENV.default] ~= nil then
		entries[ENV.default].default = true
	elseif parent_idx ~= 0 then
		entries[parent_idx].default = true
	end

	ENV.default = 0

	return entries
end

---@param entry Rabbit*Carrot.Collection
function ACTIONS.insert(entry)
	if LIST.recent == nil then
		return
	end

	local collection = LIST.buffers[LIST.scope()]
	if entry._env ~= nil then
		collection = entry._env.parent --[[@as Rabbit*Carrot.Collection]]
	else
		entry._env = entry._env or { idx = 1, cwd = ENV.cwd.value, siblings = { { idx = true } } }
	end
	local real = real_target(collection)

	local idx = entry._env.idx
	if entry._env.siblings[1].idx == false then
		idx = math.max(1, idx - 1)
	end

	local recent = LIST.recent

	if recent == nil then
		-- pass
	elseif recent.type == "file" then
		recent = recent --[[@as Rabbit*Carrot.Yank.File]]
		SET.add(real.list, recent.path, idx)
		real.filename[recent.path] = recent.name
	elseif recent.type == "collection" then
		recent = recent --[[@as Rabbit*Carrot.Yank.Collection]]

		local folder = LIST.carrot[ENV.cwd.value]
		local copy_id = recent.id_map[recent.id]
		local copy_root = recent.copied[copy_id]
		if copy_root.parent == nil then
			for new_id, obj in pairs(recent.copied) do
				folder[tostring(new_id)] = obj
			end
		else
			local parent = folder[tostring(copy_root.parent)]
			SET.del(parent.list, copy_id)
		end

		copy_root.parent = collection.ctx.id

		SET.add(real.list, copy_id, idx)
	end

	ENV.default = entry._env.idx

	LIST.carrot:__Save()

	return collection
end

---
function ACTIONS.collect(entry)
	local parent = LIST.buffers[LIST.scope()] ---@type Rabbit*Carrot.Collection
	local folder = LIST.carrot[ENV.cwd.value]

	if entry._env ~= nil then
		parent = LIST.collections[entry._env.parent.ctx.id]
	else
		entry._env = entry._env or { idx = 1, cwd = ENV.cwd.value, siblings = { { idx = true } } }
	end

	local new_id = vim.uv.hrtime()
	while folder[tostring(new_id)] ~= nil do
		new_id = vim.uv.hrtime()
	end
	local new_collection = LIST.collections[new_id]
	local new_real = real_target(new_collection)
	local p_real = real_target(parent)
	new_real.parent = parent.ctx.id

	local dx = entry._env.siblings[1].idx == false and -1 or 0
	ENV.default = entry._env.idx
	SET.add(p_real.list, new_id, math.max(1, ENV.default + dx))

	LIST.carrot:__Save()

	return parent, NVIM.bind(ACTIONS.rename, new_collection)
end

function ACTIONS.parent(entry)
	local collection = LIST.buffers[LIST.scope()] ---@type Rabbit*Carrot.Collection
	if entry._env ~= nil then
		collection = LIST.collections[entry._env.parent.ctx.id]
	end
	return LIST.collections[collection.ctx.real.parent]
end

---@param entry Rabbit*Carrot.Collection
---@return table<string, true> names
local function collect_names(entry)
	local names = {}
	local real = real_target(entry)
	for _, obj in ipairs(real.list) do
		if type(obj) == "string" then
			local name = real.filename[obj]
			if name ~= nil then
				names[name] = true
			end
		elseif type(obj) == "number" then
			local collection = LIST.carrot[ENV.cwd.value][tostring(obj)]
			assert(collection ~= nil, "Collection not found")
			names[collection.name] = true
		else
			error("Unexpected object type: " .. type(obj))
		end
	end

	return names
end

---@param entry Rabbit*Carrot.Collection | Rabbit*Trail.Buf
---@param new_name string
---@return string
local function check_rename(entry, new_name)
	if new_name == "" then
		if entry.type == "file" then
			entry = entry --[[@as Rabbit*Trail.Buf]]
			return "./" .. vim.fs.basename(entry.path)
		end
		new_name = string.format("%04x", math.random(1, 65535))
	end

	local names = collect_names(entry._env.parent --[[@as Rabbit*Carrot.Collection]])
	if entry.type == "collection" then
		entry = entry --[[@as Rabbit*Carrot.Collection]]
		names[entry.ctx.real.name] = nil
	elseif entry.type == "file" then
		entry = entry --[[@as Rabbit*Trail.Buf]]
		local real = real_target(entry._env.parent --[[@as Rabbit*Carrot.Collection]])
		local fakename = real.filename[entry.path]
		if fakename ~= nil then
			names[fakename] = nil
		end
	end

	return MEM.next_name(names, new_name)
end

---@param entry Rabbit*Carrot.Collection
---@param new_name string
---@return string
local function apply_rename(entry, new_name)
	new_name = check_rename(entry, new_name)
	if entry.type == "collection" then
		entry.label.text = new_name
		entry.ctx.real.name = new_name
	elseif entry.type == "file" then
		local e = entry --[[@as Rabbit*Trail.Buf]]
		local real = real_target(entry._env.parent --[[@as Rabbit*Carrot.Collection]])
		if new_name == "" or new_name == "./" .. vim.fs.basename(e.path) or new_name == e.path then
			real.filename[e.path] = nil
			e.label = nil
		else
			real.filename[e.path] = new_name
			e.label = {
				{ text = ICONS[e.path] .. " ", hl = "rabbit.files.path" },
				{ text = new_name, hl = "rabbit.files.file" },
			}
		end
	else
		error("Unreachable")
	end

	LIST.carrot:__Save()
	return new_name
end

---@param entry Rabbit*Carrot.Collection
---@param new_color string
local function apply_color(entry, new_color)
	entry.label.hl = {
		"rabbit.types.collection",
		"rabbit.paint." .. new_color,
	}
	entry.ctx.real.color = new_color
	LIST.carrot:__Save()
end

function ACTIONS.rename(entry)
	if entry.type == "file" then
		entry = entry --[[@as Rabbit*Trail.Buf]]
		return { ---@type Rabbit.Message.Rename
			class = "message",
			type = "rename",
			apply = apply_rename,
			check = check_rename,
			color = false,
			name = entry._env.parent.ctx.real.filename[entry.path] or "",
			entry = entry,
		}
	end

	entry = entry --[[@as Rabbit*Carrot.Collection]]

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
			entry = entry,
		},
		name = entry.ctx.real.name,
	}
end

---@param entry Rabbit*Carrot.Collection | Rabbit*Trail.Buf
function ACTIONS.delete(entry)
	local real = real_target(entry._env.parent --[[@as Rabbit*Carrot.Collection]])
	if entry.type == "file" then
		entry = entry --[[@as Rabbit*Trail.Buf]]
		LIST.recent = {
			type = "file",
			path = entry.path,
			name = real.filename[entry.path],
		}
		ENV.default = entry._env.idx
		SET.del(real.list, entry.path)
	elseif entry.type == "collection" then
		assert(entry.idx ~= false, "Cannot delete the move-up collection")
		entry = LIST.collections[entry.ctx.id]
		local folder = LIST.carrot[ENV.cwd.value]

		local copied, id_map = deep_copy_collection(entry.ctx.id)
		for old_id, _ in pairs(id_map) do
			folder[tostring(old_id)] = nil
		end

		---@type Rabbit*Carrot.Yank.Collection
		LIST.recent = {
			type = "collection",
			id = entry.ctx.id,
			copied = copied,
			id_map = id_map,
		}

		SET.del(real.list, entry.ctx.id)
		ENV.default = entry._env.idx
	else
		error("Unreachable")
	end

	LIST.carrot:__Save()
	if ENV.default == #entry._env.siblings then
		ENV.default = ENV.default - 1
	end
	INIT.empty.actions.insert = true
	return entry._env.parent
end

function ACTIONS.cut(entry)
	ACTIONS.yank(entry)

	local real = real_target(entry._env.parent --[[@as Rabbit*Carrot.Collection]])

	for _, obj in ipairs(LIST.yank) do
		if obj.type == "file" then
			obj = obj --[[@as Rabbit*Carrot.Yank.File]]
			SET.del(real.list, obj.path)
		elseif obj.type == "collection" then
			obj = obj --[[@as Rabbit*Carrot.Yank.Collection]]
			SET.del(real.list, obj.id)
		end
	end

	local dx = entry._env.siblings[1].idx == false and -1 or 0
	ENV.default = math.max(1, math.min(entry._env.idx + dx, #real.list)) - dx

	LIST.carrot:__Save()

	INIT.empty.actions.paste = #LIST.yank > 0
	return entry._env.parent
end

function ACTIONS.paste(entry)
	local parent = LIST.buffers[LIST.scope()]
	if entry._env ~= nil then
		parent = LIST.collections[entry._env.parent.ctx.id]
	else
		entry._env = entry._env or { idx = 1, cwd = ENV.cwd.value, siblings = { { idx = true } } }
	end

	local real = real_target(parent)
	local dx = entry._env.idx
	if entry._env.siblings[1].idx == false then
		dx = dx - 1
	end

	local folder = LIST.carrot[ENV.cwd.value]
	local names = collect_names(parent)

	for i, obj in ipairs(LIST.yank) do
		if obj.type == "file" then
			obj = obj --[[@as Rabbit*Carrot.Yank.File]]
			SET.add(real.list, obj.path, dx + i - 1)
			local new_name = MEM.next_name(names, obj.name)
			real.filename[obj.path] = new_name
			names[new_name] = true
		elseif obj.type == "collection" then
			obj = obj --[[@as Rabbit*Carrot.Yank.Collection]]
			local root_id = obj.id_map[obj.id]
			local root_obj = obj.copied[root_id]
			for id, copy in pairs(obj.copied) do
				folder[tostring(id)] = copy
			end

			root_obj.parent = parent.ctx.id
			SET.add(real.list, root_id, dx + i - 1)

			-- Re-copy for consecutive paste actions
			obj.copied, obj.id_map = deep_copy_collection(root_id)
			obj.id = root_id

			root_obj.name = MEM.next_name(names, root_obj.name)
			names[root_obj.name] = true
		else
			error("Unreachable")
		end
	end

	LIST.carrot:__Save()
	ENV.default = entry._env.idx
	return parent
end

function ACTIONS.yank(entry)
	local start_idx, end_idx = TERM.get_yank()
	local real = real_target(entry._env.parent --[[@as Rabbit*Carrot.Collection]])
	if entry._env.siblings[1].idx == false then
		start_idx = start_idx - 1
		end_idx = end_idx - 1
	end

	LIST.yank = {}
	for i = start_idx, end_idx do
		local obj = real.list[i]
		if type(obj) == "string" then
			table.insert(LIST.yank, {
				type = "file",
				path = obj,
				name = real.filename[obj],
			})
		elseif type(obj) == "number" then
			local copied, id_map = deep_copy_collection(obj)
			table.insert(LIST.yank, {
				type = "collection",
				id = obj,
				copied = copied,
				id_map = id_map,
			})
		else
			error("Unreachable")
		end
	end

	ENV.default = entry._env.idx

	return entry._env.parent
end

return ACTIONS
