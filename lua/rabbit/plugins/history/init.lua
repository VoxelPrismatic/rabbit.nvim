local LIST = require("rabbit.plugins.history.listing")
local UIL = require("rabbit.term.listing")

---@class Rabbit._.History: Rabbit.Plugin
local PLUG = {
	---@type Rabbit.Listing.Actions
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

-- Create a listing
function PLUG.list()
	UIL.list(LIST.generate())
end

return PLUG
