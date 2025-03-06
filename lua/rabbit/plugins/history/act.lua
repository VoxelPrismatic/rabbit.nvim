---@type Rabbit.Plugin.Actions
local ACT = {}
local UIL = require("rabbit.term.listing")
local LIST = require("rabbit.plugins.history.listing")

function ACT.select(_, entry, _)
	if entry.type == "action" then
		LIST.action = tonumber(entry.tail)
		UIL.list(LIST.generate())
		return
	end
end

function ACT.delete(idx, entry, listing) end

return ACT
