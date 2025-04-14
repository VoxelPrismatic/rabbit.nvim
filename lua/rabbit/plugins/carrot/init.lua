local GLOBAL_CONFIG = require("rabbit.config")
local LIST = require("rabbit.plugins.carrot.list")
local TRAIL = require("rabbit.plugins.trail.list")

---@class (exact) Rabbit*Carrot: Rabbit.Plugin
---@field opts Rabbit*Carrot.Options

---@type Rabbit*Carrot
local PLUG = {
	synopsis = "Put carrots next to your favorite files for quick access",
	version = "r0.0a3",
	empty = {
		msg = "There's nowhere to jump to! Get started by adding a file or collection",
		actions = {
			children = false,
			delete = false,
			hover = false,
			parent = false,
			rename = false,
			select = false,
			insert = true,
			collect = true,
			yank = false,
			cut = false,
			visual = false,
			paste = false,
		},
	},
	name = "carrot",
	actions = require("rabbit.plugins.carrot.actions"),
	events = require("rabbit.plugins.carrot.autocmd"),
	save = "carrot.json",
	_env = require("rabbit.plugins.carrot.env"),
	opts = require("rabbit.plugins.carrot.config"),
	requires = {
		"trail",
	},
}

function PLUG.setup(opts)
	PLUG.opts = vim.tbl_deep_extend("force", PLUG.opts, opts)
	LIST.load(GLOBAL_CONFIG.system.data .. PLUG.save)
end

function PLUG.list()
	PLUG.empty.actions.insert = false
	for _, bufid in ipairs(TRAIL.major.ctx.bufs) do
		local bufobj = TRAIL.bufs[bufid]
		if bufobj.ctx.listed and vim.uv.fs_stat(bufobj.path) ~= nil then
			LIST.recent = bufobj.path
			PLUG.empty.actions.insert = true
			break
		end
	end

	if PLUG.opts.separate == "never" then
		return LIST.collections[0]
	end

	return LIST.buffers[LIST.scope()]
end

return PLUG
