---@class Rabbit.UI.Listing
local UIL = {
	-- Last plugin called
	---@type Rabbit.Plugin
	---@diagnostic disable-next-line: missing-fields
	_plugin = {},
	_entries = {},
}

local RECT = require("rabbit.term.rect")
local CTX = require("rabbit.term.ctx")
local HL = require("rabbit.term.highlight")
local MEM = require("rabbit.util.mem")
local BOX = require("rabbit.term.border")
local CONFIG = require("rabbit.config")
local SET = require("rabbit.util.set")
local ACT = require("rabbit.actions")
local bufid, winid

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
		if bufid == vim.api.nvim_get_current_buf() then
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

		UIL.spawn(UIL._plugin)
	end,
})

-- Creates a buffer for the given plugin
---@param plugin Rabbit.Plugin
function UIL.spawn(plugin)
	if #CTX.stack > 0 then
		vim.api.nvim_set_current_win(CTX.user.win)
		vim.api.nvim_set_current_buf(CTX.user.buf)
		CTX.clear()
	end
	CTX.user = CTX.workspace()
	UIL._plugin = require("rabbit").plugins[plugin]
	if UIL._plugin == nil then
		error("Invalid plugin: " .. plugin)
	end

	-- Create background window
	local r = UIL.rect(CTX.user.win, 55)
	bufid = vim.api.nvim_create_buf(false, true)
	winid = vim.api.nvim_open_win(bufid, true, r)
	local bg = CTX.append(bufid, winid)
	bg.ns = vim.api.nvim_create_namespace("rabbit.bg")
	UIL._bg = bg

	-- Create foreground window
	r.split = nil
	r.relative = "win"
	r.row = 2
	r.col = 1
	r.width = r.width - 2
	r.height = r.height - 4
	r.zindex = r.zindex + 1
	bufid = vim.api.nvim_create_buf(false, true)
	winid = vim.api.nvim_open_win(bufid, true, r)
	local listing = CTX.append(bufid, winid, bg)
	listing.ns = vim.api.nvim_create_namespace("rabbit.listing")
	UIL._fg = listing
	bg.parent = listing -- Treat these as the same layer
	vim.wo[listing.win].cursorline = true

	local function redraw()
		UIL.draw_border(bg)
		UIL.apply_actions(bg, listing)
		-- vim.api.nvim_win_set_cursor(listing.win, { vim.fn.line("."), 0 })
	end

	vim.api.nvim_create_autocmd("CursorMoved", {
		buffer = listing.buf,
		callback = redraw,
	})

	bufid = -1

	UIL._plugin.list()
end

---@param entries Rabbit.Listing.Entry[]
function UIL.list(entries)
	UIL._entries = entries

	vim.api.nvim_buf_clear_namespace(UIL._fg.buf, UIL._fg.ns, 0, -1)

	local j = 0
	local k = 0

	for i, entry in ipairs(entries) do
		j = i
		local dirpart = {}
		local filepart = {}
		local headpart = {}
		local tailpart = {}

		if entry.type == "file" then
			local rel_path = MEM.rel_path({
				source = vim.api.nvim_buf_get_name(CTX.user.buf),
				target = entry.label,
				width = UIL._fg.conf.width,
				max_parts = CONFIG.window.overflow.distance_trim,
				cutoff = CONFIG.window.overflow.dirname_trim,
				overflow = CONFIG.window.overflow.distance_char,
				trim = CONFIG.window.overflow.dirname_char,
			})
			filepart = { text = rel_path.name, hl = { "rabbit.types.file" }, align = "left" }
			dirpart = { text = rel_path.dir, hl = { "rabbit.types.dir" }, align = "left" }
			vim.print(">>", rel_path, entry.label, "<<")
			-- return
		else
			filepart = {
				text = entry.label,
				hl = { "rabbit.types.collection", "rabbit.paint." .. entry.color },
				align = "left",
			}
		end

		if type(entry.head) == "string" then
			headpart = { text = entry.head .. " ", hl = "rabbit.types.head", align = "left" }
		elseif type(entry.head) == "table" then
			headpart = entry.head --[[@as Rabbit.Term.HlLine]]
		end

		if type(entry.tail) == "string" then
			tailpart = { text = entry.tail .. " ", hl = "rabbit.types.tail", align = "right" }
		elseif type(entry.tail) == "table" then
			tailpart = entry.tail --[[@as Rabbit.Term.HlLine]]
		end

		vim.print(headpart, dirpart, filepart, tailpart)
		local idx
		if entry.idx ~= false then
			k = k + 1
			idx = ("0"):rep(#tostring(#entries) - #tostring(k)) .. i .. "."
		else
			idx = (" "):rep(#tostring(#entries) + 1)
		end

		HL.nvim_buf_set_line(UIL._fg.buf, i - 1, false, UIL._fg.ns, UIL._fg.conf.width, {
			{
				text = " " .. idx .. " ",
				hl = "rabbit.types.index",
				align = "left",
			},
			headpart,
			dirpart,
			filepart,
			tailpart,
		})
	end

	vim.api.nvim_buf_set_lines(UIL._fg.buf, j, -1, false, {})

	UIL.draw_border(UIL._bg)
	UIL.apply_actions(UIL._bg, UIL._fg)
end

function UIL.apply_actions(bg, fg)
	local i = vim.fn.line(".")
	local e = UIL._entries[i] ---@type Rabbit.Listing.Entry

	if e == nil then
		return -- This shouldn't happen
	end

	local legend = {}
	local legend_parts = {}
	local all_actions = {}

	e.actions = e.actions or {}

	for key, _ in pairs(e.actions) do
		SET.add(all_actions, key)
	end

	for key, _ in pairs(UIL._plugin.act) do
		SET.add(all_actions, key)
	end

	for key, _ in pairs(UIL._plugin.opts.keys) do
		SET.add(all_actions, key)
	end

	for key, _ in pairs(ACT) do
		SET.add(all_actions, key)
	end

	for key, _ in pairs(CONFIG.keys) do
		SET.add(all_actions, key)
	end

	for _, key in ipairs(all_actions) do
		local action = e.actions[key]
		if action == false then
			goto continue
		elseif action == true or action == nil then
			action = {}
		elseif type(action) ~= "table" then
			error("Invalid action for " .. key .. ": Expected table, got " .. type(action))
		end

		action.keys = action.keys or UIL._plugin.opts.keys[key] or CONFIG.keys[key]
		if action.keys == nil then
			goto continue
		end

		if type(action.keys) == "string" then
			---@diagnostic disable-next-line: assign-type-mismatch
			action.keys = { action.keys }
		end

		action.callback = action.callback or UIL._plugin.act[key] or ACT[key]
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
				vim.keymap.set("n", k, function()
					action.callback(i, e, UIL._entries)
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
			text = action.title,
			hl = "rabbit.legend.action",
		})

		table.insert(legend_parts, {
			text = ":",
			hl = "rabbit.legend.separator",
		})

		table.insert(legend_parts, {
			text = action.keys[1] .. " ",
			hl = "rabbit.legend.key",
		})
	end

	HL.nvim_buf_set_line(bg.buf, bg.conf.height - 1, false, bg.ns, bg.conf.width, legend_parts)
end

---@param ws Rabbit.UI.Workspace
function UIL.draw_border(ws)
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
			titles.title_emphasis.right .. UIL._plugin .. titles.plugin_emphasis.right
		)
		apply_title(
			sides,
			titles.title_pos,
			titles.title_emphasis.left .. titles.title_text .. titles.title_emphasis.right,
			case_func[titles.plugin_case](UIL._plugin.opts.name),
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
			case_func[titles.plugin_case](UIL._plugin.opts.name),
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

	vim.api.nvim_set_hl(0, "rabbit.plugin", HL.gen_group(UIL._plugin.opts.color, "fg"))
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
function UIL.rect(win, z)
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

function UIL.close()
	vim.api.nvim_win_close(UIL._bg.win, true)
	vim.api.nvim_set_current_win(CTX.user.win)
	vim.api.nvim_set_current_buf(CTX.user.buf)
end
return UIL
