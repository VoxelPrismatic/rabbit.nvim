--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

local RABBIT = require("rabbit")
local TERM = require("rabbit.util.term")
local UI = require("rabbit.term.listing")

local ACTIONS = {} ---@type Rabbit.Plugin.Actions

---@param entry Rabbit*Index.Entry
function ACTIONS.select(entry)
	UI.spawn(entry.ctx.plugin)
	return { class = "message" }
end

function ACTIONS.children(entry)
	assert(entry.ctx == nil, "Cannot list children of plugin")

	local entries = {} ---@type Rabbit*Index.Entry[]

	local plugins = vim.tbl_keys(RABBIT.plugins)
	table.sort(plugins, function(a, b)
		return a < b
	end)
	for _, name in ipairs(plugins) do
		local plugin = RABBIT.plugins[name]
		if plugin.name == "index" then
			goto continue
		end

		---@class Rabbit*Index.Entry: Rabbit.Entry.Collection
		local e = {
			class = "entry",
			type = "collection",
			label = {
				text = TERM.case.title(name),
				hl = { "rabbit.types.title", "rabbit.plugin." .. name },
			},
			actions = {
				select = true,
				children = false,
			},
			ctx = {
				plugin = name,
			},
			default = UI._plugin_history[2] == name,
			synopsis = plugin.synopsis,
			tail = plugin.version .. " ",
		}
		table.insert(entries, e)
		::continue::
	end

	return entries
end

return ACTIONS
