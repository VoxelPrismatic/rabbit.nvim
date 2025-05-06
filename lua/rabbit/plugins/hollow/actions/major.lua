local LIST = require("rabbit.plugins.hollow.list")
local ENV = require("rabbit.plugins.hollow.env")
local MEM = require("rabbit.util.mem")
local SET = require("rabbit.util.set")
local GLOBAL_CONFIG = require("rabbit.config")

local ACTIONS = {}

---@type { [string]: Rabbit*Hollow.C.Leaf }
local collection_cache = {}

---@param savefile Rabbit*Hollow.SaveFile
---@return Rabbit*Hollow.C.Leaf
function ACTIONS.Make_collection(savefile)
	local addr = tostring(savefile)
	if collection_cache[addr] == nil then
		---@class Rabbit*Hollow.C.Leaf: Rabbit.Entry.Collection
		collection_cache[addr] = {
			class = "entry",
			type = "collection",
			idx = true,
			label = {
				text = savefile.name,
				hl = {
					"rabbit.types.collection",
					"rabbit.paint." .. savefile.color,
				},
			},
			actions = {
				children = true,
				select = true,
				parent = true,
				collect = true,
				rename = true,
			},
			---@class Rabbit*Hollow.C.Leaf.Ctx
			ctx = {
				---@type string
				type = "leaf",

				---@type Rabbit*Hollow.SaveFile
				real = savefile,
			},
		}
	end

	return collection_cache[addr]
end

---@param entry Rabbit*Hollow.C.Major
function ACTIONS.children(entry)
	ENV.last_cwd = entry.ctx.key
	return SET.imap(entry.ctx.real, ACTIONS.Make_collection)
end

function ACTIONS.parent(_)
	return LIST.hollow[ENV.last_cwd]
end

return ACTIONS
