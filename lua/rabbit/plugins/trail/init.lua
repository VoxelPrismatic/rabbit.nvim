local LIST = require("rabbit.plugins.trail.list")

---@class (exact) Rabbit*Trail: Rabbit.Plugin
---@field opts Rabbit*Trail.Options
---@field _env Rabbit*Trail.Environment

---@type Rabbit*Trail
local PLUG = {
	synopsis = "Navigate the trail of previously visited buffers, separated by window",
	version = "r1.0",
	empty = {
		msg = "There's nowhere to jump to! Get started by opening a buffer",
		actions = {},
	},
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
	PLUG._env.from_major = false
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
