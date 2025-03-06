---@class Rabbit._.History: Rabbit.Plugin
local PLUG = {
	---@type Rabbit.Plugin.Actions
	act = require("rabbit.plugins.history.act"),

	---@type Rabbit.Plugin.Events
	evt = require("rabbit.plugins.history.evt"),

	---@type Rabbit.Plugin.Context
	ctx = {},

	opts = require("rabbit.plugins.history.config"),
	save = false,
}

-- Initialize the plugin
---@param opts Rabbit._.History.Options
function PLUG.setup(opts)
	PLUG.opts = vim.tbl_deep_extend("force", PLUG.opts, opts)
end

return PLUG
