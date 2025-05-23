--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

local SET = require("rabbit.util.set")

---@class Rabbit.Stack.Shared
local SHARED = {
	-- When the last workspace was opened
	---@type integer
	last_scratch = 0,

	-- Lists open workspaces
	---@type Rabbit.Table.Set<integer>
	open = SET.new(),

	-- Workspace ID: Workspace
	---@type table<integer, Rabbit.Stack.Workspace>
	spaces = {},

	-- User configuration
	---@type Rabbit.Stack.Workspace
	user = nil,
}

function SHARED.clear()
	for _, v in pairs(SHARED.spaces) do
		v:close()
	end
end

return SHARED
