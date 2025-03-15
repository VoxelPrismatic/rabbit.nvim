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
}

local RECT = require("rabbit.term.rect")
local CTX = require("rabbit.term.ctx")
local HL = require("rabbit.term.highlight")
local MEM = require("rabbit.util.mem")
local BOX = require("rabbit.term.border")
local CONFIG = require("rabbit.config")
local SET = require("rabbit.util.set")
local ACT = require("rabbit.actions")

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

-- Draws a title on the given sides
---@param sides table
---@param mode string
---@param prefix string
---@param str string
---@param suffix string
local function apply_title(sides, mode, prefix, str, suffix)
	sides.hl_t = sides.hl_t or {}
	sides.hl_b = sides.hl_b or {}
	sides.hl_l = sides.hl_l or {}
	sides.hl_r = sides.hl_r or {}

	local target, hl_target, align = unpack(({
		nw = { sides.t, sides.hl_t, "left" },
		n = { sides.t, sides.hl_t, "center" },
		ne = { sides.t, sides.hl_t, "right" },
		en = { sides.r, sides.hl_r, "left" },
		e = { sides.r, sides.hl_r, "center" },
		es = { sides.r, sides.hl_r, "right" },
		se = { sides.b, sides.hl_b, "right" },
		s = { sides.b, sides.hl_b, "center" },
		sw = { sides.b, sides.hl_b, "left" },
		ws = { sides.l, sides.hl_l, "right" },
		w = { sides.l, sides.hl_l, "center" },
		wn = { sides.l, sides.hl_l, "left" },
	})[mode])

	if target == nil then
		error("Invalid mode: " .. mode)
	end

	local strls = {}
	for _, v in ipairs(vim.fn.str2list(prefix .. str .. suffix)) do
		table.insert(strls, vim.fn.list2str({ v }))
	end

	if align == "left" then
		for i, v in ipairs(strls) do
			target[i] = v
			if vim.fn.strwidth(prefix) < i and i <= vim.fn.strwidth(prefix .. str) then
				hl_target[#hl_target + 1] = #table.concat(strls, "", 1, i)
			end
		end
	elseif align == "center" then
		local start = math.max(1, math.ceil((#target - #strls + 1) / 2))
		local fin = math.min(#target, start + #strls - 1)
		local j = 1
		for i = start, fin do
			target[i] = strls[j]
			if vim.fn.strwidth(prefix) < j and j <= vim.fn.strwidth(prefix .. str) then
				---@diagnostic disable-next-line: param-type-mismatch
				hl_target[#hl_target + 1] = #table.concat(target, "", 1, i)
			end
			j = j + 1
		end
	else
		for i = #target - #strls + 1, #target do
			local j = i - #target + #strls
			target[i] = strls[j]
			if vim.fn.strwidth(prefix) < j and j <= vim.fn.strwidth(prefix .. str) then
				hl_target[#hl_target + 1] = i
			end
		end
	end
end

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
	bg.parent = listing -- Treat these as the same layer
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
					callback = UI._plugin.actions[v] or ACT[v],
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
		if tostring(entry.path):find("term://") == 1 then
			return {
				{
					text = tostring(entry.path):gsub("^.*/(%w+)$", "%1"),
					hl = { "rabbit.files.term" },
					align = "left",
				},
				{
					text = " $ ",
					hl = { "rabbit.legend.separator" },
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
					text = tostring(entry.path):gsub(".*(%d+):.*$", "%1") .. " ",
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

	all_actions:add({
		SET.keys(e.actions),
		SET.keys(UI._plugin.actions),
		SET.keys(UI._plugin.opts.keys),
		SET.keys(ACT),
		SET.keys(CONFIG.keys),
	})

	for _, key in ipairs(all_actions) do
		local action = e.actions[key]
		if action == false then
			goto continue
		elseif action == true or action == nil then
			action = {}
		elseif type(action) == "function" then
			action = {
				callback = action,
			}
		elseif type(action) ~= "table" then
			error("Invalid action for " .. key .. ": Expected table, got " .. type(action))
		end

		action.keys = _K(action.keys or UI._plugin.opts.keys[key] or CONFIG.keys[key])
		if #action.keys == 0 then
			goto continue
		end

		action.callback = action.callback or UI._plugin.actions[key] or ACT[key]
		if action.callback == nil then
			goto continue
		end

		action.title = action.title or key

		action.priority = action.priority or 0

		table.insert(legend, action)

		for _, k in
			ipairs(action.keys --[[@as table<string>]])
		do
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
					UI.handle_callback(action.callback(e))
				end, { buffer = fg.buf })
			else
				error("Invalid key: " .. vim.inspect(k))
			end
		end
		::continue::
	end

	table.sort(legend, function(a, b)
		return a.priority > b.priority
	end)

	for _, action in ipairs(legend) do
		table.insert(legend_parts, {
			text = " " .. action.title,
			hl = "rabbit.legend.action",
		})

		table.insert(legend_parts, {
			text = ":",
			hl = "rabbit.legend.separator",
		})

		table.insert(legend_parts, {
			text = action.keys[1],
			hl = "rabbit.legend.key",
		})
	end

	HL.nvim_buf_set_line(bg.buf, bg.conf.height - 1, false, bg.ns, bg.conf.width, legend_parts)
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
	end

	error("Callback data not implemented: " .. vim.inspect(data))
end

-- Draws the border around the listing
---@param ws Rabbit.UI.Workspace
function UI.draw_border(ws)
	local titles = CONFIG.window.titles
	local box = BOX.normalize(CONFIG.window.box)
	local final_height = ws.conf.height - (CONFIG.window.legend and 1 or 0)

	local sides = {
		t = {},
		b = {},
		r = {},
		l = {},
	}

	for i = 1, ws.conf.width - 2 do
		sides.t[i] = box.h
		sides.b[i] = box.h
	end

	local scroll_top = 0
	local scroll_len = 0
	if
		titles.title_pos ~= "es"
		and titles.plugin_pos ~= "es"
		and titles.title_pos ~= "e"
		and titles.plugin_pos ~= "e"
		and titles.title_pos ~= "en"
		and titles.plugin_pos ~= "en"
	then
		scroll_len = (final_height - 2) / vim.fn.line("$")
		scroll_top = scroll_len * (vim.fn.line(".") - 1)
		scroll_len = math.max(1, scroll_len)
	end

	for i = 1, final_height - 2 do
		sides.l[i] = box.v
		if scroll_top <= i and i <= scroll_top + scroll_len then
			sides.r[i] = box.scroll or box.v
		else
			sides.r[i] = box.v
		end
	end

	if titles.title_pos == titles.plugin_pos then
		apply_title(
			sides,
			titles.title_pos,
			titles.title_emphasis.left,
			case_func[titles.title_case](titles.title_text),
			titles.title_emphasis.right .. UI._plugin .. titles.plugin_emphasis.right
		)
		apply_title(
			sides,
			titles.title_pos,
			titles.title_emphasis.left .. titles.title_text .. titles.title_emphasis.right,
			case_func[titles.plugin_case](UI._plugin.name),
			titles.plugin_emphasis.right
		)
	else
		apply_title(
			sides,
			titles.title_pos,
			titles.title_emphasis.left,
			case_func[titles.title_case](titles.title_text),
			titles.title_emphasis.right
		)
		apply_title(
			sides,
			titles.plugin_pos,
			titles.plugin_emphasis.left,
			case_func[titles.plugin_case](UI._plugin.name),
			titles.plugin_emphasis.right
		)
	end

	local lines = {}
	local st = box.nw .. table.concat(sides.t) .. box.ne
	table.insert(lines, st)

	for i = 1, final_height - 2 do
		table.insert(lines, sides.l[i] .. (" "):rep(ws.conf.width - 2) .. sides.r[i])
	end

	table.insert(lines, box.sw .. table.concat(sides.b) .. box.se)

	if CONFIG.window.legend then
		table.insert(lines, "")
	end

	vim.api.nvim_buf_set_lines(ws.buf, 0, -1, false, lines)

	vim.api.nvim_set_hl(0, "rabbit.plugin", HL.gen_group(UI._plugin.opts.color, "fg"))
	HL.apply()

	for i = 1, ws.conf.height do
		vim.api.nvim_buf_add_highlight(ws.buf, ws.ns, "rabbit.plugin", i - 1, 0, -1)
	end

	for _, v in ipairs(sides.hl_t) do
		vim.api.nvim_buf_add_highlight(ws.buf, ws.ns, "rabbit.types.title", 0, v + #box.nw - 1, v + #box.nw)
	end

	for _, v in ipairs(sides.hl_b) do
		vim.api.nvim_buf_add_highlight(
			ws.buf,
			ws.ns,
			"rabbit.types.title",
			final_height - 1,
			v + #box.sw - 1,
			v + #box.sw
		)
	end

	for _, v in ipairs(sides.hl_l) do
		vim.api.nvim_buf_add_highlight(ws.buf, ws.ns, "rabbit.types.title", v, 0, 1)
	end

	for _, v in ipairs(sides.hl_r) do
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
