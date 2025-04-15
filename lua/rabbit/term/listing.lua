local RECT = require("rabbit.term.rect")
local HL = require("rabbit.term.highlight")
local MEM = require("rabbit.util.mem")
local BOX = require("rabbit.term.border")
local CONFIG = require("rabbit.config")
local SET = require("rabbit.util.set")
local LSP = require("rabbit.util.lsp")
local TERM = require("rabbit.util.term")
local STACK = require("rabbit.term.stack")
local ACTIONS

---@class Rabbit.UI.Listing
local UI = {
	-- Last plugin called
	---@type Rabbit.Plugin
	---@diagnostic disable-next-line: missing-fields
	_plugin = {}, ---@type Rabbit.Plugin

	-- List of entries currently on screen
	_entries = {}, ---@type Rabbit.Entry[]

	-- Parent collection that generated entries on screen
	_parent = nil, ---@type Rabbit.Entry.Collection

	-- Should be the same as _parent
	_display = nil, ---@type Rabbit.Entry.Collection

	-- Keymaps currently bound
	_keys = {}, ---@type Rabbit.Table.Set<string>

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
		UI.close()
	end

	for _, winid in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_config(winid).relative == "" then
			UI._hov[winid] = vim.api.nvim_win_get_buf(winid)
			UI._views[winid] = vim.api.nvim_win_call(winid, vim.fn.winsaveview)
		end
	end

	STACK._.user = STACK.ws.from()

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
		UI.draw_border(UI._bg)
		UI.apply_actions()
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

	local cwd = { ---@type Rabbit.Plugin.Context.Directory
		value = nil,
		scope = "fallback",
		raw = vim.fn.getcwd,
	}

	if UI._plugin.opts.cwd then
		cwd.raw = UI._plugin.opts.cwd
		cwd.scope = "plugin"
	elseif CONFIG.cwd then
		cwd.raw = CONFIG.cwd
		cwd.scope = "global"
	end

	if type(cwd.raw) == "function" then
		cwd.value = cwd.raw()
	end

	-- Do not reassign in case _env is a reference to a module
	UI._plugin._env.plugin = UI._plugin
	UI._plugin._env.winid = STACK._.user.win.id
	UI._plugin._env.cwd = cwd
	UI._plugin._env.open = true
	UI._plugin._env.bufid = STACK._.user.buf.id
	UI._plugin._env.hov = UI._hov

	UI.handle_callback(UI._plugin.list())
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
		local j = 0
		local r = 0

		local auto_default = nil
		local man_default = nil

		local idx_len = #tostring(#UI._entries)

		for i, entry in ipairs(UI._entries) do
			j = i
			auto_default, man_default, r = UI.place_entry(entry, j, r, idx_len, auto_default, man_default)
		end

		UI._fg.buf.o.modifiable = true
		UI._fg.cursor:set(man_default or auto_default or 1, 0)
		vim.api.nvim_buf_set_lines(UI._fg.buf.id, j, -1, false, {})
	else
		UI._fg.buf.o.modifiable = true
		local lines = TERM.wrap(UI._plugin.empty.msg, UI._fg.win.config.width)
		table.insert(lines, "")
		UI._fg.lines:set(lines)
		UI._fg.cursor:set(#lines, 0)
	end

	UI.draw_border(UI._bg)
	UI.apply_actions()
	UI._fg.buf.o.modifiable = false

	return UI._entries
end

-- Redraws this entry at it's current position. Shorthand for:
-- `UI.place_entry(entry, entry._env.idx, entry._env.real - 1, #tostring(#UI._entries))`
-- **WARNING:** This entry must be placed first (must have _env set)
---@param entry Rabbit.Entry
function UI.redraw_entry(entry)
	UI.place_entry(entry, entry._env.idx, entry._env.real - 1, #tostring(#UI._entries))
end

---@param entry Rabbit.Entry
---@param j number Index (line number).
---@param r number Real index.
---@param idx_len number String length of max index.
---@param auto_default? number Default index to select.
---@param man_default? number Manual index to select.
---@return number | nil "auto_default"
---@return number | nil "man_default"
---@return number "real index"
function UI.place_entry(entry, j, r, idx_len, auto_default, man_default)
	UI._fg.buf.o.modifiable = true

	entry._env = {
		idx = j,
		real = entry.idx and r + 1 or nil,
		entry = entry,
		siblings = UI._entries,
		parent = UI._display,
		cwd = UI._plugin._env.cwd.value,
		ident = "",
	}

	for k, v in ipairs(entry.actions) do
		if v == false or v == nil then
			entry.actions[k] = nil
		elseif v == true then
			entry.actions[k] = {
				action = k,
				callback = UI._plugin.actions[v] or ACTIONS[v],
			}
		elseif type(v) == "function" then
			entry.actions[k] = {
				action = k,
				callback = v,
			}
		elseif type(v) ~= "table" then
			error("Invalid action for " .. k .. ": Expected table, function, or boolean; got " .. type(v))
		end
	end

	local idx
	if entry.idx ~= false then
		r = r + 1
		auto_default = auto_default or j
		man_default = entry.default and (man_default or j) or man_default
		idx = ("0"):rep(idx_len - #tostring(r)) .. r .. "."
		if r < 10 and entry.actions.select then
			vim.keymap.set("n", tostring(r), function()
				UI.handle_callback(UI.find_action("select", entry)(entry))
			end, {
				buffer = UI._fg.buf.id,
			})
		end
	else
		idx = ("—"):rep(idx_len + 1)
		man_default = entry.default and (man_default or j) or man_default
	end

	entry._env.ident = " " .. idx .. "\u{a0}"

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
		start = j - 1,
	})

	if entry.synopsis and CONFIG.window.synopsis.mode == "always" then
		UI.synopsis(entry, j)
	end

	UI._fg.buf.o.modifiable = false
	return auto_default, man_default, r
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

-- Creates the highlights for a particular entry
---@param entry Rabbit.Entry
---@return Rabbit.Term.HlLine
function UI.highlight(entry)
	if entry.type == "collection" then
		entry = entry --[[@as Rabbit.Entry.Collection]]
		return {
			type(entry.label) == "string" and { text = entry.label, hl = { "rabbit.paint.iris" }, align = "left" }
				or entry.label
				or {},
			type(entry.tail) == "string" and { text = entry.tail, hl = { "rabbit.types.tail" }, align = "right" }
				or entry.tail
				or {},
		}
	elseif entry.type ~= "file" then
		error("Highlight not implemented for type: " .. entry.type)
	end

	entry = entry --[[@as Rabbit.Entry.File]]
	if entry.label then
		return { entry.label }
	end

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
				text = CONFIG.window.icons.modified .. " ",
				hl = { "rabbit.files.modified" },
				align = "right",
			})
		end

		if CONFIG.window.beacon.readonly and vim.bo[entry.bufid].readonly then
			table.insert(extras, {
				text = CONFIG.window.icons.readonly .. " ",
				hl = { "rabbit.files.readonly" },
				align = "right",
			})
		end

		local lsp_count = LSP.get_count(entry.bufid, CONFIG.window.beacon.lsp)
		for k, v in pairs(lsp_count) do
			if v > 0 then
				table.insert(extras, {
					text = CONFIG.window.icons["lsp_" .. k] .. v .. " ",
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
---@return fun(e: Rabbit.Entry) | nil
---@return string[]
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

	for _, key in ipairs(UI._keys) do
		_ = pcall(vim.keymap.del, "n", key, { buffer = UI._fg.buf.id })
	end

	UI._keys = SET.new()
	UI._plugins = {}
	local all_actions = SET.new() ---@type Rabbit.Table.Set<string>

	e.actions = e.actions or {}

	all_actions
		:add({
			SET.keys(e.actions),
			SET.keys(UI._plugin.actions),
			SET.keys(UI._plugin.opts.keys),
			SET.keys(ACTIONS),
			SET.keys(CONFIG.keys),
		})
		:del("hover")

	UI._fg.keys:clear()

	if e.actions.parent then
		local _, val = pcall(UI.find_action("parent", e) or function() end, e)
		if val == UI._display then
			all_actions:del("parent")
		end
	end

	for _, action in ipairs(all_actions) do
		local cb, keys = UI.find_action(action, e)
		if #keys == 0 or cb == nil then
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
			label = action,
			keys = keys,
			callback = function()
				UI.handle_callback(cb(e))
			end,
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

		UI._keys:add(switches)
		local part = UI._fg.keys:add({
			label = name,
			keys = switches,
			callback = function()
				UI.spawn(plugin)
			end,
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
		UI.handle_callback(UI.find_action("hover", e)(e))
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
---@param data? Rabbit.Response
function UI.handle_callback(data)
	if data == false then
		return
	end

	if data == nil then
		return UI.close()
	end

	if data.class == "entry" then
		data = data --[[@as Rabbit.Entry]]
		if data.type == "collection" then
			data = data --[[@as Rabbit.Entry.Collection]]
			UI._parent = data
			return UI.list(UI._parent)
		end
	elseif data.class == "message" then
		return require("rabbit.messages").Handle(data)
	end

	error("Callback data not implemented: " .. vim.inspect(data))
end

-- Draws the border around the listing
---@param ws Rabbit.Stack.Workspace
function UI.draw_border(ws)
	local config = CONFIG.boxes.rabbit
	local final_height = ws.win.config.height - (CONFIG.window.legend and 1 or 0)

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
	local tail_len = (ws.win.config.width - 2) / 2 - vim.api.nvim_strwidth(text) - vim.api.nvim_strwidth(join_char)

	if tail_len > 0 then
		tail = tail:rep(tail_len)
	end

	border_parts.tail = { tail, false }

	if type(config.right_side) == "table" then
		local base = config.right_side.base
		local scroll_len = (final_height - 2) / vim.fn.line("$")
		scroll_len = math.max(1, math.ceil(scroll_len))
		local scroll_top = ((vim.fn.line(".") - 1) / vim.fn.line("$") * (final_height - 2))
		local frac = math.floor(scroll_top)
		scroll_top = frac + (scroll_top - frac < 0.5 and 0 or 1)
		border_parts.scroll[1] = base:rep(scroll_top) .. (config.chars.scroll or base):rep(scroll_len)
	end

	local c = UI._plugin.opts.color
	HL.apply({
		["rabbit.types.plugin"] = c,
	})

	local sides = BOX.make(ws.win.config.width, final_height, config, border_parts)
	local lines = sides:to_hl({
		border_hl = "rabbit.types.plugin",
		title_hl = "rabbit.types.title",
	}).lines

	HL.set_lines({
		bufnr = UI._bg.buf.id,
		ns = UI._bg.ns,
		lines = lines,
		width = ws.win.config.width,
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
	local config = STACK._.user.win.config

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
function UI.close()
	if #STACK._.open == 0 then
		return
	end

	_ = STACK._.user:focus(true)

	if UI._bg ~= nil then
		UI.cancel_hover()
		UI._bg:close()
	end

	STACK._.clear()

	UI._plugin._env.open = false
	UI._priority_legend = {}
end

-- Closes the window ONLY if the latest window is NOT generated by CTX via the scratch function
function UI.maybe_close()
	if vim.uv.hrtime() - STACK._.last_scratch > 250 * 1000000 then
		UI.close()
	end
end

-- Deletes the hover windows
function UI.cancel_hover()
	local ns = vim.api.nvim_create_namespace("rabbit.preview.search")

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

		vim.api.nvim_win_call(winid, function()
			vim.fn.winrestview(view)
		end)

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
