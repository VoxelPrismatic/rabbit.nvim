local TERM = require("rabbit.term")
local CONFIG = require("rabbit.config")
local SET = require("rabbit.util.set")

local RABBIT = {
	---@type table<string, Rabbit.Plugin>
	-- Loaded plugins, where the key is the plugin name
	plugins = {},

	---@type Rabbit.Table.Set<string>
	-- Order of loaded plugins (first will be opened by default)
	order = SET.new(),

	---@type table<string, integer>
	-- Event : Autocmd ID
	autocmds = {},

	augroup = vim.api.nvim_create_augroup("Rabbit", { clear = false }),
}

function RABBIT.setup(opts)
	CONFIG.setup(opts)

	for _, k in
		ipairs(CONFIG.keys.switch --[[@as table<string>]])
	do
		vim.keymap.set("n", k, function()
			RABBIT.spawn()
		end, { desc = "Rabbit" })
	end
	for k, v in pairs(CONFIG.plugins) do
		if v ~= false then
			RABBIT.register(k, v)
		end
	end

	local ok, msg, errno = vim.uv.fs_mkdir(CONFIG.system.data, 493)
	if not ok and errno ~= "EEXIST" then
		error(msg)
	end
end

-- Sets up a plugin
---@param plugin string | Rabbit.Plugin Plugin table or require() plugin name
---@param opts? Rabbit.Plugin.Options
function RABBIT.register(plugin, opts)
	local ok ---@type boolean
	local p ---@type Rabbit.Plugin
	if type(plugin) == "string" then
		ok, p = pcall(require, "rabbit.plugins." .. plugin) ---@type boolean, Rabbit.Plugin
		if not ok then
			local err_msg = p --[[@as string]]
			if err_msg:find("module 'rabbit.plugins." .. p .. "' not found:") ~= 1 then
				error(err_msg)
			end
			p = require(plugin --[[@as string]]) ---@type Rabbit.Plugin
		end
	elseif type(plugin) == "table" then
		p = plugin
	else
		error("Invalid plugin. Expected string or table, got " .. type(plugin))
	end

	if opts == nil then
		opts = CONFIG.plugins[p.name] or {}
	end

	RABBIT.plugins[p.name] = p
	RABBIT.order:add(p.name, opts.default and 1 or -1)
	p.setup(opts)

	for evt, _ in pairs(p.events) do
		if not RABBIT.autocmds[evt] then
			RABBIT.autocmds[evt] = vim.api.nvim_create_autocmd(evt, {
				callback = function(e)
					-- NvimEvent and vim.api.keyset.create_autocmd.callback_args are the same,
					-- but mine is better typed
					RABBIT.propagate(e --[[@as NvimEvent]])
				end,
				group = RABBIT.augroup,
			})
		end
	end

	for _, plug in ipairs(p.requires or {}) do
		if RABBIT.plugins[plug] == nil then
			RABBIT.register(plug)
		end
	end
end

-- Propagates events to all plugins
---@param evt NvimEvent
function RABBIT.propagate(evt)
	local winid = vim.api.nvim_get_current_win()

	local ctx = { ---@type Rabbit.Plugin.Environment
		winid = winid,
		bufid = vim.api.nvim_win_get_buf(winid),
		---@diagnostic disable-next-line: missing-fields
		dir = {},
	}

	for _, p in pairs(RABBIT.plugins) do
		ctx.plugin = p
		ctx.dir.raw = p.opts.cwd or CONFIG.cwd
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
		RABBIT.register(plugin)
	end

	return TERM.UI.spawn(RABBIT.plugins[plugin])
end

return RABBIT
