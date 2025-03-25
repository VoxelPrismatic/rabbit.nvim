local ENV = require("rabbit.plugins.harpoon.env")
local LIST = require("rabbit.plugins.harpoon.list")
local TRAIL = require("rabbit.plugins.trail.list")
local SET = require("rabbit.util.set")

local selection = 1

---@type Rabbit.Plugin.Actions
local ACTIONS = {}

---@param entry Rabbit*Harpoon.Collection
function ACTIONS.children(entry)
	local entries = {}
	LIST.buffers[ENV.bufid] = entry

	local real = entry.ctx.real

	assert(real ~= nil, "Unreachable: Rabbit Collection should have a Harpoon Collection")

	if real.parent ~= 0 then
		local c = LIST.collections[real.parent]
		c.idx = false
		table.insert(entries, c)
	end

	for _, e in ipairs(entry.ctx.real) do
		if type(e) == "string" then
			local c = TRAIL.bufs[e]
			c.actions.insert = true
			table.insert(entries, c)
		else
			table.insert(entries, LIST.collections[e])
		end
	end

	if selection < #entries then
		entries[selection].default = true
	end
	return entries
end

---@param entry Rabbit*Harpoon.Collection
function ACTIONS.insert(entry)
	local collection = LIST.buffers[ENV.bufid] ---@type Rabbit*Harpoon.Collection
	if entry._env == nil then
		entry._env = { idx = 1, cwd = ENV.cwd.value }
	end
	SET.Func.add(collection.ctx.real, LIST.recent, entry._env.idx)
	selection = entry._env.idx
	return collection
end

function ACTIONS.parent(_)
	local collection = LIST.buffers[ENV.bufid] ---@type Rabbit*Harpoon.Collection
	return LIST.collections[collection.ctx.real.parent]
end

return ACTIONS
