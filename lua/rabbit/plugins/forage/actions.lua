local TRAIL = require("rabbit.plugins.trail.list")
local LIST = require("rabbit.plugins.forage.list")
local ENV = require("rabbit.plugins.forage.env")

local ACTIONS = {} ---@type Rabbit.Plugin.Actions

function ACTIONS.children(entry)
	assert(entry.type == "collection")
	local listing = LIST.quickscore()
	local entries = {} ---@type Rabbit.Entry[]
	for _, v in ipairs(listing) do
		table.insert(entries, TRAIL.bufs[v.path]:as(ENV.winid))
	end
	return entries
end

return ACTIONS
