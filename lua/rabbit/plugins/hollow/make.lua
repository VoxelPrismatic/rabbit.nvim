--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

local MAKE = {}

MAKE.cache = {
	---@type { [string]: Rabbit*Hollow.C.Leaf }
	leaf = {},

	---@type { [string]: Rabbit*Hollow.C.Tab }
	tab = {},

	---@type { [string]: Rabbit*Hollow.C.Win }
	win = {},
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
				type = "leaf",

				---@type Rabbit*Hollow.SaveFile
				real = leaf,
			},
		}
	end

	return MAKE.cache.leaf[addr]
end

---@param win Rabbit*Hollow.SaveFile.Win
---@param tab Rabbit*Hollow.SaveFile.Tab
---@param leaf Rabbit*Hollow.SaveFile
---@return Rabbit*Hollow.C.Win
function MAKE.win(leaf, tab, win)
	local addr = tostring(win)
	if MAKE.cache.win[addr] == nil then
		---@class Rabbit*Hollow.C.Win: Rabbit.Entry.Collection
		MAKE.cache.win[addr] = {
			class = "entry",
			type = "collection",
			idx = true,
			label = {
				text = win.name,
				hl = {
					"rabbit.types.collection",
					"rabbit.paint.iris",
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
				type = "win",

				---@type Rabbit*Hollow.SaveFile.Win
				real = win,

				---@type Rabbit*Hollow.SaveFile.Tab
				tab = tab,

				---@type Rabbit*Hollow.SaveFile
				leaf = leaf,
			},
		}
	end

	return MAKE.cache.win[addr]
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
