--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

local MAKE = {}

MAKE.cache = {
	---@type { [string]: Rabbit*Hollow.C.Leaf }
	leaf = {},

	---@type { [string]: Rabbit*Hollow.C.Tab }
	tab = {},
}

---@param leaf Rabbit*Hollow.SaveFile
---@return Rabbit*Hollow.C.Leaf
function MAKE.leaf(leaf)
	local addr = tostring(leaf)
	if MAKE.cache.leaf[addr] == nil then
		---@class Rabbit*Hollow.C.Leaf: Rabbit.Entry.Collection
		MAKE.cache.leaf[addr] = {
			class = "entry",
			type = "collection",
			idx = true,
			label = {
				text = leaf.name,
				hl = {
					"rabbit.types.collection",
					"rabbit.paint." .. leaf.color,
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
				real = leaf,
			},
		}
	end

	return MAKE.cache.leaf[addr]
end

---@param tab Rabbit*Hollow.SaveFile.Tab
---@param leaf Rabbit*Hollow.SaveFile
---@return Rabbit*Hollow.C.Tab
function MAKE.tab(leaf, tab)
	local addr = tostring(tab)
	if MAKE.cache.tab[addr] == nil then
		---@class Rabbit*Hollow.C.Tab: Rabbit.Entry.Collection
		MAKE.cache.tab[addr] = {
			class = "entry",
			type = "collection",
			idx = true,
			label = {
				text = tab.name,
				hl = {
					"rabbit.types.collection",
					"rabbit.paint." .. tab.color,
				},
			},
			actions = {
				children = true,
				select = true,
				parent = true,
				collect = true,
				rename = true,
			},
			---@class Rabbit*Hollow.C.Tab.Ctx
			ctx = {
				---@type string
				type = "tab",

				---@type Rabbit*Hollow.SaveFile.Tab
				real = tab,

				---@type Rabbit*Hollow.SaveFile
				leaf = leaf,
			},
		}
	end

	return MAKE.cache.tab[addr]
end

return MAKE
