---@class Rabbit.UI.Listing
local UIL = {}

local rect = require("rabbit.term.rect")
local CTX = require("rabbit.term.ctx")
local bufid, winid
local last_plugin

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

local function apply_title(sides, mode, str)
	if type(str) ~= "string" then
		error("Expected string, got " .. type(str))
	end
	local target, align = unpack(({
		nw = { sides.t, "left" },
		n = { sides.t, "center" },
		ne = { sides.t, "right" },
		en = { sides.r, "left" },
		e = { sides.r, "center" },
		es = { sides.r, "right" },
		se = { sides.b, "right" },
		s = { sides.b, "center" },
		sw = { sides.b, "left" },
		ws = { sides.l, "right" },
		w = { sides.l, "center" },
		wn = { sides.l, "left" },
	})[mode])

	if target == nil then
		error("Invalid mode: " .. mode)
	end

	local strls = {}
	for _, v in ipairs(vim.fn.str2list(str)) do
		table.insert(strls, vim.fn.list2str({ v }))
	end

	if align == "left" then
		for i, v in ipairs(strls) do
			target[i] = v
		end
	elseif align == "center" then
		local start = math.max(1, math.ceil((#target - #strls + 1) / 2))
		local fin = math.min(#target, start + #strls - 1)
		local j = 1
		for i = start, fin do
			target[i] = strls[j]
			j = j + 1
		end
	else
		for i = #target - #strls + 1, #target do
			target[i] = strls[i - #target + #strls]
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

		UIL.spawn(last_plugin)
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
	last_plugin = plugin

	-- Create background window
	local r = UIL.rect(CTX.user.win, 55)
	bufid = vim.api.nvim_create_buf(false, true)
	winid = vim.api.nvim_open_win(bufid, true, r)
	local bg = CTX.append(bufid, winid)

	-- Draw border
	UIL.draw_border(bg)

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
	bg.parent = listing -- Treat these as the same layer
	bufid = -1
end

---@param ws Rabbit.UI.Workspace
function UIL.draw_border(ws)
	local titles = require("rabbit.config").window.titles
	local box = require("rabbit.term.border").normalize(require("rabbit.config").window.box)

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

	for i = 1, ws.conf.height - 2 do
		sides.l[i] = box.v
		sides.r[i] = box.v
	end

	if titles.title_pos == titles.plugin_pos then
		local text = titles.title_emphasis.left
			.. titles.title_text
			.. titles.title_emphasis.right
			.. last_plugin
			.. titles.plugin_emphasis.right
		apply_title(sides, titles.title_pos, case_func[titles.title_case](text))
	else
		apply_title(
			sides,
			titles.title_pos,
			case_func[titles.title_case](titles.title_emphasis.left .. titles.title_text .. titles.title_emphasis.right)
		)
		apply_title(
			sides,
			titles.plugin_pos,
			case_func[titles.plugin_case](titles.plugin_emphasis.left .. last_plugin .. titles.plugin_emphasis.right)
		)
	end

	local lines = {}
	table.insert(lines, box.nw .. table.concat(sides.t) .. box.ne)

	for i = 1, ws.conf.height - 2 do
		table.insert(lines, sides.l[i] .. (" "):rep(ws.conf.width - 2) .. sides.r[i])
	end

	table.insert(lines, box.sw .. table.concat(sides.b) .. box.se)
	vim.api.nvim_buf_set_lines(ws.buf, 0, -1, false, lines)
end

-- Creates the bounding box for the window
---@param win integer
---@param z integer
---@return vim.api.keyset.win_config
function UIL.rect(win, z)
	local spawn = require("rabbit.config").window.spawn

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

	return rect.win(rect.calc(ret, win))
end

return UIL
