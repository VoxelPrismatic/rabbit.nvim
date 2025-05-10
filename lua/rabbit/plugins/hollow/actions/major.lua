--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

local LIST = require("rabbit.plugins.hollow.list")
local ENV = require("rabbit.plugins.hollow.env")
local SET = require("rabbit.util.set")
local MAKE = require("rabbit.plugins.hollow.make")

---@type Rabbit.Plugin.Actions
local ACTIONS = {}

---@param entry Rabbit*Hollow.C.Major
function ACTIONS.children(entry)
	ENV.last_cwd = entry.ctx.key
	return SET.imap(entry.ctx.real, MAKE.leaf)
end

---@param entry Rabbit*Hollow.C.Major
function ACTIONS.parent(entry)
	return LIST.major[entry.ctx.key]
end

return ACTIONS
