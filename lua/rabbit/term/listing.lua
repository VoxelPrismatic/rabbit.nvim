local RECT = require("rabbit.term.rect")
local HL = require("rabbit.term.highlight")
local MEM = require("rabbit.util.mem")
local BOX = require("rabbit.term.border")
local CONFIG = require("rabbit.config")
local SET = require("rabbit.util.set")
local LSP = require("rabbit.util.lsp")
local TERM = require("rabbit.util.term")
local STACK = require("rabbit.term.stack")
local NVIM = require("rabbit.util.nvim")
local ACTIONS

---@class Rabbit.UI.Listing
local UI = {
	-- Last plugin called
	---@type Rabbit.Plugin
	---@diagnostic disable-next-line: missing-fields
	_plugin = {}, ---@type Rabbit.Plugin

	-- List of entries currently on screen
	_entries = {}, ---@type Rabbit.Entry[]

	-- Should be the same as _parent
	_display = nil, ---@type Rabbit.Entry.Collection

	-- Preview border windows
	_pre = {}, ---@type { [string]: Rabbit.Stack.Workspace }

	-- Original buffers each window had opened
	_hov = {}, ---@type { [integer]: integer }

	-- Each window's view
	_views = {}, ---@type { [integer]: vim.fn.winsaveview.ret }

	-- Legend keymap for actions
	_legend = {}, ---@type Rabbit.Term.HlLine[]

	-- Legend keymap for plugins
	_plugins = {}, ---@type Rabbit.Term.HlLine[]

	-- Special keymap that overrides _legend, eg current window is changed
	_priority_legend = {}, ---@type Rabbit.Term.HlLine[]

	-- Marquee timer
	_marquee = vim.uv.new_timer(),

	-- Background window, featuring border
	_bg = nil, ---@type Rabbit.Stack.Workspace

	-- Foreground window, featuring entries
	_fg = nil, ---@type Rabbit.Stack.Workspace

	-- History of plugins
	_plugin_history = SET.new(), ---@type Rabbit.Table.Set<string>

	-- Enable close debugger
	---@type boolean
	_dbg = false,
}

---@param key string | string[]
---@return string[]
local function _K(key)
	if key == nil then
		return {}
	end
	return type(key) ~= "table" and { tostring(key) } or key --[[@as table<string>]]
end

local last_mode = ""

vim.api.nvim_create_autocmd("VimResized", {
	callback = function()
		if #STACK._.open == 0 then
			return
		end

		UI.spawn(UI._plugin)
	end,
})

-- Creates a buffer for the given plugin
---@param plugin string | Rabbit.Plugin
function UI.spawn(plugin)
	ACTIONS = ACTIONS or require("rabbit.actions")

	if #STACK._.open > 0 then
		UI.close(true)
	end

	for _, winid in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_config(winid).relative == "" then
			UI._hov[winid] = vim.api.nvim_win_get_buf(winid)
			UI._views[winid] = vim.api.nvim_win_call(winid, vim.fn.winsaveview)
		end
	end

	STACK._.user = STACK.ws.from()

	UI.update_env(plugin)
	UI._plugin_history:add(UI._plugin.name)

	-- Create background window
	local r = UI.rect(STACK._.user.win.id, 55)

	UI._bg = STACK.ws.scratch({
		focus = false,
		ns = "rabbit.bg",
		config = r,
		name = "Rabbit [borders]",
	})

	-- Create foreground window
	r.split = nil
	r.relative = "win"
	r.win = UI._bg.win.id
	r.row = 1
	r.col = 1
	r.width = r.width - 2
	r.height = r.height - 3
	r.zindex = r.zindex + 1

	local function redraw()
		UI.draw_border()
		local ok = pcall(UI.apply_actions)
		if not ok then
			UI.close()
			UI.spawn(UI._plugin)
		end
		-- vim.api.nvim_win_set_cursor(listing.win, { vim.fn.line("."), 0 })
	end

	UI._fg = STACK.ws.scratch({
		focus = true,
		ns = "rabbit.listing",
		config = r,
		parent = UI._bg,
		name = "Rabbit: " .. UI._plugin.name,
		---@diagnostic disable-next-line: missing-fields
		wo = {
			cursorline = true,
		},
		autocmd = {
			CursorMoved = redraw,
			BufLeave = UI.maybe_close,
			ModeChanged = UI.marquee_legend,
		},
	})

	UI._fg.children:add(UI._bg.id) -- Treat these as the same layer

	UI._plugin._env.open = true

	UI.handle_callback(UI._plugin.list())
end

-- Updates the environment of the plugin
---@param plugin? Rabbit.Plugin | string
function UI.update_env(plugin)
	if plugin ~= nil then
		UI.normalize_plugin(plugin)
	end

	STACK._.user = STACK.ws.from()

	local cwd = { ---@type Rabbit.Plugin.Context.Directory
		value = nil,
		scope = "fallback",
		raw = vim.fn.getcwd,
	}

	if UI._plugin.opts.cwd then
		cwd.raw = UI._plugin.opts.cwd
		cwd.scope = "plugin"
	elseif CONFIG.system.cwd then
		cwd.raw = CONFIG.system.cwd
		cwd.scope = "global"
	end

	if type(cwd.raw) == "function" then
		cwd.value = cwd.raw()
	end

	-- Do not reassign in case _env is a reference to a module
	UI._plugin._env.plugin = UI._plugin
	UI._plugin._env.winid = STACK._.user.win.id
	UI._plugin._env.cwd = cwd
	UI._plugin._env.bufid = STACK._.user.buf.id
	UI._plugin._env.hov = UI._hov
end

-- Normalizes the plugin
---@param plugin string | Rabbit.Plugin
function UI.normalize_plugin(plugin)
	if type(plugin) == "string" then
		UI._plugin = require("rabbit").plugins[plugin]
	elseif type(plugin) == "table" then
		UI._plugin = plugin
	else
		error("Invalid plugin. Expected string or table, got " .. type(plugin))
	end

	if UI._plugin == nil then
		error("Invalid plugin: " .. plugin)
	end
end

-- Actually lists the entries. Also calls `apply_actions` at the end
---@param collection Rabbit.Entry.Collection
---@return Rabbit.Entry[]
function UI.list(collection)
	if collection.actions.children == true then
		collection.actions.children = UI._plugin.actions.children
	elseif collection.actions.children == false then
		error("Invalid children")
	end

	UI._fg:focus()
	UI._priority_legend = {}
	UI._entries = collection.actions.children(collection)
	UI._display = collection

	_ = pcall(vim.api.nvim_buf_clear_namespace, UI._fg.buf, UI._fg.ns, 0, -1)

	if #UI._entries > 0 then
		---@type Rabbit.Kwargs.PlaceEntry
		local kwargs = {
			entry = UI._entries[1],
			idx = 0,
			line = 0,
			pad = UI.get_pad(),
		}

		for i, entry in ipairs(UI._entries) do
			kwargs.entry = entry
			kwargs.line = i
			UI.place_entry(kwargs)
		end

		UI._fg.buf.o.modifiable = true
		UI._fg.cursor:set(kwargs.man_default or kwargs.auto_default or 1, 0)
		vim.api.nvim_buf_set_lines(UI._fg.buf.id, kwargs.line, -1, false, {})
	else
		UI._fg.buf.o.modifiable = true
		local lines = HL.wrap({ text = UI._plugin.empty.msg }, UI._fg.win.config.width, " ")
		table.insert(lines, "")
		UI._fg.lines:set(lines, { end_ = -1, many = true })
		UI._fg.cursor:set(#lines, 0)
	end

	UI.draw_border()
	UI.apply_actions()
	UI._fg.buf.o.modifiable = false

	return UI._entries
end

-- Redraws this entry at it's current position. Shorthand for:
-- `UI.place_entry(entry, entry._env.idx, entry._env.real - 1, #tostring(#UI._entries))`
-- **WARNING:** This entry must be placed first (must have _env set)
---@param entry Rabbit.Entry
function UI.redraw_entry(entry)
	UI.place_entry({
		entry = entry,
		line = entry._env.idx,
		idx = (entry._env.real or 1) - 1,
		pad = UI.get_pad(),
	})
end

-- Gets the padding length
---@return integer pad
function UI.get_pad()
	local count = 0
	for _, e in ipairs(UI._entries) do
		if e.idx ~= false then
			count = count + 1
		end
	end

	return #tostring(count)
end

---@class Rabbit.Kwargs.PlaceEntry
---@field entry Rabbit.Entry
---@field line integer Line number to place the entry at
---@field idx integer Display index
---@field pad integer Number of spaces to pad the index with
---@field auto_default? integer Automatic default selection (first one with index shown)
---@field man_default? integer Manual default selection (with default set)

-- Places an entry
---@param kwargs Rabbit.Kwargs.PlaceEntry
function UI.place_entry(kwargs)
	UI._fg.buf.o.modifiable = true

	local idx
	local entry = kwargs.entry

	if entry.type == "search" then
		if kwargs.line ~= 1 then
			error("Search entries must be placed first")
		end
		entry = entry --[[@as Rabbit.Entry.Search]]
		entry.idx = false
		idx = entry.fields[entry.open].name .. ":"
	elseif type(entry.idx) == "string" then
		idx = (" "):rep(kwargs.pad - 1) .. entry.idx
	elseif entry.idx ~= false then
		kwargs.idx = kwargs.idx + 1
		kwargs.auto_default = kwargs.auto_default or kwargs.line
		idx = (" "):rep(kwargs.pad - #tostring(kwargs.idx)) .. kwargs.idx
		if kwargs.idx < 10 and entry.actions.select then
			vim.keymap.set(
				"n",
				tostring(kwargs.idx),
				UI.bind_callback("select", entry, true),
				{ buffer = UI._fg.buf.id, desc = "Select entry " .. kwargs.idx }
			)
		end
	else
		idx = ("—"):rep(kwargs.pad)
	end

	if kwargs.man_default == nil and entry.default then
		kwargs.man_default = kwargs.line
	end

	entry._env = {
		idx = kwargs.line,
		real = (entry.idx ~= false) and kwargs.idx or nil,
		entry = entry,
		siblings = UI._entries,
		parent = UI._display,
		cwd = UI._plugin._env.cwd.value,
		ident = " " .. idx .. "\u{a0}",
	}

	UI._entries[kwargs.line] = entry

	UI._fg.lines:set({
		{
			text = entry._env.ident,
			hl = "rabbit.types.index",
			align = "left",
		},
		UI.highlight(entry),
	}, {
		many = false,
		strict = false,
		start = kwargs.line - 1,
	})

	if entry.type == "search" then
		UI._fg.extmarks:set({
			line = 0,
			col = 0,
			ns = "rabbit.search.line",
			name = "search_line",
			opts = {
				end_col = 0,
				strict = false,
				virt_lines = {
					{ { ("─"):rep(UI._fg.win.config.width), "rabbit.types.plugin" } },
				},
			},
		})
	elseif entry.synopsis and CONFIG.window.synopsis.mode == "always" then
		UI.synopsis(entry, kwargs.line)
	end

	UI._fg.buf.o.modifiable = false
end

-- Creates the synopsis for a particular entry
---@param entry Rabbit.Entry
---@param id integer ID of this entry (use 0 to for hover, idx for always)
function UI.synopsis(entry, id)
	local text = entry.synopsis
	if type(text) == "string" then
		text = { ---@type Rabbit.Term.HlLine.NoAlign
			text = text,
			hl = { "rabbit.types.synopsis" },
		}
	else
		text = entry.synopsis --[[@as Rabbit.Term.HlLine.NoAlign]]
	end
	local w = UI._fg.win.config.width
	local ident = vim.fn.strdisplaywidth(entry._env.ident)
	local parts = {}
	for i, v in ipairs(vim.fn.str2list(CONFIG.window.synopsis.tree)) do
		parts[i] = vim.fn.nr2char(v)
	end

	while #parts < 2 do
		table.insert(parts, " ")
	end

	local synopsis = HL.wrap(text, w, (" "):rep(ident), { " " .. parts[1] .. parts[2]:rep(ident - 3) .. " " })
	if CONFIG.window.synopsis.newline then
		table.insert(synopsis, { { (" "):rep(w), "Normal" } })
	end

	UI._fg.extmarks:set({
		line = entry._env.idx - 1,
		col = 0,
		ns = "rabbit.synopsis",
		opts = {
			id = id,
			virt_lines = synopsis,
		},
	})
end

-- Normalizes a label
---@param text string | Rabbit.Term.HlLine
---@param hl string | string[]
---@param align string
---@return Rabbit.Term.HlLine
local function normalize_label(text, hl, align)
	text = text or {}
	if type(text) == "table" then
		return text
	end

	if type(hl) == "string" then
		hl = { hl }
	end

	return {
		text = text,
		hl = hl,
		align = align,
	}
end

-- Creates the highlights for a particular entry
---@param entry Rabbit.Entry
---@return Rabbit.Term.HlLine
function UI.highlight(entry)
	if entry.type == "search" then
		entry = entry --[[@as Rabbit.Entry.Search]]
		local max_len = UI._fg.win.config.width - vim.fn.strdisplaywidth(entry._env.ident) - 3 * #entry.fields
		local text = entry.fields[entry.open].content
		if #text > max_len then
			local ellipsis = CONFIG.window.overflow.dirname_char
			text = text:sub(1, max_len - 1 - vim.fn.strdisplaywidth(ellipsis)) .. ellipsis
		end
		local ret = {
			{ text = text, align = "left" },
		}
		for idx, field in ipairs(entry.fields) do
			if idx == entry.open then
				table.insert(ret, {
					{
						text = CONFIG.icons.select_left,
						hl = "rabbit.types.plugin",
						align = "right",
					},
					{
						text = field.icon,
						hl = "rabbit.types.reverse",
						align = "right",
					},
					{
						text = CONFIG.icons.select_right,
						hl = "rabbit.types.plugin",
						align = "right",
					},
				})
			else
				table.insert(ret, {
					text = " " .. field.icon .. " ",
					hl = "rabbit.types.index",
					align = "right",
				})
			end
		end
		table.insert(ret, {
			text = " ",
			align = "right",
		})
		return ret
	elseif entry.type ~= "file" or entry.label ~= nil then
		entry = entry --[[@as Rabbit.Entry.Collection]]
		return {
			normalize_label(entry.label, "rabbit.paint.iris", "left"),
			normalize_label(entry.tail, "rabbit.types.tail", "right"),
		}
	end

	entry = entry --[[@as Rabbit.Entry.File]]

	---@diagnostic disable-next-line: missing-fields
	entry = entry --[[@as Rabbit.Entry.File]]
	entry.closed = not vim.api.nvim_buf_is_valid(entry.bufid)
	if not entry.closed and entry.path == "" then
		entry.path = vim.api.nvim_buf_get_name(entry.bufid)
	end

	if tostring(entry.path):find("term://") == 1 then
		return {
			{
				text = "$ ",
				hl = { "rabbit.files.term" },
				align = "left",
			},
			{
				text = vim.b[entry.bufid].term_title,
				hl = {
					["rabbit.types.index"] = entry.idx == false,
					["rabbit.files.closed"] = entry.closed,
					"rabbit.files.file",
				},
				align = "left",
			},
			CONFIG.window.beacon.nrs and {
				text = tostring(entry.path):gsub(".*/(%d+):.*/(%w+)$", "%2/%1") .. " ",
				hl = { "rabbit.types.tail" },
				align = "right",
			} or {},
		}
	elseif tostring(entry.path):find("://") ~= nil then
		return {
			{
				text = tostring(entry.path):gsub("://.*$", ""),
				hl = { "rabbit.files.term" },
				align = "left",
			},
			{
				text = ":",
				hl = { "rabbit.legend.separator" },
				align = "left",
			},
			{
				text = tostring(entry.path):gsub(".*://", ""),
				hl = {
					["rabbit.types.index"] = entry.idx == false,
					["rabbit.files.closed"] = entry.closed,
					"rabbit.files.file",
				},
				align = "left",
			},
			CONFIG.window.beacon.nrs and {
				text = tostring(entry.bufid) .. " ",
				hl = { "rabbit.types.tail" },
				align = "right",
			} or {},
		}
	end

	local extras = {}

	if vim.api.nvim_buf_is_valid(entry.bufid) then
		if CONFIG.window.beacon.modified and vim.bo[entry.bufid].modified then
			table.insert(extras, {
				text = CONFIG.icons.modified .. " ",
				hl = { "rabbit.files.modified" },
				align = "right",
			})
		end

		if CONFIG.window.beacon.readonly and vim.bo[entry.bufid].readonly then
			table.insert(extras, {
				text = CONFIG.icons.readonly .. " ",
				hl = { "rabbit.files.readonly" },
				align = "right",
			})
		end

		local lsp_count = LSP.get_count(entry.bufid, CONFIG.window.beacon.lsp)
		for k, v in pairs(lsp_count) do
			if v > 0 then
				table.insert(extras, {
					text = CONFIG.icons["lsp_" .. k] .. v .. " ",
					hl = { "rabbit.lsp." .. k },
					align = "right",
				})
			end
		end
	end

	if entry.path == "" then
		return {
			{
				text = "#nil ",
				hl = { "rabbit.files.void" },
				align = "left",
			},
			{
				text = tostring(entry.bufid),
				hl = {
					["rabbit.types.index"] = entry.idx == false,
					["rabbit.files.closed"] = entry.closed,
					"rabbit.files.file",
				},
				align = "left",
			},
			extras,
		}
	end

	local rel_path = MEM.rel_path(tostring(entry.path))
	return {
		{ text = rel_path.dir, hl = { "rabbit.files.path" }, align = "left" },
		{
			text = rel_path.name,
			hl = {
				["rabbit.files.closed"] = entry.closed,
				["rabbit.types.index"] = entry.idx == false,
				"rabbit.files.file",
			},
			align = "left",
		},
		extras,
		(CONFIG.window.beacon.nrs and not entry.closed) and {
			text = tostring(entry.bufid) .. " ",
			hl = { "rabbit.types.tail" },
			align = "right",
		} or {},
	}
end

---@param action string
---@param entry Rabbit.Entry
---@return fun(e: Rabbit.Entry) | nil cb
---@return string[] keys
function UI.find_action(action, entry)
	local callback = entry.actions[action]
	if callback == false or callback == nil then
		return nil, {}
	elseif callback == true then
		callback = nil
	elseif type(callback) ~= "function" then
		error("Invalid action callback for " .. action .. "; Expected function, got " .. type(callback))
	end

	callback = callback or UI._plugin.actions[action] or ACTIONS[action]
	local keys = _K(UI._plugin.opts.keys[action] or CONFIG.keys[action])
	return callback, keys
end

-- Applies keymaps and draws the legend at the bottom of the listing
function UI.apply_actions()
	local i = UI._fg.cursor:get()[1]
	local e = UI._entries[i] ---@type Rabbit.Entry

	if e == nil then
		if #UI._entries == 0 then
			e = {
				class = "entry",
				type = "collection",
				actions = UI._plugin.empty.actions,
			}
		else
			e = {
				class = "entry",
				type = "collection",
				actions = { close = true },
			}
		end
		e.actions.close = true
	else
		-- Enable some actions by default
		for _, action in ipairs({ "close" }) do
			if e.actions[action] == nil then
				e.actions[action] = true
			end
		end
	end

	UI._plugins = {}
	local renamed = e.action_label or {}

	e.actions = e.actions or {}

	local all_actions = SET.extend(
		SET.keys(e.actions),
		SET.keys(UI._plugin.actions),
		SET.keys(UI._plugin.opts.keys),
		SET.keys(ACTIONS),
		SET.keys(CONFIG.keys)
	):del("hover")

	UI._fg.keys:clear()
	UI._fg.keys:add({
		keys = { "<LeftMouse>" },
		callback = function()
			local mouse = vim.fn.getmousepos()
			local line = vim.fn.line(".")
			vim.api.nvim_win_set_cursor(mouse.winid, { mouse.line, mouse.column - 1 })
			if mouse.winid ~= UI._fg.win.id then
				vim.api.nvim_set_current_win(mouse.winid)
				return
			end
			if line == mouse.line then
				local ok, cb = pcall(UI.bind_callback, "select", UI._entries[mouse.line], true)
				if ok then
					cb()
				end
			end
		end,
		shown = false,
		mode = "n",
		label = "mouse select",
	})

	if e.actions.parent then
		local val = UI.bind_callback("parent", e)()
		if val == UI._display then
			all_actions:del("parent")
		end
	end

	for _, action in ipairs(all_actions) do
		local cb, keys, exists = UI.bind_callback(action, e, true)
		if #keys == 0 or not exists then
			goto continue
		end

		local shown = CONFIG.window.legend
		if type(shown) ~= "boolean" then
			shown = shown[action]
		end

		local mode = "n"
		if action == "yank" or action == "cut" then
			mode = "v"
		end

		UI._fg.keys:add({
			label = renamed[action] or action,
			keys = keys,
			callback = cb,
			mode = mode,
			hl = "rabbit.types.plugin",
			shown = shown,
		})

		::continue::
	end

	local hls = {}

	for name, plugin in pairs(require("rabbit").plugins) do
		if plugin == UI._plugin or plugin.opts.keys.switch == "" or plugin.opts.keys.switch == false then
			goto continue
		end

		local switches = type(plugin.opts.keys.switch) == "string" and { tostring(plugin.opts.keys.switch) }
			or plugin.opts.keys.switch --[[@as table<string>]]

		local part = UI._fg.keys:add({
			label = name,
			keys = switches,
			callback = NVIM.bind(UI.spawn, plugin),
			mode = "n",
			hl = "rabbit.plugin." .. name,
			align = "right",
		})

		hls["rabbit.plugin." .. name] = { fg = tostring(plugin.opts.color) }

		table.insert(UI._plugins, { join = part, split = HL.split(part) })

		::continue::
	end

	HL.apply(hls)

	if vim.fn.mode() ~= "n" and not UI._fg.keys:has("visual") then
		TERM.feed("<Esc>")
	end

	if e.synopsis and CONFIG.window.synopsis.mode == "hover" then
		UI.synopsis(e, 10)
	end

	last_mode = ""
	UI.marquee_legend()
	if not UI._marquee:is_active() then
		UI._marquee:start(100, 100, vim.schedule_wrap(UI.marquee_legend))
	end

	if e.actions.hover then
		UI.bind_callback("hover", e, true)()
	else
		UI.cancel_hover()
	end
end

-- Marquee legend
function UI.marquee_legend()
	if not UI._bg.buf:exists() then
		UI._marquee:stop()
		return
	end

	local cur_plugin = { join = {}, split = {} }
	if vim.fn.mode() ~= last_mode then
		UI._legend = HL.split(UI._fg.keys:legend({
			align = "left",
			hl = "rabbit.types.plugin",
		}))
		last_mode = vim.fn.mode()
	end

	local legend = vim.deepcopy(UI._priority_legend)
	if #legend == 0 then
		legend = UI._legend
		if #UI._plugins > 0 then
			local idx = (os.time() % #UI._plugins) + 1
			cur_plugin = UI._plugins[idx]
		end

		legend = vim.deepcopy(UI._legend)
	end

	local max_len = UI._bg.win.config.width - #cur_plugin.split - #legend
	if max_len < 0 then
		for _ = 1, -max_len do
			table.remove(legend, #legend)
		end
		table.insert(legend, { text = " " })
		table.insert(UI._legend, table.remove(UI._legend, 1))
	else
		table.insert(legend, {
			text = (" "):rep(max_len),
		})
	end

	UI._bg.extmarks:clear("rabbit.marquee")

	HL.set_lines({
		bufnr = UI._bg.buf.id,
		lineno = UI._bg.win.config.height - 1,
		lines = { { legend, cur_plugin.join } },
		ns = "rabbit.marquee",
		many = false,
		strict = false,
		width = UI._bg.win.config.width,
	})
end

-- Handles callback data
---@param ... Rabbit.Recursive<Rabbit.Response>
function UI.handle_callback(...)
	local queue = { ... }
	while #queue > 0 do
		local data = table.remove(queue, 1)
		while type(data) == "function" do
			for i, d in ipairs({ data() }) do
				table.insert(queue, i, d)
			end
			data = table.remove(queue, 1)
		end

		if data == false or data == nil then
			-- pass
		elseif type(data) ~= "table" then
			error("Expected table, got: " .. type(data))
		elseif data.class == "entry" then
			data = data --[[@as Rabbit.Entry]]
			if data.type == "collection" or data.type == "search" then
				data = data --[[@as Rabbit.Entry.Collection]]
				UI._parent = data
				UI.list(UI._parent)
			else
				error("Cannot list a file")
			end
		elseif data.class == "message" then
			require("rabbit.messages").Handle(data)
		else
			error("Callback data not implemented: " .. vim.inspect(data))
		end
	end
end

-- Binds a callback given an entry and action to perform
---@param entry Rabbit.Entry
---@param action string | fun(entry: Rabbit.Entry): Rabbit.Response
---@param handle? boolean Also handle the callback
---@return fun() cb
---@return string[] keys
---@return boolean exists
function UI.bind_callback(action, entry, handle)
	local cb, keys

	if type(action) == "function" then
		cb, keys = action, {}
	else
		cb, keys = UI.find_action(action, entry)
	end

	cb = cb or function() end
	local wrap = function()
		return cb(entry)
	end

	if handle then
		wrap = UI.wrap_callback(wrap)
	end

	return wrap, keys, true
end

-- Wraps a callback to a function
---@param data Rabbit.Recursive<Rabbit.Response>
---@return fun()
function UI.wrap_callback(data)
	return function()
		UI.draw_border()
		UI.handle_callback(data)
	end
end

-- Defers a callback
---@param data Rabbit.Recursive<Rabbit.Response>
---@param ms? integer | 5
function UI.defer_callback(data, ms)
	vim.defer_fn(UI.wrap_callback(data), ms or CONFIG.system.defer or 5)
end

-- Draws the border around the listing
function UI.draw_border()
	if not UI._bg.buf:exists() then
		return
	end

	local config = CONFIG.boxes.rabbit
	local win_config = UI._bg.win.config:Raw()
	local final_height = win_config.height - (CONFIG.window.legend and 1 or 0)

	---@type { [string]: Rabbit.Cls.Box.Part }
	local border_parts = {
		rise = { (config.chars.rise):rep(final_height / 4), false },
		rabbit = { CONFIG.system.name, true },
		plugin = { UI._plugin.name, true },
		head = { config.chars.emphasis, false },
		scroll = { "", false },
	}

	local tail = config.chars.emphasis
	local join_char, _, text = BOX.join_for(config, border_parts, "rabbit", "plugin", "head")
	local tail_len = (win_config.width - 2) / 2 - vim.api.nvim_strwidth(text .. join_char)

	if tail_len > 0 then
		tail = tail:rep(tail_len)
	end

	border_parts.tail = { tail, false }

	if type(config.right_side) == "table" then
		local off = 2
		local cur_line, max_line = unpack(vim.api.nvim_win_call(UI._fg.win.id, function()
			return { vim.fn.line(".") - 1, vim.fn.line("$") }
		end))
		local scroll_height = final_height - off

		local base = config.right_side.base
		local scroll_len = scroll_height / max_line
		scroll_len = math.max(1, math.ceil(scroll_len))
		local scroll_top = (cur_line / max_line * scroll_height)
		local frac = math.floor(scroll_top)
		scroll_top = math.min(frac + (scroll_top - frac < 0.5 and 0 or 1), scroll_height - scroll_len)
		border_parts.scroll[1] = base:rep(scroll_top) .. (config.chars.scroll or base):rep(scroll_len)
	end

	local c = UI._plugin.opts.color
	HL.apply({
		["rabbit.types.plugin"] = c,
	})

	local sides = BOX.make(win_config.width, final_height, config, border_parts)
	local lines = sides:to_hl({
		border_hl = "rabbit.types.plugin",
		title_hl = "rabbit.types.title",
	}).lines

	HL.set_lines({
		bufnr = UI._bg.buf.id,
		ns = UI._bg.ns,
		lines = lines,
		width = win_config.width,
		lineno = 0,
		strict = false,
		many = true,
	})
end

-- Creates the bounding box for the window
---@param win integer
---@param z integer
---@return vim.api.keyset.win_config
function UI.rect(win, z)
	local spawn = CONFIG.window.spawn
	local config = STACK._.user.win.config:Raw()

	local calc_width = spawn.width
	local calc_height = spawn.height

	if calc_width == nil then
		calc_width = 64
	elseif calc_width <= 1 then
		calc_width = math.floor(config.width * calc_width)
	end

	if calc_height == nil then
		calc_height = 24
	elseif calc_height <= 1 then
		calc_height = math.floor(config.height * calc_height)
	end

	local ret = { ---@type Rabbit.UI.Rect
		x = 0,
		y = 0,
		z = z or 10,
		w = config.width,
		h = config.height,
	}

	if spawn.mode == "split" then
		ret.split = spawn.side
		if spawn.side == "left" then
			ret.w = calc_width
		elseif spawn.side == "above" then
			ret.h = calc_height
		elseif spawn.side == "below" then
			ret.y = config.width - calc_height
			ret.h = calc_height
		else
			ret.x = config.height - calc_width
			ret.w = calc_width
		end
	end

	if spawn.mode == "float" then
		ret.w = calc_width
		ret.h = calc_height

		if spawn.side == "w" or spawn.side == "c" or spawn.side == "e" then
			ret.y = math.floor((config.height - calc_height) / 2)
		elseif spawn.side == "sw" or spawn.side == "s" or spawn.side == "se" then
			ret.y = config.height - calc_height
		end

		if spawn.side == "n" or spawn.side == "c" or spawn.side == "s" then
			ret.x = math.floor((config.width - calc_width) / 2)
		elseif spawn.side == "ne" or spawn.side == "e" or spawn.side == "se" then
			ret.x = config.width - calc_width
		end
	end

	return RECT.win(RECT.calc(ret, win))
end

-- Closes the window
---@param dbg? boolean Crashes when
function UI.close(dbg)
	local ns = NVIM.ns["rabbit.preview.search"]
	for bufid in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(bufid) and vim.api.nvim_buf_is_loaded(bufid) then
			vim.api.nvim_buf_clear_namespace(bufid, ns, 0, -1)
		end
	end
	UI._plugin._env.open = false

	if UI._bg ~= nil then
		UI.cancel_hover()
		UI._bg:close()
	end

	if UI._fg ~= nil then
		UI._fg:close()
	end

	UI._plugin._env.open = false
	UI._priority_legend = {}

	if #STACK._.open > 0 then
		_ = STACK._.user:focus(true)
		if not dbg and UI._dbg then
			error("Debugging")
		end
	end

	STACK._.clear()
end

-- Closes the window ONLY if the latest window is NOT generated by CTX via the scratch function
function UI.maybe_close()
	if vim.uv.hrtime() - STACK._.last_scratch < 250 * 1000000 then
		return
	end

	UI.close()
end

-- Deletes the hover windows
function UI.cancel_hover()
	local ns = NVIM.ns["rabbit.preview.search"]
	vim.api.nvim_buf_clear_namespace(STACK._.user.buf.id, ns, 0, -1)

	for winid, view in pairs(UI._views) do
		if not vim.api.nvim_win_is_valid(winid) then
			UI._hov[winid] = nil
			UI._views[winid] = nil
			goto continue
		end

		vim.api.nvim_buf_clear_namespace(vim.api.nvim_win_get_buf(winid), ns, 0, -1)

		local bufid = UI._hov[winid]
		if vim.api.nvim_buf_is_valid(bufid) then
			vim.api.nvim_win_set_buf(winid, bufid)
		else
			UI._hov[winid] = nil
		end

		vim.api.nvim_win_call(winid, NVIM.bind(vim.fn.winrestview, view))

		::continue::
	end

	for _, v in pairs(UI._pre) do
		v:close()
	end
	UI._pre = {}
end

-- Returns the current workspace
---@return Rabbit.Stack.Workspace "Background (border & legend)"
---@return Rabbit.Stack.Workspace "Foreground (listing)"
function UI.workspace()
	return UI._bg, UI._fg
end

return UI
