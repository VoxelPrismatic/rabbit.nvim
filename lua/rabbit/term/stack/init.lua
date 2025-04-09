---@class Rabbit.Stack
local STACK = {
	---@type Rabbit.Stack.Workspace
	ws = require("rabbit.term.stack.workspace"),

	---@type Rabbit.Stack.Shared
	_ = require("rabbit.term.stack.shared"),
}

return STACK
