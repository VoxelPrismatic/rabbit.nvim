local MEM = require("rabbit.util.mem")
local ENV = require("rabbit.plugins.harpoon.env")
local CONFIG = require("rabbit.plugins.harpoon.config")

---@class (exact) Rabbit*Harpoon.Collection: Rabbit.Entry.Collection
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
---@field [integer] string | integer String: File path; Integer: Collection ID

---@class (exact) Rabbit*Harpoon.Dump
---@field [integer] Rabbit*Harpoon.Collection.Dump

---@class Rabbit*Harpoon.Listing
local LIST = {
	---@type table<string, Rabbit*Harpoon.Dump>
	-- { path: Collection }
	harpoon = {},

	---@type table<string, Rabbit*Harpoon.Collection>
	-- Memory pointers to collections to prevent duplicates
	slots = {},

	---@type table<integer, Rabbit*Harpoon.Collection>
	-- { collection id: Collection }
	collections = {},

	---@type table<integer, Rabbit*Harpoon.Collection>
	-- { buffer id: Collection }
	buffers = {},
}

-- Loads collection data from disk
---@param path string File path
function LIST.load(path)
	LIST.harpoon = MEM.Read(path)
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
	if LIST.harpoon[ENV.cwd.value] == nil then
		LIST.harpoon[ENV.cwd.value] = {}
	end

	if LIST.harpoon[ENV.cwd.value][id] == nil then
		---@type Rabbit*Harpoon.Collection.Dump
		LIST.harpoon[ENV.cwd.value][id] = {
			name = id == 0 and "Root" or tostring(id),
			color = "rose",
			parent = 0,
		}
	end

	local collection = LIST.harpoon[ENV.cwd.value][id]

	---@type Rabbit*Harpoon.Collection
	self[id] = {
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
			delete = false,
			children = true,
			select = true,
			hover = false,
			parent = true,
			rename = false,
			insert = false,
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

-- Recently deleted entry
---@type integer | string
LIST.recent = 0

return LIST
