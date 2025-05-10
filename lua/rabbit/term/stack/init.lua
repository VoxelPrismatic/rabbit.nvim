--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

---@class Rabbit.Stack
local STACK = {
	---@type Rabbit.Stack.Workspace
	ws = require("rabbit.term.stack.workspace"),

	---@type Rabbit.Stack.Shared
	_ = require("rabbit.term.stack.shared"),
}

return STACK
