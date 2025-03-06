---@class Rabbit.UI.Listing
local UIL = {
	-- Last plugin called
	---@type Rabbit.Plugin
	---@diagnostic disable-next-line: missing-fields
	_plugin = {},
}

local RECT = require("rabbit.term.rect")
local CTX = require("rabbit.term.ctx")
local HL = require("rabbit.term.highlight")
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
		UIL.apply_actions(listing)
	end

	vim.api.nvim_create_autocmd("CursorMoved", {
		buffer = listing.buf,
		callback = redraw,
	})

	vim.keymap.set({ "n", "i", "v", "x" }, "<Left>", "", { buffer = listing.buf })
	vim.keymap.set({ "n", "i", "v", "x" }, "<Right>", "", { buffer = listing.buf })

	bufid = -1
end

---@param entries Rabbit.Listing.Entry[]
function UIL.list(entries)
	UIL._entries = entries

	vim.api.nvim_buf_set_lines(UIL._fg.buf, 0, -1, false, entries)

	UIL.draw_border(UIL._bg)
	UIL.apply_actions(UIL._fg)
end

function UIL.apply_actions(ws)
	local i = vim.fn.line(".")
	local e = UIL._entries[i]
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

	HL.apply()
	vim.api.nvim_set_hl(0, "rabbit.plugin", HL.gen_group("#d875a7", "fg"))

	for i = 1, ws.conf.height do
		vim.api.nvim_buf_add_highlight(ws.buf, ws.ns, "rabbit.plugin", i - 1, 0, -1)
	end

	for _, v in ipairs(sides.hl_t) do
		vim.api.nvim_buf_add_highlight(ws.buf, ws.ns, "rabbit.type.title", 0, v + #box.nw - 1, v + #box.nw)
	end

	for _, v in ipairs(sides.hl_b) do
		vim.api.nvim_buf_add_highlight(
			ws.buf,
			ws.ns,
			"rabbit.type.title",
			final_height - 1,
			v + #box.sw - 1,
			v + #box.sw
		)
	end

	for _, v in ipairs(sides.hl_l) do
		vim.api.nvim_buf_add_highlight(ws.buf, ws.ns, "rabbit.type.title", v, 0, 1)
	end

	for _, v in ipairs(sides.hl_r) do
		vim.api.nvim_buf_add_highlight(ws.buf, ws.ns, "rabbit.type.title", v, ws.conf.width - 1, 1)
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

return UIL
