--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

local MAKE = require("rabbit.plugins.hollow.make")

---@type Rabbit.Plugin.Actions
local ACTIONS = {}

---@param entry Rabbit*Hollow.C.Tab
function ACTIONS.children(entry)
	error("Not implemented")
end

---@param entry Rabbit*Hollow.C.Tab
function ACTIONS.parent(entry)
	return MAKE.leaf(entry.ctx.leaf)
end

return ACTIONS
