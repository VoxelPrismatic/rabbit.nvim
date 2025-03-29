local MEM = require("rabbit.util.mem")
local ENV = require("rabbit.plugins.harpoon.env")
local SET = require("rabbit.util.set")
local CONFIG = require("rabbit.plugins.harpoon.config")
local TRAIL = require("rabbit.plugins.trail.list")

---@class (exact) Rabbit*Harpoon.Collection: Rabbit.Entry.Collection
---@field label Rabbit.Term.HlLine | Rabbit.Term.HlLine[]
---@field ctx Rabbit*Harpoon.Collection.Ctx

---@class Rabbit*Harpoon.Collection.Ctx
---@field id integer Real collection ID
---@field bufid integer Target Buffer ID
---@field winid integer Target Window ID
---@field real Rabbit*Harpoon.Collection.Dump

---@class (exact) Rabbit*Harpoon.Collection.Dump
---@field name string Collection name
---@field color Rabbit.Colors.Paint Collection color
---@field parent integer Parent collection (or 0 for root)
---@field list (string | integer)[] String: File path; Integer: Collection ID

---@class (exact) Rabbit*Harpoon.Dump
---@field [string] Rabbit*Harpoon.Collection.Dump

---@class Rabbit*Harpoon.Writeable: Rabbit.Writeable
---@field [string] Rabbit*Harpoon.Dump

---@class Rabbit*Harpoon.Listing
local LIST = {
	---@type Rabbit*Harpoon.Writeable
	-- { path: Collection }
	harpoon = { __Dest = "harpoon.json", __Save = MEM.Write },

	---@type table<string, Rabbit*Harpoon.Collection>
	-- Memory pointers to collections to prevent duplicates
	slots = {},

	---@type table<integer, Rabbit*Harpoon.Collection>
	-- { collection id: Collection }
	collections = {},

	---@type table<integer, Rabbit*Harpoon.Collection>
	-- { buffer id: Collection }
	buffers = {},

	files = {},
}

-- Loads collection data from disk
---@param path string File path
function LIST.load(path)
	LIST.harpoon = MEM.Read(path)
	for _, collections in pairs(LIST.harpoon) do
		if type(collections) ~= "table" then
			goto continue
		end
		local to_delete = SET.new({ SET.keys(collections) })
		to_delete:del("0")
		local queue = SET.new({ "0" })
		while #queue > 0 do
			local id = tostring(queue:pop())
			for _, value in ipairs(collections[id].list) do
				if type(value) == "number" then
					queue:add(tostring(value))
					to_delete:del(tostring(value))
				end
			end
		end

		for _, id in ipairs(to_delete) do
			collections[id] = nil
		end

		::continue::
	end

	LIST.harpoon:__Save()
end

---@param bufid integer Buffer ID to show the collection for
local function buffer_collection(self, bufid)
	if not CONFIG.by_buffer and bufid ~= 0 then
		return self[0]
	end

	self[bufid] = LIST.collections[0]
	return self[bufid]
end

---@param id integer Collection ID
local function create_collection(self, id)
	if rawget(self, tostring(id)) ~= nil then
		return self[tostring(id)]
	end

	if LIST.harpoon[ENV.cwd.value] == nil then
		LIST.harpoon[ENV.cwd.value] = {}
	end

	if LIST.harpoon[ENV.cwd.value][tostring(id)] == nil then
		---@type Rabbit*Harpoon.Collection.Dump
		LIST.harpoon[ENV.cwd.value][tostring(id)] = {
			name = id == 0 and "Root" or "",
			color = "rose",
			parent = -1,
			list = {},
		}
	end

	local collection = LIST.harpoon[ENV.cwd.value][tostring(id)]

	---@type Rabbit*Harpoon.Collection
	self[tostring(id)] = {
		class = "entry",
		type = "collection",
		idx = true,
		label = {
			text = collection.name,
			hl = {
				"rabbit.types.collection",
				"rabbit.paint." .. collection.color,
			},
		},
		actions = {
			delete = true,
			children = true,
			select = true,
			hover = false,
			parent = collection.parent ~= 0,
			rename = tostring(id) ~= "0",
			insert = true,
			collect = true,
		},
		ctx = {
			bufid = ENV.bufid,
			winid = ENV.winid,
			real = collection,
			id = id,
		},
	}

	return self[id]
end

setmetatable(LIST.collections, {
	__index = create_collection,
})

setmetatable(LIST.buffers, {
	__index = buffer_collection,
})

setmetatable(LIST.files, {
	__index = function(_, key)
		local c = vim.deepcopy(TRAIL.bufs[key])
		c.actions.insert = true
		c.actions.collect = true
		c.idx = true
		return c
	end,
})

-- Recently deleted entry
---@type integer | string | table
LIST.recent = 0

return LIST
