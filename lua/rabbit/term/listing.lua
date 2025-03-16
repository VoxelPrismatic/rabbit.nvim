---@class Rabbit.UI.Listing
local UI = {
	-- Last plugin called
	---@type Rabbit.Plugin
	---@diagnostic disable-next-line: missing-fields
	_plugin = {}, ---@type Rabbit.Plugin
	_entries = {}, ---@type Rabbit.Entry[]
	_parent = nil, ---@type Rabbit.Entry.Collection
	_keys = {},
	_winid = 0,
	_bufid = 0,
	_pre = {}, ---@type { [string]: Rabbit.UI.Workspace }
	_hov = {}, ---@type { [integer]: integer }
}

local RECT = require("rabbit.term.rect")
local CTX = require("rabbit.term.ctx")
local HL = require("rabbit.term.highlight")
local MEM = require("rabbit.util.mem")
local BOX = require("rabbit.term.border")
local CONFIG = require("rabbit.config")
local SET = require("rabbit.util.set")
local ACTIONS = require("rabbit.actions")

---@param key string | string[]
---@return string[]
local function _K(key)
	if key == nil then
		return {}
	end
	return type(key) ~= "table" and { tostring(key) } or key --[[@as table<string>]]
end

local case_func = {
	upper = string.upper,
	lower = string.lower,
	unchanged = function(s)
		return s
	end,
	title = function(s)
		return s:gsub("(%w)(%w*)", function(a, b)
			return string.upper(a) .. string.lower(b)
		end)
	end,
}

vim.api.nvim_create_autocmd("BufEnter", {
	callback = function()
		if UI._bufid == vim.api.nvim_get_current_buf() then
			return
		end

		local w = vim.api.nvim_get_current_win()
		for _, v in ipairs(CTX.stack) do
			if v.win == w then
				return
			end
		end

		CTX.clear()
	end,
})

vim.api.nvim_create_autocmd("WinResized", {
	callback = function()
		if #CTX.stack == 0 then
			return
		end

		UI.spawn(UI._plugin)
	end,
})

-- Creates a buffer for the given plugin
---@param plugin string | Rabbit.Plugin
function UI.spawn(plugin)
	if #CTX.stack > 0 then
		vim.api.nvim_set_current_win(CTX.user.win)
		vim.api.nvim_set_current_buf(CTX.user.buf)
		CTX.clear()
	end

	CTX.user = CTX.workspace()

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

	-- Create background window
	local r = UI.rect(CTX.user.win, 55)
	UI._bufid = vim.api.nvim_create_buf(false, true)
	UI._winid = vim.api.nvim_open_win(UI._bufid, true, r)
	local bg = CTX.append(UI._bufid, UI._winid)
	bg.ns = vim.api.nvim_create_namespace("rabbit.bg")
	UI._bg = bg

	-- Create foreground window
	r.split = nil
	r.relative = "win"
	r.row = 1
	r.col = 1
	r.width = r.width - 2
	r.height = r.height - 3
	r.zindex = r.zindex + 1
	UI._bufid = vim.api.nvim_create_buf(false, true)
	UI._winid = vim.api.nvim_open_win(UI._bufid, true, r)
	local listing = CTX.append(UI._bufid, UI._winid, bg)
	listing.ns = vim.api.nvim_create_namespace("rabbit.listing")
	UI._fg = listing
	listing:add_child(bg) -- Treat these as the same layer
	vim.wo[listing.win].cursorline = true

	local function redraw()
		UI.draw_border(bg)
		UI.apply_actions()
		-- vim.api.nvim_win_set_cursor(listing.win, { vim.fn.line("."), 0 })
	end

	vim.api.nvim_create_autocmd("CursorMoved", {
		buffer = listing.buf,
		callback = redraw,
	})

	UI._bufid = -1

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

	UI._plugin._env = {
		plugin = UI._plugin,
		winid = CTX.user.win,
		cwd = cwd,
	}

	UI.handle_callback(UI._plugin.list())
end

-- Actually lists the entries. Also calls `apply_actions` at the end
---@param collection Rabbit.Entry.Collection
---@return Rabbit.Entry[]
function UI.list(collection)
	vim.bo[UI._fg.buf].modifiable = true
	if collection.actions.children == true then
		collection.actions.children = UI._plugin.actions.children
	elseif collection.actions.children == false then
		error("Invalid children")
	end

	UI._entries = collection.actions.children(collection)

	_ = pcall(vim.api.nvim_buf_clear_namespace, UI._fg.buf, UI._fg.ns, 0, -1)

	local j = 0
	local r = 0

	local auto_default = nil
	local man_default = nil

	local idx_len = #tostring(#UI._entries)

	for i, entry in ipairs(UI._entries) do
		j = i

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
		else
			idx = (" "):rep(idx_len - 1) .. "——"
		end

		HL.nvim_buf_set_line(UI._fg.buf, i - 1, false, UI._fg.ns, UI._fg.conf.width, {
			{
				text = " " .. idx .. " ",
				hl = "rabbit.types.index",
				align = "left",
			},
			UI.highlight(entry),
		})
	end

	vim.api.nvim_buf_set_lines(UI._fg.buf, j, -1, false, {})
	vim.api.nvim_win_set_cursor(UI._fg.win, { man_default or auto_default or 1, 0 })

	UI.draw_border(UI._bg)
	UI.apply_actions()

	vim.bo[UI._fg.buf].modifiable = false
	return UI._entries
end

-- Creates the highlights for a particular entry
---@param entry Rabbit.Entry
---@return Rabbit.Term.HlLine
function UI.highlight(entry)
	if entry.type == "file" then
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
						["rabbit.files.closed"] = entry.closed,
						["rabbit.types.index"] = entry.idx == false,
						"rabbit.files.file",
					},
					align = "left",
				},
				CONFIG.window.nrs and {
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
						["rabbit.files.closed"] = entry.closed,
						["rabbit.types.index"] = entry.idx == false,
						"rabbit.files.file",
					},
					align = "left",
				},
				CONFIG.window.nrs and {
					text = tostring(entry.bufid) .. " ",
					hl = { "rabbit.types.tail" },
					align = "right",
				} or {},
			}
		elseif entry.path == "" then
			return {
				{
					text = "#nil ",
					hl = { "rabbit.files.void" },
					align = "left",
				},
				{
					text = tostring(entry.bufid),
					hl = {
						["rabbit.files.closed"] = entry.closed,
						["rabbit.types.index"] = entry.idx == false,
						"rabbit.files.file",
					},
					align = "left",
				},
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
			CONFIG.window.nrs and {
				text = tostring(entry.bufid) .. " ",
				hl = { "rabbit.types.tail" },
				align = "right",
			} or {},
		}
	elseif entry.type == "collection" then
		entry = entry --[[@as Rabbit.Entry.Collection]]
		return {
			type(entry.label) == "string" and { text = entry.label, hl = { "rabbit.paint.iris" }, align = "left" }
				or entry.label
				or {},
			type(entry.tail) == "string" and { text = entry.tail, hl = { "rabbit.types.tail" }, align = "right" }
				or entry.tail
				or {},
		}
	end
	error("Not implemented for type: " .. entry.type)
end

---@param action string
---@param entry Rabbit.Entry
---@return fun(e: Rabbit.Entry) | nil
---@return string[]
local function find_action(action, entry)
	local callback = entry.actions[action]
	if callback == false then
		return nil, {}
	elseif callback == true or callback == nil then
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
	local bg = UI._bg
	local fg = UI._fg
	local i = vim.fn.line(".")
	local e = UI._entries[i] ---@type Rabbit.Entry

	if e == nil then
		local keys = _K(CONFIG.keys.close)
		if #keys < 1 then
			keys = { "q", "<Esc>" }
		end
		for _, k in ipairs(keys) do
			_ = pcall(vim.keymap.del, "n", k, { buffer = UI._fg.buf })
		end

		return -- This shouldn't happen
	end

	UI._keys = SET.new()
	local legend = {}
	local legend_parts = {}
	local all_actions = SET.new() ---@type Rabbit.Table.Set<string>

	e.actions = e.actions or {}

	for _, key in ipairs(UI._keys) do
		_ = pcall(vim.keymap.del, "n", key, { buffer = UI._fg.buf })
	end

	all_actions
		:add({
			SET.keys(e.actions),
			SET.keys(UI._plugin.actions),
			SET.keys(UI._plugin.opts.keys),
			SET.keys(ACTIONS),
			SET.keys(CONFIG.keys),
		})
		:del("hover")

	for _, action in ipairs(all_actions) do
		local cb, keys = find_action(action, e)
		if #keys == 0 or cb == nil then
			goto continue
		end

		table.insert(legend, {
			title = action,
			keys = keys,
		})

		for _, k in ipairs(keys) do
			if type(k) == "string" then
				UI._keys:add(k)
				vim.keymap.set("n", k, function()
					e._env = {
						idx = i,
						entry = e,
						siblings = UI._entries,
						parent = UI._parent,
						cwd = UI._plugin._env.cwd.value,
					}
					UI.handle_callback(cb(e))
				end, { buffer = fg.buf })
			else
				error("Invalid key: " .. vim.inspect(k))
			end
		end
		::continue::
	end

	table.sort(legend, function(a, b)
		return a.title < b.title
	end)

	for _, action in ipairs(legend) do
		table.insert(legend_parts, {
			{
				text = " " .. action.title,
				hl = "rabbit.legend.action",
			},
			{
				text = ":",
				hl = "rabbit.legend.separator",
			},
			{
				text = action.keys[1],
				hl = "rabbit.legend.key",
			},
		})
	end

	HL.nvim_buf_set_line(bg.buf, bg.conf.height - 1, false, bg.ns, bg.conf.width, legend_parts)

	if e.actions.hover then
		UI.handle_callback(find_action("hover", e)(e))
	elseif UI._pre.l ~= nil then
		UI._pre.l:close()
		UI._pre.r:close()
		UI._pre.b:close()
		UI._pre.t:close()
		for winid, bufid in pairs(UI._hov) do
			UI._bufid = bufid
			vim.api.nvim_win_set_buf(winid, bufid)
			UI._hov[winid] = nil
		end
	end
end

function UI.handle_callback(data)
	if data == nil then
		return CTX.clear()
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
---@param ws Rabbit.UI.Workspace
function UI.draw_border(ws)
	local titles = CONFIG.window.titles
	local box = BOX.normalize(CONFIG.window.box)
	local final_height = ws.conf.height - (CONFIG.window.legend and 1 or 0)

	local sides ---@type Rabbit.Term.Border.Applied

	local scroll_len = (final_height - 2) / vim.fn.line("$")
	local scroll_top = scroll_len * (vim.fn.line(".") - 1)
	scroll_len = math.max(1, math.ceil(scroll_len))
	local scroll_func = { ---@type Rabbit.Term.Border.Side | nil
		align = "en",
		text = "",
		pre = box.v:rep(scroll_top),
		suf = (box.scroll or box.v):rep(scroll_len),
	}

	if titles[1] == nil then
		if
			titles.title_pos == "es"
			or titles.plugin_pos == "es"
			or titles.title_pos == "e"
			or titles.plugin_pos == "e"
			or titles.title_pos == "en"
			or titles.plugin_pos == "en"
		then
			scroll_func = nil
		end

		local title = case_func[titles.title_case](titles.title_text)
		local plugin = case_func[titles.plugin_case](UI._plugin.name)

		if titles.title_pos == titles.plugin_pos then
			sides = BOX.make_sides(ws.conf.width, final_height, box, {
				align = titles.title_pos,
				pre = titles.title_emphasis.left,
				text = title,
				suf = titles.title_emphasis.right .. plugin .. titles.plugin_emphasis.right,
			}, {
				align = titles.title_pos,
				pre = titles.title_emphasis.left .. title .. titles.title_emphasis.right,
				text = plugin,
				suf = titles.plugin_emphasis.right,
			}, scroll_func)
		else
			sides = BOX.make_sides(ws.conf.width, final_height, box, {
				align = titles.title_pos,
				pre = titles.title_emphasis.left,
				text = title,
				suf = titles.title_emphasis.right,
			}, {
				align = titles.plugin_pos,
				pre = titles.plugin_emphasis.left,
				text = plugin,
				suf = titles.plugin_emphasis.right,
			})
		end
	else
		sides = BOX.make_sides(ws.conf.width, final_height, box, scroll_func, unpack(titles))
	end

	local lines = {}
	local st = box.nw .. table.concat(sides.t.txt, "") .. box.ne
	table.insert(lines, st)

	for i = 1, final_height - 2 do
		table.insert(lines, sides.l.txt[i] .. (" "):rep(ws.conf.width - 2) .. sides.r.txt[i])
	end

	table.insert(lines, box.sw .. table.concat(sides.b.txt, "") .. box.se)

	if CONFIG.window.legend then
		table.insert(lines, "")
	end

	vim.api.nvim_buf_set_lines(ws.buf, 0, -1, false, lines)

	local c = UI._plugin.opts.color
	HL.set_group(0, {
		["rabbit.plugin"] = type(c) == "string" and { fg = c } or c,
		["rabbit.plugin.inv"] = {
			fg = ":rabbit.plugin",
			bg = ":Folded",
		},
	})
	HL.apply()

	for i = 1, ws.conf.height do
		vim.api.nvim_buf_add_highlight(ws.buf, ws.ns, "rabbit.plugin", i - 1, 0, -1)
	end

	for _, v in ipairs(sides.t.hl) do
		vim.api.nvim_buf_add_highlight(ws.buf, ws.ns, "rabbit.types.title", 0, v + #box.nw - 1, v + #box.nw)
	end

	for _, v in ipairs(sides.b.hl) do
		vim.api.nvim_buf_add_highlight(
			ws.buf,
			ws.ns,
			"rabbit.types.title",
			final_height - 1,
			v + #box.sw - 1,
			v + #box.sw
		)
	end

	for _, v in ipairs(sides.l.hl) do
		vim.api.nvim_buf_add_highlight(ws.buf, ws.ns, "rabbit.types.title", v, 0, 1)
	end

	for _, v in ipairs(sides.r.hl) do
		vim.api.nvim_buf_add_highlight(ws.buf, ws.ns, "rabbit.types.title", v, ws.conf.width - 1, 1)
	end
end

-- Creates the bounding box for the window
---@param win integer
---@param z integer
---@return vim.api.keyset.win_config
function UI.rect(win, z)
	local spawn = CONFIG.window.spawn

	local calc_width = spawn.width
	local calc_height = spawn.height

	if calc_width == nil then
		calc_width = 64
	elseif calc_width <= 1 then
		calc_width = math.floor(CTX.user.conf.width * calc_width)
	end

	if calc_height == nil then
		calc_height = 24
	elseif calc_height <= 1 then
		calc_height = math.floor(CTX.user.conf.height * calc_height)
	end

	local ret = { ---@type Rabbit.UI.Rect
		x = 0,
		y = 0,
		z = z or 10,
		w = CTX.user.conf.width,
		h = CTX.user.conf.height,
	}

	if spawn.mode == "split" then
		ret.split = spawn.side
		if spawn.side == "left" then
			ret.w = calc_width
		elseif spawn.side == "above" then
			ret.h = calc_height
		elseif spawn.side == "below" then
			ret.y = CTX.user.conf.height - calc_height
			ret.h = calc_height
		else
			ret.x = CTX.user.conf.width - calc_width
			ret.w = calc_width
		end
	end

	if spawn.mode == "float" then
		ret.w = calc_width
		ret.h = calc_height

		if spawn.side == "w" or spawn.side == "c" or spawn.side == "e" then
			ret.y = math.floor((CTX.user.conf.height - calc_height) / 2)
		elseif spawn.side == "sw" or spawn.side == "s" or spawn.side == "se" then
			ret.y = CTX.user.conf.height - calc_height
		end

		if spawn.side == "n" or spawn.side == "c" or spawn.side == "s" then
			ret.x = math.floor((CTX.user.conf.width - calc_width) / 2)
		elseif spawn.side == "ne" or spawn.side == "e" or spawn.side == "se" then
			ret.x = CTX.user.conf.width - calc_width
		end
	end

	return RECT.win(RECT.calc(ret, win))
end

-- Closes the window
function UI.close()
	vim.api.nvim_win_close(UI._bg.win, true)
	vim.api.nvim_set_current_win(CTX.user.win)
	vim.api.nvim_set_current_buf(CTX.user.buf)
end

-- Returns the current workspace
---@return Rabbit.UI.Workspace, Rabbit.UI.Workspace
function UI.workspace()
	return UI._bg, UI._fg
end

return UI
