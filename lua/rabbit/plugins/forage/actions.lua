--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

local TRAIL = require("rabbit.plugins.trail.list")
local LIST = require("rabbit.plugins.forage.list")
local ENV = require("rabbit.plugins.forage.env")
local RIPGREP = require("rabbit.plugins.forage.rg")
local FUZZER = require("rabbit.plugins.forage.fzr")
local CONFIG = require("rabbit.plugins.forage.config")

---@type Rabbit.Plugin.Actions
---@diagnostic disable-next-line: missing-fields
local ACTIONS = {}

---@class Rabbit*Forage.Buf: Rabbit*Trail.Buf
---@field ctx Rabbit*Forage.Buf.Ctx

---@class Rabbit*Forage.Buf.Ctx: Rabbit*Trail.Buf.Ctx
---@field via string
---@field score Rabbit*Forage.Score
---@field siblings Rabbit*Forage.Score[]
---@field idx integer

local search_tools = {
	CONFIG.grep and RIPGREP.root or nil,
	CONFIG.fuzzy and FUZZER.root or nil,
}

function ACTIONS.children(entry)
	assert(entry.type == "collection")
	local listing = LIST.quickscore()
	---@type Rabbit.Entry[]
	local entries = vim.deepcopy(search_tools)
	for i, v in ipairs(listing) do
		local obj = vim.deepcopy(TRAIL.bufs[v.path]:as(ENV.winid)) --[[@as Rabbit*Forage.Buf]]
		obj.ctx.via = "forage"
		obj.ctx.score = v
		obj.ctx.siblings = listing
		obj.ctx.idx = i
		table.insert(entries, obj)
	end

	if entries[ENV.default] ~= nil then
		entries[ENV.default].default = true
		ENV.default = 0
	end
	return entries
end

function ACTIONS.parent(_)
	return LIST.default
end

function ACTIONS.delete(entry)
	assert(entry.ctx.via == "forage")

	entry = entry --[[@as Rabbit*Forage.Buf]]

	local ctx = entry.ctx
	local listing = ctx.siblings
	if listing[ctx.idx] ~= ctx.score then
		for i = #listing, 1, -1 do
			if listing[i].path == entry.ctx.score.path then
				table.remove(listing, i)
				break
			end
		end
	else
		table.remove(listing, ctx.idx)
	end

	ENV.default = math.min(entry._env.idx, #listing + #search_tools)
	return LIST.default
end

return ACTIONS
