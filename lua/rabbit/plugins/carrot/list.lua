local MEM = require("rabbit.util.mem")
local ENV = require("rabbit.plugins.carrot.env")
local SET = require("rabbit.util.set")
local CONFIG = require("rabbit.plugins.carrot.config")
local TRAIL = require("rabbit.plugins.trail.list")

---@class (exact) Rabbit*Carrot.Collection: Rabbit.Entry.Collection
---@field label Rabbit.Term.HlLine
---@field ctx Rabbit*Carrot.Collection.Ctx

---@class Rabbit*Carrot.Collection.Ctx
---@field id integer Real collection ID
---@field bufid integer Target Buffer ID
---@field winid integer Target Window ID
---@field real Rabbit*Carrot.Collection.Dump

---@class (exact) Rabbit*Carrot.Collection.Dump
---@field name string Collection name
---@field color Rabbit.Colors.Paint Collection color
---@field parent integer Parent collection (or 0 for root)
---@field list (string | integer)[] String: File path; Integer: Collection ID
---@field filename table<string, string> Renamed files

---@class (exact) Rabbit*Carrot.Dump
---@field [string] Rabbit*Carrot.Collection.Dump

---@class Rabbit*Carrot.Writeable: Rabbit.Writeable
---@field [string] Rabbit*Carrot.Dump

---@class Rabbit*Carrot.Listing
local LIST = {
	---@type Rabbit*Carrot.Writeable
	-- { path: Collection }
	carrot = { __Dest = "twig.json", __Save = MEM.Write },

	---@type table<string, Rabbit*Carrot.Collection>
	-- Memory pointers to collections to prevent duplicates
	slots = {},

	---@type table<integer, Rabbit*Carrot.Collection>
	-- { collection id: Collection }
	collections = {},

	---@type table<integer, Rabbit*Carrot.Collection>
	-- { buffer id: Collection }
	buffers = {},

	---@type table<integer | string, Rabbit*Trail.Buf>
	files = {},

	---@type table<string, table<integer, Rabbit*Carrot.Collection>>
	real = {},
}

-- Loads collection data from disk
---@param path string File path
function LIST.load(path)
	LIST.carrot = MEM.Read(path) --[[@as Rabbit*Carrot.Writeable]]
	for _, collections in pairs(LIST.carrot) do
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

	LIST.carrot:__Save()
end

---@param bufid integer Buffer ID to show the collection for
local function buffer_collection(self, bufid)
	self[bufid] = LIST.collections[0]
	return self[bufid]
end

---@return integer "0, bufid, or winid based on the current settings"
function LIST.scope()
	if CONFIG.separate == "buffer" then
		return ENV.bufid or 0
	elseif CONFIG.separate == "window" then
		return ENV.winid or 0
	end
	return 0
end

---@param id integer Collection ID
local function create_collection(self, id)
	local real_target = LIST.real[ENV.cwd.value]
	if real_target == nil then
		real_target = {}
		LIST.real[ENV.cwd.value] = real_target
	end

	local str_id = tostring(id)
	if rawget(real_target, str_id) ~= nil then
		return real_target[str_id]
	end

	local carrot_target = LIST.carrot[ENV.cwd.value]
	if carrot_target == nil then
		carrot_target = {}
		LIST.carrot[ENV.cwd.value] = carrot_target
	end

	local collection = carrot_target[str_id]
	if collection == nil then
		---@type Rabbit*Carrot.Collection.Dump
		collection = {
			name = id == 0 and "Root" or "",
			color = "rose",
			parent = -1,
			list = {},
			filename = {},
		}

		carrot_target[str_id] = collection
	else
		collection.parent = collection.parent or 0
		collection.list = collection.list or {}
		collection.filename = collection.filename or {}
	end

	---@type Rabbit*Carrot.Collection
	real_target[str_id] = {
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
			parent = collection.parent ~= 0,
			rename = str_id ~= "0",
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
