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

	---@type table<integer, Rabbit*Carrot.Collection>
	-- { collection id: Collection }
	collections = {},

	---@type table<integer, Rabbit*Carrot.Collection>
	-- { buffer id: Collection }
	buffers = {},

	---@type table<integer | string, Rabbit*Trail.Buf>
	files = TRAIL.copy_bufs(function(c)
		c.idx = true
		c.default = false
		c.actions.insert = true
		c.actions.collect = true
		c.actions.delete = true
		c.actions.rename = true
		return c:as(ENV.winid)
	end),

	---@type table<string, table<integer, Rabbit*Carrot.Collection>>
	real = {},

	---@type Rabbit*Carrot.Yank
	recent = nil,

	---@type Rabbit*Carrot.Yank[]
	yank = {},
}

---@class Rabbit*Carrot.Yank
---@field type string

---@class Rabbit*Carrot.Yank.File: Rabbit*Carrot.Yank
---@field type "file"
---@field path string
---@field name string

---@class Rabbit*Carrot.Yank.Collection: Rabbit*Carrot.Yank
---@field type "collection"
---@field id integer
---@field copied table<integer, Rabbit*Carrot.Collection.Dump>
---@field id_map table<integer, integer>

-- Loads collection data from disk
---@param path string File path
function LIST.load(path)
	LIST.carrot = MEM.Read(path) --[[@as Rabbit*Carrot.Writeable]]
	for _, collections in pairs(LIST.carrot) do
		if type(collections) ~= "table" then
			goto continue
		end

		local to_delete = SET.new(SET.keys(collections))

		to_delete:del("0")
		local queue = SET.new({ "0" })
		local seen = {}
		while #queue > 0 do
			local id = tostring(queue:pop())
			seen[id] = true
			local list = collections[id].list
			for i = #list, 1, -1 do
				local value = list[i]
				if type(value) == "number" then
					local v_id = tostring(value)
					if seen[v_id] then
						table.remove(list, i)
					else
						queue:add(v_id)
						to_delete:del(v_id)
					end
				end
			end
		end

		for _, id in ipairs(to_delete) do
			collections[id] = nil
		end

		::continue::
	end

	setmetatable(LIST.carrot, {
		__index = function(_, key)
			assert(type(key) == "string", "Expected string, got " .. type(key))
			local c = {}
			LIST.carrot[key] = c
			return c
		end,
	})

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

	local carrot_target = LIST.carrot[ENV.cwd.value]

	local str_id = tostring(id)
	if rawget(real_target, str_id) ~= nil then
		local collection = real_target[str_id]
		local real_obj = carrot_target[str_id]
		if real_obj ~= nil then
			collection.label = {
				text = real_obj.name,
				hl = {
					"rabbit.types.collection",
					"rabbit.paint." .. real_obj.color,
				},
			}

			return collection
		end
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
			visual = true,
			yank = true,
			cut = true,
			paste = true,
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

return LIST
