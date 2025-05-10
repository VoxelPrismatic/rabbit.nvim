--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

local LIST = require("rabbit.plugins.carrot.list")
local ENV = require("rabbit.plugins.carrot.env")
local UI = require("rabbit.term.listing")
local TRAIL = require("rabbit.plugins.trail.list")
local GLOBAL_ACTIONS = require("rabbit.actions")

local SCRIPT = {}

-- Simulates a series of selections from the root collection.
-- If this selection path does not lead to a file, Rabbit will spawn.
-- **WARNING:** This does not recalculate when moving stuff around.
-- **NOTE:** Do not offset future indexes by 1; this script automatically removes the 'up' entry.
---@param ... integer Selections to make
---@overload fun(env: string, ...: integer)
function SCRIPT.select(...)
	UI.update_env("carrot")

	local vararg = { ... }
	local folder = LIST.carrot[ENV.cwd.value]
	local custom_env = nil
	if type(vararg[1]) ~= "number" then
		local env = table.remove(vararg, 1)
		while type(env) == "function" do
			env = env()
		end
		custom_env = tostring(env)
		folder = LIST.carrot[tostring(env)]
	end

	local target_id = 0

	for _, key in ipairs({ ... }) do
		local value = folder[tostring(target_id)].list[key]
		if value == nil then
			break
		elseif type(value) == "string" then
			GLOBAL_ACTIONS.select(TRAIL.bufs[value])
			return
		else
			target_id = value
		end
	end

	UI.spawn("carrot")
	if custom_env ~= nil then
		ENV.cwd = {
			value = custom_env,
			scope = "script",
			raw = custom_env,
		}
	end
	UI.handle_callback(LIST.collections[target_id])
end

-- Simulates a series of selections from the root collection.
-- If this selection path does not lead to a file, Rabbit will spawn.
-- **WARNING:** This does not recalculate when moving stuff around.
-- **NOTE:** Do not offset future indexes by 1; this script automatically removes the 'up' entry.
---@param ... integer Selections to make
---@return fun() callback
function SCRIPT.select_fn(...)
	local vararg = { ... }
	return function()
		SCRIPT.select(unpack(vararg))
	end
end

return SCRIPT
