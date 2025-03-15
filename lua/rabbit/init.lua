local TERM = require("rabbit.term")
local OPTS = require("rabbit.config")

local RABBIT = {
	plugins = {}, ---@type table<string, Rabbit.Plugin>
	order = {}, ---@type string[]
	autocmds = {},
}

function RABBIT.setup(opts)
	OPTS.setup(opts)

	for _, k in
		ipairs(OPTS.keys.switch --[[@as table<string>]])
	do
		vim.keymap.set("n", k, function()
			RABBIT.spawn()
		end, { desc = "Rabbit" })
	end
	for k, v in pairs(OPTS.plugins) do
		local ok, p = pcall(require, "rabbit.plugins." .. k) ---@type boolean, Rabbit.Plugin
		if not ok then
			p = require(k)
		end

		RABBIT.register(p, v)
	end
end

-- Sets up a plugin
---@param p Rabbit.Plugin
---@param opts Rabbit.Plugin.Options
function RABBIT.register(p, opts)
	RABBIT.plugins[p.name] = p
	table.insert(RABBIT.order, p.name)
	p.setup(opts)

	for evt, _ in pairs(p.events) do
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

	local ctx = { ---@type Rabbit.Plugin.Environment
		winid = winid,
		---@diagnostic disable-next-line: missing-fields
		dir = {},
	}

	for _, p in pairs(RABBIT.plugins) do
		ctx.plugin = p
		ctx.dir.raw = p.opts.cwd or OPTS.cwd
		ctx.dir.scope = p.opts.cwd and "plugin" or "global"
		ctx.dir.value = type(ctx.dir.raw) == "function" and ctx.dir.raw() or ctx.dir.raw

		if p.events[evt.event] then
			p.events[evt.event](evt, ctx)
		end
	end
end

-- Spawns a plugin, and registers it if necessary
---@param plugin? string
function RABBIT.spawn(plugin)
	if plugin == nil then
		if #RABBIT.order == 0 then
			error("No plugins registered")
		end
		plugin = RABBIT.order[1]
	end
	if RABBIT.plugins[plugin] == nil then
		local ok, p = pcall(require, "rabbit.plugins." .. plugin) ---@type boolean, Rabbit.Plugin
		if not ok then
			local err_msg = p --[[@as string]]
			if err_msg:find("module 'rabbit.plugins." .. plugin .. "' not found:") ~= 1 then
				error(err_msg)
			end
			p = require(plugin)
		end

		vim.print(vim.api.nvim_get_hl(0, { name = "Error" }), "Set up plugin `" .. p.name .. "' with default options")
		---@diagnostic disable-next-line: missing-fields
		RABBIT.register(p, {})
	end
	return TERM.UI.spawn(RABBIT.plugins[plugin])
end

return RABBIT
