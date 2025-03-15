local LIST = require("rabbit.plugins.trail.list")
local CTX = require("rabbit.term.ctx")

---@class (exact) Rabbit*Trail: Rabbit.Plugin

---@type Rabbit*Trail
local PLUG = {
	name = "trail",
	actions = require("rabbit.plugins.trail.actions"),
	events = require("rabbit.plugins.trail.autocmd"),
	save = false,
	_env = {},
	opts = require("rabbit.plugins.trail.config"),
}

function PLUG.setup(opts)
	PLUG.opts = vim.tbl_deep_extend("force", PLUG.opts, opts)
end

function PLUG.list()
	if CTX.user.win == nil then
		return LIST.major
	elseif LIST.wins[CTX.user.win]:Len() < 2 then
		return LIST.major
	end

	return LIST.wins[CTX.user.win]
end

return PLUG
