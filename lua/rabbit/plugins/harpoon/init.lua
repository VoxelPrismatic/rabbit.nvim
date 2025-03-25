local GLOBAL_CONFIG = require("rabbit.config")
local LIST = require("rabbit.plugins.harpoon.list")
local TRAIL = require("rabbit.plugins.trail.list")

---@class (exact) Rabbit*Harpoon: Rabbit.Plugin

---@type Rabbit*Harpoon
local PLUG = {
	empty = {
		msg = "There's nowhere to aim! Get started by adding a file or collection",
		actions = {
			children = false,
			delete = false,
			hover = false,
			parent = false,
			rename = false,
			select = false,
			insert = true,
			collect = true,
		},
	},
	name = "harpoon",
	actions = require("rabbit.plugins.harpoon.actions"),
	events = require("rabbit.plugins.harpoon.autocmd"),
	save = "harpoon.json",
	_env = require("rabbit.plugins.harpoon.env"),
	opts = require("rabbit.plugins.harpoon.config"),
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

	return LIST.buffers[PLUG._env.bufid]
end

return PLUG
