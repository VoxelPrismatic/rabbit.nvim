local ENV = require("rabbit.plugins.carrot.env")
local LIST = require("rabbit.plugins.carrot.list")
local SET = require("rabbit.util.set")
local CONFIG = require("rabbit.config")
local ICONS = require("rabbit.util.icons")

local selection = 10000

---@param entry Rabbit*Carrot.Collection
---@return Rabbit*Carrot.Collection.Dump real
local function real_target(entry)
	local real = LIST.collections[entry.ctx.id].ctx.real
	entry.ctx.real = real
	return real
end

---@type Rabbit.Plugin.Actions
local ACTIONS = {}

---@param entry Rabbit*Carrot.Collection
function ACTIONS.children(entry)
	local entries = {}
	local env = entry._env
	entry = LIST.collections[entry.ctx.id]
	entry._env = env
	LIST.buffers[0] = entry

	entry._env = entry._env or { cwd = ENV.cwd.value }

	local real = real_target(entry)
	local parent_idx = 0

	assert(real ~= nil, "Unreachable: Rabbit Collection should have a Twig Collection")
	if type(LIST.recent) == "table" and entry.ctx.id == LIST.recent.id then
		-- Do not permit moving a collection to itself
		LIST.recent = 0
		require("rabbit.plugins.carrot.init").empty.actions.insert = LIST.recent ~= 0
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
				if #c.label == 4 then
					table.insert(c.label, 1, {
						text = CONFIG.window.overflow.distance_char,
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
		c.idx = false
		c.actions.rename = false
		c.actions.insert = LIST.recent ~= 0
		c.actions.delete = false
		table.insert(entries, c)
	end

	local to_remove = {}
	local top_level = LIST.collections[0] == entry
	for i, e in ipairs(real.list) do
		if e == vim.NIL or e == nil then
			table.insert(to_remove, i)
		elseif type(e) == "string" then
			local c = LIST.files[e]:as(ENV.winid)
			c.actions.parent = not top_level
			c.actions.delete = true
			c.actions.insert = LIST.recent ~= 0
			c.actions.rename = true
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
			c.actions.parent = not top_level
			c.actions.rename = true
			c.actions.insert = LIST.recent ~= 0
			c.default = false
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

	if selection <= #entries and #entries > 0 then
		entries[selection].default = true
	elseif parent_idx ~= 0 then
		entries[parent_idx].default = true
	end

	selection = 10000

	return entries
end

---@param entry Rabbit*Carrot.Collection
function ACTIONS.insert(entry)
	if LIST.recent == 0 then
		return
	end

	local collection = LIST.buffers[ENV.bufid] ---@type Rabbit*Carrot.Collection

	entry._env = entry._env or { idx = 1, cwd = ENV.cwd.value }

	local idx = entry._env.idx
	if entry._env.siblings[1].idx == false then
		idx = math.max(1, idx - 1)
	end
	if type(LIST.recent) == "string" then
		SET.Func.add(collection.ctx.real.list, LIST.recent, idx)
	elseif type(LIST.recent) == "table" then
		local folder = LIST.carrot[ENV.cwd.value]
		local target = folder[tostring(LIST.recent.id)]
		local parent = folder[tostring(target.parent)]
		local current = folder[tostring(collection.ctx.id)]
		SET.Func.del(parent.list, LIST.recent.id)
		SET.Func.add(current.list, LIST.recent.id, idx)
		for id, value in
			pairs(LIST.recent --[[@as table]])
		do
			if id ~= "id" then
				folder[tostring(id)] = value
			end
		end
		target.parent = collection.ctx.id
	end

	selection = entry._env.idx

	LIST.carrot:__Save()

	return collection
end

---
function ACTIONS.collect(entry)
	local collection = LIST.buffers[ENV.bufid] ---@type Rabbit*Carrot.Collection
	if entry._env ~= nil then
		collection = LIST.collections[entry._env.parent.ctx.id]
	end
	entry._env = entry._env or { idx = 1, cwd = ENV.cwd.value }

	local idx = vim.uv.hrtime()
	local c = LIST.collections[idx]

	local pt = entry._env.idx
	if collection.ctx.real.parent ~= -1 then
		pt = math.max(1, pt - 1)
	end

	c.ctx.real.parent = collection.ctx.id
	SET.Func.add(collection.ctx.real.list, idx, pt)
	selection = entry._env.idx
	LIST.carrot:__Save()

	vim.defer_fn(function()
		require("rabbit.term.listing").handle_callback(ACTIONS.rename(c))
	end, 25)

	return collection
end

function ACTIONS.parent(_)
	local collection = LIST.buffers[ENV.bufid] ---@type Rabbit*Carrot.Collection
	return LIST.collections[collection.ctx.real.parent]
end

---@param entry Rabbit*Carrot.Collection
---@param new_name string
---@return string
local function check_rename(entry, new_name)
	if new_name == "" then
		if entry.type == "file" then
			local e = entry --[[@as Rabbit*Trail.Buf]]
			return "./" .. vim.fs.basename(e.path)
		end
		return string.format("%04x", math.random(1, 65535))
	end

	for _, collection in pairs(entry._env.siblings) do
		collection = collection --[[@as Rabbit*Carrot.Collection]]
		if collection.type ~= "collection" then
			-- pass
		elseif collection ~= entry and collection.ctx.real.name == new_name then
			local _, _, count, match = new_name:find("(%++)([0-9]*)$")
			if match == nil and count == nil then
				return check_rename(entry, new_name .. "+")
			elseif match == "" and count ~= "" then
				return check_rename(entry, new_name .. #count)
			else
				local new_idx = tostring(tonumber(match) + 1)
				return check_rename(entry, new_name:sub(1, -#new_idx - 1) .. new_idx)
			end
		end
	end

	return new_name
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
		}
	end

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
	}
end

---@param entry Rabbit*Carrot.Collection | Rabbit*Trail.Buf
function ACTIONS.delete(entry)
	if entry.type == "file" then
		entry = entry --[[@as Rabbit*Trail.Buf]]
		LIST.recent = entry.path
		selection = entry._env.idx
		local real = LIST.collections[entry._env.parent.ctx.id].ctx.real
		SET.Func.del(real.list, entry.path)
	elseif entry.type == "collection" then
		assert(entry.idx ~= false, "Cannot delete the move-up collection")
		entry = LIST.collections[entry.ctx.id]
		local to_delete = SET.new({ entry.ctx.id })
		local folder = LIST.carrot[ENV.cwd.value]

		LIST.recent = { id = entry.ctx.id, [entry.ctx.id] = entry.ctx.real }

		while #to_delete > 0 do
			local parent_id = tostring(to_delete:pop())
			for id, collection in pairs(folder) do
				if tostring(collection.parent) == parent_id then
					LIST.recent[id] = collection
					folder[id] = nil
					to_delete:add(id)
				end
			end
		end

		SET.Func.del(entry._env.parent.ctx.real.list, entry.ctx.id)
		selection = entry._env.idx
	else
		error("Unreachable")
	end

	LIST.carrot:__Save()
	if selection == #entry._env.siblings then
		selection = selection - 1
	end
	return entry._env.parent
end

return ACTIONS
