local UI = require("rabbit.term.listing")
local BOX = require("rabbit.term.border")
local MEM = require("rabbit.util.mem")
local CONFIG = require("rabbit.config")
local TERM = require("rabbit.util.term")
local STACK = require("rabbit.term.stack")
local NVIM = require("rabbit.util.nvim")

local preview_ws ---@type Rabbit.Stack.Workspace | nil

---@class Rabbit.Caching.Message.Preview.WinConfig
---@field l vim.api.keyset.win_config Right config.
---@field r vim.api.keyset.win_config Left config.
---@field t vim.api.keyset.win_config Top config.
---@field b vim.api.keyset.win_config Bottom config.
---@field w vim.api.keyset.win_config Target window config.
---@field [0] uv.uv_timer_t Timer to clear cache after 10m
---@field [string] Rabbit.Term.Border.Generic<Rabbit.Term.HlLine> Borders for the window (per file).

---@param win_config vim.api.keyset.win_config
---@param path string
local function make_border(path, win_config)
	local config = CONFIG.boxes.preview
	local is_dir = path:sub(-1) == "/"
	local relpath = { dir = vim.fs.dirname(path), name = vim.fs.basename(path) }
	if is_dir then
		local parts = vim.split(path, "/")
		table.remove(parts, #parts)
		relpath.name = table.remove(parts, #parts) .. "/"
		relpath.dir = table.concat(parts, "/")
	end

	if relpath.dir ~= "" then
		relpath.dir = relpath.dir .. "/"
	end

	local parts = {
		dirname = { " " .. relpath.dir, false },
		basename = { relpath.name .. " ", true },
		rise = { (config.chars.rise):rep(win_config.height / 4), false },
		head = { config.chars.emphasis, false },
		tail = { config.chars.emphasis:rep(win_config.width / 2 - 2 - #path), false },
	}

	local sides = BOX.make(win_config.width, win_config.height, config, parts)

	return sides:to_hl({
		border_hl = "rabbit.types.preview",
		title_hl = "rabbit.types.title",
	})
end

---@param id integer
local function cache_config(id)
	if type(id) ~= "number" or math.floor(id) ~= id then
		error("Expected integer, got " .. type(id))
	end
	local w = TERM.win_config(id)
	if w == nil then
		error("Invalid window ID: " .. id)
	end

	local l = { ---@type vim.api.keyset.win_config
		row = w.row,
		col = w.col,
		width = 1,
		height = w.height,
		relative = "editor",
		zindex = 10,
		anchor = "NW",
		style = "minimal",
	}

	local r = vim.deepcopy(l)
	r.col = w.col + w.width - 1

	local t = vim.deepcopy(r)
	t.height = 1
	t.col = w.col + 1
	t.width = w.width - 2

	local b = vim.deepcopy(t)
	b.row = w.row + w.height - 1

	---@type Rabbit.Caching.Message.Preview.WinConfig
	local ret = setmetatable({ l = l, r = r, t = t, b = b, w = w, _ = {} }, {
		---@param path string
		__index = function(self, path)
			local p = self._[path]
			if p == nil then
				p = {
					border = make_border(path, self.w),
					timer = vim.uv.new_timer(),
				}
				self._[path] = p
			end
			p.timer:start(1000 * 600, 0, function()
				self._[path] = nil
				p.timer:close()
			end)
			return p.border
		end,
	})

	ret[0] = vim.loop.new_timer()

	return ret
end

---@type { [integer]: Rabbit.Caching.Message.Preview.WinConfig }
local real_cache = {}

-- Clear all cache if the window is resized
vim.api.nvim_create_autocmd("WinResized", {
	callback = function()
		for k, v in pairs(real_cache) do
			v[0]:stop()
			real_cache[k] = nil
		end
	end,
})

---@type { [integer]: Rabbit.Caching.Message.Preview.WinConfig }
local win_config_cache = setmetatable({}, {
	---@param id integer
	__index = function(_, id)
		local ret = real_cache[id]
		if ret == nil then
			ret = cache_config(id)
			real_cache[id] = ret
		end

		ret[0]:start(1000 * 600, 0, function()
			real_cache[id] = nil
			ret[0]:close()
		end)

		return ret
	end,
})

---@type { [string]: string[][] }
local binary_sz_cache = {}

---@param msg string Message to display
---@param width integer
---@param height integer
local function gen_msg_preview(msg, width, height)
	local hash = width * 37 + height

	if binary_sz_cache[msg] == nil then
		binary_sz_cache[msg] = {}
	elseif binary_sz_cache[msg][hash] ~= nil then
		return binary_sz_cache[msg][hash]
	end

	local h = math.floor(height / 3)
	local w = math.floor(width / 3)

	if h < 8 then
		h = height
	elseif h < 16 then
		h = math.floor(height / 2)
	end

	if w < 48 then
		w = width
	elseif w < 96 then
		w = math.floor(width / 2)
	end

	local grid = {}
	local lines = {}
	local diagonal = ("╱"):rep(w)
	local extra = ("╱"):rep(width - w * 3)
	for i = 1, h do
		grid[i] = diagonal
	end

	local msg_h = math.floor(h / 2)
	-- local st = "Binaries cannot be previewed"
	local fix = ("╱"):rep((w - #msg - 2) / 2)
	grid[msg_h - 1] = fix .. " " .. (" "):rep(#msg) .. " " .. fix
	grid[msg_h] = fix .. " " .. msg .. " " .. fix
	grid[msg_h + 1] = grid[msg_h - 1]

	for i = 1, h do
		local line = grid[i] .. grid[i] .. grid[i] .. extra

		lines[i + 0 * h] = line
		lines[i + 1 * h] = line
		lines[i + 2 * h] = line
	end

	for i = 3 * h, height do
		lines[i] = lines[1]
	end

	binary_sz_cache[msg][hash] = lines
	return lines
end

---@param data Rabbit.Message.Preview
---@return string | string[] "Error message (nil if no error)"
local function preview_test(data)
	local stat = MEM.stat(data.file)
	if stat == nil then
		return "No such file exists"
	end

	if stat.type == "directory" then
		return "Cannot preview a directory"
	end

	if stat.size == 0 then
		return "File is empty"
	end

	if stat.size > 1 * 1024 * 1024 then
		return "File too large to preview"
	end

	local file = io.open(data.file, "r")
	if file == nil then
		return "Could not read file"
	end

	local lines = {}
	for line in file:lines() do
		table.insert(lines, line)
	end

	return lines
end

---@param data Rabbit.Message.Preview
---@return boolean true if closed
local function possibly_closed(data)
	---@type string[] | string
	local lines = {}

	local function highlight_search()
		if data.jump == nil or data.jump.line == nil or data.jump.line < 1 or data.jump.line > #lines then
			return
		end

		data.jump.col = math.max(data.jump.col or 0, 0)
		data.jump.end_ = math.min(data.jump.end_ or 10000, #lines[data.jump.line])

		local ns = NVIM.ns["rabbit.preview.search"]
		vim.api.nvim_buf_clear_namespace(data.bufid, ns, 0, -1)
		pcall(vim.api.nvim_win_set_cursor, data.winid, { data.jump.line, data.jump.col })
		vim.api.nvim_buf_set_extmark(data.bufid, ns, data.jump.line - 1, data.jump.col, {
			end_col = data.jump.end_,
			hl_group = "CurSearch",
			priority = 110,
		})
		local others = vim.deepcopy(data.jump.others or {})
		while #others > 0 do
			local jump = table.remove(others, 1)
			for _, j in ipairs(jump.others or {}) do
				table.insert(others, j)
			end

			vim.api.nvim_buf_set_extmark(data.bufid, ns, jump.line - 1, jump.col, {
				end_col = jump.end_,
				hl_group = "Search",
				priority = 105,
			})
		end

		vim.api.nvim_buf_call(data.bufid, function()
			vim.cmd("normal! zz")
		end)
	end

	if vim.api.nvim_buf_is_valid(data.bufid) then
		lines = vim.api.nvim_buf_get_lines(data.bufid, 0, -1, false)
		highlight_search()
		return false
	end

	data.bufid = vim.api.nvim_create_buf(false, true)

	local timer, err = vim.uv.new_timer()
	assert(timer ~= nil, err)

	timer:start(0, 0, function()
		lines = preview_test(data)
		local is_err = false

		vim.schedule(function()
			if type(lines) == "string" then
				local config = TERM.win_config(data.winid)
				assert(config ~= nil, "Target window does not exist")
				lines = gen_msg_preview(lines, config.width, config.height)
				is_err = true
			end
			vim.api.nvim_buf_set_lines(data.bufid, 0, -1, false, lines)
			vim.bo[data.bufid].filetype = NVIM.ft[data.file] or "text"
			vim.bo[data.bufid].readonly = true

			if not is_err then
				highlight_search()
			end

			vim.api.nvim_create_autocmd("BufLeave", {
				buffer = data.bufid,
				callback = function()
					vim.api.nvim_win_set_buf(data.winid, UI._hov[data.winid])
					vim.api.nvim_buf_delete(data.bufid, { force = true })
				end,
			})
		end)
	end)
	return true
end

---@param data Rabbit.Message.Preview
return function(data)
	for _, v in pairs(UI._pre) do
		v:close()
	end

	if not vim.api.nvim_win_is_valid(data.winid) then
		-- Garbage collect
		win_config_cache[data.winid] = nil
		return
	end

	local was_closed = possibly_closed(data)

	local relpath
	local fallback_bufid = UI._hov[data.winid]
	if vim.api.nvim_buf_is_valid(data.bufid or -1) then
		if was_closed then
			relpath = MEM.rel_path(data.file)
		else
			relpath = MEM.rel_path(vim.api.nvim_buf_get_name(data.bufid))
		end
		vim.api.nvim_win_set_buf(data.winid, data.bufid)
	else
		if preview_ws ~= nil then
			preview_ws = preview_ws:close()
		end

		if vim.api.nvim_buf_is_valid(fallback_bufid) then
			vim.api.nvim_win_set_buf(data.winid, fallback_bufid)
		end
		return
	end

	if vim.api.nvim_buf_is_valid(fallback_bufid) then
		-- Keep Oil windows open
		if preview_ws ~= nil and vim.api.nvim_win_is_valid(preview_ws.win.id) then
			vim.api.nvim_win_set_buf(preview_ws.win.id, fallback_bufid)
		else
			local config = UI._bg.win.config
			local fakewin = vim.api.nvim_open_win(fallback_bufid, false, {
				width = config.width - 4,
				height = config.height - 4,
				relative = "editor",
				row = config.row + 2,
				col = config.col + 2,
				zindex = 1,
			})
			preview_ws = STACK.ws.from(data.bufid, fakewin, true)
			preview_ws.container = true
			UI._fg.children:add(preview_ws.id)
		end
	end

	local configs = win_config_cache[data.winid or 0]
	local hl = configs[relpath.merge]

	UI._pre.l = STACK.ws.scratch({
		focus = false,
		config = configs.l,
		parent = { UI._bg, UI._fg },
		---@diagnostic disable-next-line: missing-fields
		wo = { wrap = true },
		lines = hl.l,
		ns = "rabbit:preview",
	})

	UI._pre.r = STACK.ws.scratch({
		focus = false,
		config = configs.r,
		parent = { UI._pre.l, UI._fg },
		---@diagnostic disable-next-line: missing-fields
		wo = { wrap = true },
		lines = hl.r,
		ns = "rabbit:preview",
	})

	UI._pre.t = STACK.ws.scratch({
		focus = false,
		config = configs.t,
		parent = { UI._pre.r, UI._fg },
		---@diagnostic disable-next-line: missing-fields
		wo = { wrap = true },
		lines = hl.t,
		ns = "rabbit:preview",
	})

	UI._pre.b = STACK.ws.scratch({
		focus = false,
		config = configs.b,
		parent = { UI._pre.t, UI._pre.l, UI._fg }, -- Circle so they all close simultaneously
		---@diagnostic disable-next-line: missing-fields
		wo = { wrap = true },
		lines = hl.b,
		ns = "rabbit:preview",
	})
end
