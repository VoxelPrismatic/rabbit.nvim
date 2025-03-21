local LIST = require("rabbit.plugins.trail.list")

---@class (exact) Rabbit*Trail: Rabbit.Plugin

---@type Rabbit*Trail
local PLUG = {
	empty_msg = "There's nowhere to jump to!",
	name = "trail",
	actions = require("rabbit.plugins.trail.actions"),
	events = require("rabbit.plugins.trail.autocmd"),
	save = false,
	_env = require("rabbit.plugins.trail.env"),
	opts = require("rabbit.plugins.trail.config"),
}

function PLUG.setup(opts)
	PLUG.opts = vim.tbl_deep_extend("force", PLUG.opts, opts)
end

function PLUG.list()
	if PLUG._env.winid == nil then
		return LIST.major
	end

	local ret = LIST.wins[PLUG._env.winid]
	if ret:Len() < 2 then
		return LIST.major
	end

	return ret
end

return PLUG
