--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

local SET = require("rabbit.util.set")
local KEYS = require("rabbit.term.stack.keybind")
local SHARED = require("rabbit.term.stack.shared")
local LINES = require("rabbit.term.stack.lines")
local AUTOCMD = require("rabbit.term.stack.autocmd")
local CURSOR = require("rabbit.term.stack.cursor")
local EXTMARKS = require("rabbit.term.stack.extmarks")
local NVIM = require("rabbit.util.nvim")
local TERM = require("rabbit.util.term")

---@alias Rabbit.AutoArray<T> T | T[]

---@class Rabbit.Stack.Workspace
local WS = {
	-- Workspace ID
	---@type integer
	id = 0,

	-- Highlight namespace ID
	---@type integer
	ns = 0,

	-- Child workspace IDs
	---@type Rabbit.Table.Set<integer>
	children = SET.new(),

	-- True if this is a container (will not delete buffer upon close)
	---@type boolean
	container = false,

	-- Keymap manager
	keys = KEYS,

	-- Line manager
	lines = LINES,

	-- Autocmd manager
	autocmd = AUTOCMD,

	-- Cursor manager
	cursor = CURSOR,

	-- Extmark manager
	extmarks = EXTMARKS,
}
-- Returns the current window configuration
---@return vim.api.keyset.win_config | nil "Nil if window doesn't exist"

-- Window stuff
---@class Rabbit.Stack.Workspace.Window
WS.win = {
	-- Window ID
	---@type integer
	id = 0,

	-- Window options
	---@type vim.wo
	o = vim.wo[0],

	-- Window configuration
	---@type Rabbit.Stack.WinConfig
	config = nil,

	-- Check if the window exists
	exists = function(self)
		return vim.api.nvim_win_is_valid(self.id)
	end,

	-- Get current buffer
	bufnr = function(self)
		return vim.api.nvim_win_get_buf(self.id)
	end,
}

-- Buffer stuff
---@class Rabbit.Stack.Workspace.Buffer: table
---@overload fun(): Rabbit.Stack.Workspace.Buffer Gets the new buffer if the old one doesn't exist
WS.buf = {
	-- Buffer ID
	---@type integer
	id = 0,

	-- Buffer options
	---@type vim.bo
	o = vim.bo[0],

	-- Check if the buffer exists
	exists = function(self)
		return vim.api.nvim_buf_is_valid(self.id)
	end,
}

-- Creates a workspace from a given buffer and window ID.
---@param bufid? integer Buffer ID.
---@param winid? integer Window ID.
---@param append? boolean Whether to append to the stack.
---@return Rabbit.Stack.Workspace
function WS.from(bufid, winid, append)
	bufid = bufid or vim.api.nvim_get_current_buf()
	winid = winid or vim.api.nvim_get_current_win()

	---@type Rabbit.Stack.Workspace
	local ws = setmetatable({
		id = winid * 37 + bufid,
		buf = {
			id = bufid,
			o = vim.bo[bufid],
			exists = WS.buf.exists,
		},
		win = {
			id = winid,
			o = vim.wo[winid],
			config = TERM.win_config(winid),
			exists = WS.win.exists,
			bufnr = WS.win.bufnr,
		},
		ns = 0,
		children = SET.new(),
		container = false,
	}, { __index = vim.deepcopy(WS) })

	ws.keys = KEYS.new(ws)
	ws.lines = LINES.new(ws)
	ws.autocmd = AUTOCMD.new(ws)
	ws.cursor = CURSOR.new(ws)
	ws.extmarks = EXTMARKS.new(ws)
	ws.buf = setmetatable(ws.buf --[[@as table]], {
		__call = function()
			if not ws.buf:exists() then
				ws.buf.id = ws.win:bufnr()
				ws.buf.o = vim.bo[ws.buf.id]
			end

			return ws.buf
		end,
	})

	if append then
		SHARED.spaces[ws.id] = ws
		SHARED.open:add(ws.id)
		ws.autocmd:add({ "BufDelete", "WinClosed", "QuitPre" }, function()
			ws:close()
		end)
	end

	return ws
end

---@class (exact) Rabbit.Stack.Kwargs.Scratch
---@field name? string Buffer name
---@field focus boolean Focus the window immediately after creation
---@field config vim.api.keyset.win_config Window configuration
---@field parent? Rabbit.AutoArray<Rabbit.Stack.Workspace | integer> Will close this one if the parent is closed
---@field ns? integer | string Highlight namespace
---@field wo? vim.wo Window options
---@field bo? vim.bo Buffer options
---@field autocmd? table<string, fun(evt: NvimEvent): nil | boolean> Buffer Autocmds
---@field lines? (Rabbit.Term.HlLine | string)[] Highlight line
---@field many? boolean If true, the lines field will be treated as many lines
---@field cursor? { [1]: integer, [2]: integer, [3]: boolean } Cursor position. If [3] is true, the real position will be used
---@field container? boolean Will not delete buffer upon close
---@field on_close? fun(self: Rabbit.Stack.Workspace) Called when the workspace is closed

-- Creates a scratch window and buffer, appending it to the stack
---@param opts Rabbit.Stack.Kwargs.Scratch
---@return Rabbit.Stack.Workspace
function WS.scratch(opts)
	assert(type(opts) == "table", "Expected table, got " .. type(opts))

	if opts.focus ~= false then
		SHARED.last_scratch = vim.uv.hrtime()
	end

	local bufid = vim.api.nvim_create_buf(false, true)
	local winid = vim.api.nvim_open_win(bufid, opts.focus ~= false, opts.config)

	local ws = WS.from(bufid, winid, true)
	ws.container = opts.container or false
	SHARED.spaces[ws.id] = ws
	SHARED.open:add(ws.id)

	ws:add_parents(opts.parent)

	if opts.name then
		vim.api.nvim_buf_set_name(bufid, opts.name)
	end

	local ns = opts.ns or 0
	if ns == 0 then
		ns = NVIM.ns[winid .. ":" .. bufid]
	else
		ns = NVIM.ns[ns]
	end

	ws.ns = ns

	if opts.lines then
		ws.lines:set(opts.lines, {
			ns = ws.ns,
			start = 0,
			end_ = -1,
			many = opts.many,
		})
	end

	for k, b in pairs(opts.wo or {}) do
		ws.win.o[k] = b
	end

	for k, b in pairs(opts.bo or {}) do
		ws.buf.o[k] = b
	end

	if opts.cursor then
		if opts.cursor[3] then
			TERM.realplace(opts.cursor[1], opts.cursor[2], winid)
		else
			vim.api.nvim_win_set_cursor(winid, { opts.cursor[1], opts.cursor[2] })
		end
	end

	for k, v in pairs(opts.autocmd or {}) do
		ws.autocmd:add(k, v)
	end

	ws.on_close = opts.on_close or ws.on_close

	return ws
end

function WS:close()
	if self.on_close then
		self:on_close()
	end
	SHARED.spaces[self.id] = nil
	SHARED.open:del(self.id)
	for _, parent in pairs(SHARED.spaces) do
		parent.children:del(self.id)
	end

	for i = #self.children, 1, -1 do
		local space = SHARED.spaces[table.remove(self.children, i)]
		if space ~= nil then
			space:close()
		end
	end

	_ = pcall(vim.api.nvim_win_close, self.win.id, true)
	if not self.container then
		_ = pcall(vim.api.nvim_buf_delete, self.buf.id, { force = true })
	end
end

-- Adds parents to the workspace
---@param ... Rabbit.AutoArray<Rabbit.Stack.Workspace | integer>
function WS:add_parents(...)
	local parents = { ... }
	while #parents > 0 do
		local id = table.remove(parents, 1) ---@type Rabbit.AutoArray<Rabbit.Stack.Workspace | integer>
		if type(id) == "number" then
			SHARED.spaces[id].children:add(self.id)
		elseif type(id) == "table" then
			for _, v in ipairs(id) do
				table.insert(parents, v)
			end
			if id.id ~= nil then
				assert(SHARED.spaces[id.id] ~= nil, "Parent workspace does not exist")
				SHARED.spaces[id.id].children:add(self.id)
			end
		end
	end
end

-- Focuses the window
---@param focus_buf? boolean Focus the buffer, too
---@return boolean Success
function WS:focus(focus_buf)
	SHARED.last_scratch = vim.uv.hrtime()
	local ok = pcall(vim.api.nvim_set_current_win, self.win.id or 0)
	if focus_buf then
		ok = ok and pcall(vim.api.nvim_set_current_buf, self.buf.id or 0)
	end

	return ok
end

-- On close callback
function WS:on_close() end

return WS
