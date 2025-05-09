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
