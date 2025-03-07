local LIST = require("rabbit.plugins.history.listing")
local UIL = require("rabbit.term.listing")
local CTX = require("rabbit.term.ctx")
local SET = require("rabbit.util.set")

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

-- Create a listing
function PLUG.list()
	LIST.winnr = CTX.user.win
	if #LIST.win[LIST.winnr] < 2 then
		LIST.winnr = nil
	end

	LIST.cache_system()
	UIL.list(LIST.generate())
	_ = pcall(vim.api.nvim_win_set_cursor, UIL._fg.win, { 2, 0 })
end

return PLUG
