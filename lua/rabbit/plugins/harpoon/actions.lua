local ENV = require("rabbit.plugins.harpoon.env")
local LIST = require("rabbit.plugins.harpoon.list")
local SET = require("rabbit.util.set")

local selection = 10000

---@type Rabbit.Plugin.Actions
local ACTIONS = {}

---@param entry Rabbit*Harpoon.Collection
function ACTIONS.children(entry)
	local entries = {}
	LIST.buffers[0] = entry
	LIST.buffers[ENV.bufid] = entry

	if entry._env == nil then
		entry._env = { cwd = ENV.cwd.value }
	end

	local real = entry.ctx.real
	local parent_idx = 0

	assert(real ~= nil, "Unreachable: Rabbit Collection should have a Harpoon Collection")

	if real.parent ~= -1 then
		local c = LIST.collections[real.parent]
		c.idx = false
		c.actions.rename = false
		c.actions.insert = true
		table.insert(entries, c)
	end

	local to_remove = {}
	for i, e in ipairs(entry.ctx.real.list) do
		if e == vim.NIL or e == nil then
			table.insert(to_remove, i)
		elseif type(e) == "string" then
			local c = LIST.files[e]:as(ENV.winid)
			table.insert(entries, c)
		else
			local c = LIST.collections[e]
			c.default = false
			table.insert(entries, c)
			if c == entry._env.parent then
				parent_idx = #entries
			end
		end
	end

	for j = #to_remove, 1, -1 do
		table.remove(entry.ctx.real.list, to_remove[j])
	end

	if selection <= #entries then
		entries[selection].default = true
	elseif parent_idx ~= 0 then
		entries[parent_idx].default = true
	end

	selection = 10000

	return entries
end

---@param entry Rabbit*Harpoon.Collection
function ACTIONS.insert(entry)
	if LIST.recent == 0 then
		return
	end
	local collection = LIST.buffers[ENV.bufid] ---@type Rabbit*Harpoon.Collection
	if entry._env == nil then
		entry._env = { idx = 1, cwd = ENV.cwd.value }
	end
	SET.Func.add(collection.ctx.real.list, LIST.recent, math.max(1, entry._env.idx - 1))
	selection = entry._env.idx

	LIST.harpoon:__Save()

	return collection
end

function ACTIONS.collect(entry)
	local collection = LIST.buffers[ENV.bufid] ---@type Rabbit*Harpoon.Collection
	if entry._env == nil then
		entry._env = { idx = 1, cwd = ENV.cwd.value }
	end
	local idx = vim.uv.hrtime()
	local c = LIST.collections[idx]
	c.ctx.real.parent = collection.ctx.id
	SET.Func.add(collection.ctx.real.list, idx, entry._env.idx)
	selection = entry._env.idx
	LIST.harpoon:__Save()

	vim.defer_fn(function()
		require("rabbit.term.listing").handle_callback(ACTIONS.rename(c))
	end, 25)

	return collection
end

function ACTIONS.parent(_)
	local collection = LIST.buffers[ENV.bufid] ---@type Rabbit*Harpoon.Collection
	return LIST.collections[collection.ctx.real.parent]
end

---@param entry Rabbit*Harpoon.Collection
---@param new_name string
local function apply_rename(entry, new_name)
	if new_name == "" then
		new_name = string.format("%04x", math.random(1, 65535))
	end

	for _, collection in pairs(entry._env.siblings) do
		collection = collection --[[@as Rabbit*Harpoon.Collection]]
		if collection ~= entry and collection.ctx.real.name == new_name then
			local _, _, count, match = new_name:find("(%++)([0-9]*)$")
			if match == nil and count == nil then
				return apply_rename(entry, new_name .. "+")
			elseif match == "" and count ~= "" then
				return apply_rename(entry, new_name .. #count)
			else
				local new_idx = tostring(tonumber(match) + 1)
				return apply_rename(entry, new_name:sub(1, -#new_idx - 1) .. new_idx)
			end
		end
	end
	entry.label.text = new_name
	entry.ctx.real.name = new_name
	LIST.harpoon:__Save()
	return new_name
end

function ACTIONS.rename(entry)
	if entry.type == "file" then
		error("Unreachable (file should never be renamed)")
	end

	return { ---@type Rabbit.Message.Rename
		class = "message",
		type = "rename",
		apply = apply_rename,
		color = false,
		name = entry.ctx.real.name,
	}
end

return ACTIONS
