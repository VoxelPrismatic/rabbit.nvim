local TERM = require("rabbit.term")
local OPTS = require("rabbit.config")

local RABBIT = {
	plugins = {}, ---@type table<string, Rabbit.Plugin>
	order = {}, ---@type string[]
	autocmds = {},
}

function RABBIT.setup(opts)
	OPTS.setup(opts)

	for k, v in pairs(OPTS.plugins) do
		local ok, p = pcall(require, "rabbit.plugins." .. k)
		if not ok then
			p = require(k)
		end

		RABBIT.register(k, p, v)
	end
end

-- Sets up a plugin
---@param k string Module name (passed to require)
---@param p Rabbit.Plugin
---@param opts Rabbit.Plugin.Options
function RABBIT.register(k, p, opts)
	RABBIT.plugins[k] = p
	table.insert(RABBIT.order, k)
	p.setup(opts)

	for evt, _ in pairs(p.evt) do
		if not RABBIT.autocmds[evt] then
			RABBIT.autocmds[evt] = true
			vim.api.nvim_create_autocmd(evt, {
				callback = function(e)
					RABBIT.propagate(e)
				end,
				group = vim.api.nvim_create_augroup("Rabbit", { clear = false }),
			})
		end
	end
end

-- Propagates events to all plugins
---@param evt NvimEvent
function RABBIT.propagate(evt)
	local winid = vim.api.nvim_get_current_win()
	for _, ctx in pairs(TERM.CTX.stack) do
		if evt.buf == ctx.buf or winid == ctx.win then
			return
		end
	end

	local ctx = { ---@type Rabbit.Plugin.Context
		winid = winid,
		---@diagnostic disable-next-line: missing-fields
		dir = {},
	}

	for _, p in pairs(RABBIT.plugins) do
		ctx.plugin = p
		ctx.dir.raw = p.opts.cwd or OPTS.cwd
		ctx.dir.scope = p.opts.cwd and "plugin" or "global"
		ctx.dir.value = type(ctx.dir.raw) == "function" and ctx.dir.raw() or ctx.dir.raw

		if p.evt[evt.event] then
			p.evt[evt.event](evt, ctx)
		end
	end
end

return RABBIT
