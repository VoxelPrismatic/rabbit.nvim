local UI = require("rabbit.term.listing")
local CTX = require("rabbit.term.ctx")
local BOX = require("rabbit.term.border")
local MEM = require("rabbit.util.mem")
local CONFIG = require("rabbit.config")

local preview_ws ---@type Rabbit.UI.Workspace | nil

---@class Rabbit.Caching.Message.Preview.WinConfig
---@field l vim.api.keyset.win_config Right config.
---@field r vim.api.keyset.win_config Left config.
---@field t vim.api.keyset.win_config Top config.
---@field b vim.api.keyset.win_config Bottom config.
---@field w vim.api.keyset.win_config Target window config.
---@field [0] uv.uv_timer_t Timer to clear cache after 10m
---@field [string] Rabbit.Term.Border.Generic<Rabbit.Term.HlLine[]> Borders for the window (per file).

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
	local w = CTX.win_config(id)
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

---@param width integer
---@param height integer
local function gen_binary_preview(width, height)
	local h = math.floor(height / 3)
	local w = math.floor(width / 3)
	local grid = {}
	local lines = {}
	local diagonal = ("╱"):rep(w)
	local extra = ("╱"):rep(width - w * 3)
	for i = 1, h do
		grid[i] = diagonal
	end

	local msg_h = math.floor(h / 2)
	local st = "Binaries cannot be previewed"
	local fix = ("╱"):rep((w - #st - 2) / 2)
	grid[msg_h - 1] = fix .. " " .. (" "):rep(#st) .. " " .. fix
	grid[msg_h] = fix .. " " .. st .. " " .. fix
	grid[msg_h + 1] = grid[msg_h - 1]

	for i = 1, h do
		lines[i] = grid[i] .. grid[i] .. grid[i] .. extra
		lines[i + 1 * h] = lines[i]
		lines[i + 2 * h] = lines[i]
	end

	for i = 3 * h, height do
		lines[i] = lines[1]
	end

	return lines
end

---@param data Rabbit.Message.Preview
local function possibly_closed(data)
	if not vim.api.nvim_buf_is_valid(data.bufid) and vim.uv.fs_stat(data.file or "") ~= nil then
		local bufid = vim.api.nvim_create_buf(false, true)
		data.bufid = bufid
		vim.api.nvim_create_autocmd("BufLeave", {
			buffer = bufid,
			callback = function()
				vim.api.nvim_buf_delete(bufid, { force = true })
			end,
		})
		local ok = pcall(vim.api.nvim_buf_set_lines, bufid, 0, -1, false, vim.fn.readfile(data.file))
		if not ok then
			local config = CTX.win_config(data.winid)
			if config == nil then
				data.bufid = nil
			else
				vim.api.nvim_buf_set_lines(bufid, 0, -1, false, gen_binary_preview(config.width, config.height))
			end
		else
		end
		vim.bo[bufid].filetype = vim.filetype.match({ filename = data.file }) or "text"
		vim.bo[bufid].readonly = true
	end
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

	possibly_closed(data)

	local relpath
	local fallback_bufid = UI._hov[data.winid]
	if vim.api.nvim_buf_is_valid(data.bufid or -1) then
		relpath = MEM.rel_path(vim.api.nvim_buf_get_name(data.bufid))
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
		if preview_ws ~= nil and vim.api.nvim_win_is_valid(preview_ws.win) then
			vim.api.nvim_win_set_buf(preview_ws.win, fallback_bufid)
		else
			local fakewin = vim.api.nvim_open_win(fallback_bufid, false, {
				width = UI._bg.conf.width,
				height = UI._bg.conf.height,
				relative = "editor",
				row = UI._bg.conf.row,
				col = UI._bg.conf.col,
				zindex = 1,
			})
			preview_ws = CTX.append(data.bufid, fakewin)
			preview_ws.container = true
		end
	end

	local configs = win_config_cache[data.winid or 0]
	local hl = configs[relpath.merge]

	UI._pre.l = CTX.scratch({
		focus = false,
		config = configs.l,
		parent = UI._bg,
		---@diagnostic disable-next-line: missing-fields
		wo = { wrap = true },
		lines = hl.l,
		ns = "rabbit:preview",
	})

	UI._pre.r = CTX.scratch({
		focus = false,
		config = configs.r,
		parent = UI._pre.l,
		---@diagnostic disable-next-line: missing-fields
		wo = { wrap = true },
		lines = hl.r,
		ns = "rabbit:preview",
	})

	UI._pre.t = CTX.scratch({
		focus = false,
		config = configs.t,
		parent = UI._pre.r,
		---@diagnostic disable-next-line: missing-fields
		wo = { wrap = true },
		lines = hl.t,
		ns = "rabbit:preview",
	})

	UI._pre.b = CTX.scratch({
		focus = false,
		config = configs.b,
		parent = { UI._pre.t, UI._pre.l }, -- Circle so they all close simultaneously
		---@diagnostic disable-next-line: missing-fields
		wo = { wrap = true },
		lines = hl.b,
		ns = "rabbit:preview",
	})
end
