local SET = require("rabbit.util.set")
local HL = require("rabbit.term.highlight")

---@class Rabbit.UI.Workspace.Keybind
---@field label string Description/legend label.
---@field keys Rabbit.Table.Set<string> Key sequence.
---@field mode string Keymap mode.
---@field space string Highlight name.
---@field shown boolean Whether or not to show this in the legend.
---@field legend fun(self: Rabbit.UI.Workspace.Keybind, align?: "left" | "right" | "center"): Rabbit.Term.HlLine[]

---@class Rabbit.UI.Workspace.Autocmd
---@field event string Autocmd event.
---@field kwargs vim.api.keyset.create_autocmd Kwargs passed to vim.api.nvim_create_autocmd
---@field id integer Autocmd ID
---@field target Rabbit.UI.Workspace
---@field del fun(self: Rabbit.UI.Workspace.Autocmd) Deletes the autocmd

---@class Rabbit.UI.Workspace
local workspace = {
	---@type integer
	-- Window ID.
	win = 0,

	---@type integer
	-- Buffer ID.
	buf = 0,

	---@type integer
	-- Highlight namespace ID.
	ns = 0,

	---@type Rabbit.UI.Workspace[]
	-- Child workspaces.
	children = {},

	---@type vim.api.keyset.win_config?
	-- Window configuration.
	conf = {},

	---@type vim.fn.winsaveview.ret?
	-- Window viewport details.
	---@diagnostic disable-next-line: missing-fields
	view = {},

	---@type boolean
	-- True if this workspace is a container (will not delete buffer upon close)
	container = false,

	---@type Rabbit.UI.Workspace.Keybind[]
	-- Keys mapped to this workspace.
	keys = {},

	---@type { [string]: Rabbit.UI.Workspace.Autocmd[] }
	-- Autocmds mapped to this workspace.
	autocmds = {},
}

local CTX = {
	---@diagnostic disable-next-line: missing-fields
	user = { ns = 0 }, ---@type Rabbit.UI.Workspace
	stack = {}, ---@type Rabbit.UI.Workspace[]
	used = {
		win = SET.new(),
		buf = SET.new(),
	},
	scratch_time = 0,
}

-- Adds a child to this workspace. If this workspace closes, all children will be closed too.
---@param self Rabbit.UI.Workspace
---@param ... Rabbit.UI.Workspace
function workspace.add_child(self, ...)
	if #self.children == 0 then
		vim.api.nvim_create_autocmd({ "WinClosed", "BufDelete", "QuitPre" }, {
			buffer = self.buf,
			callback = function()
				self:close()
				while #self.children > 0 do
					table.remove(self.children, 1):close()
				end
			end,
		})
	end
	for _, child in ipairs({ ... }) do
		table.insert(self.children, child)
	end
end

---@class Rabbit.UI.Workspace.BindKwargs
---@field mode? "n" | string | string[] Keymap mode
---@field shown? true | boolean Whether or not to show this in the legend
---@field key string | string[] Keys to bind
---@field label string Description/legend label
---@field callback? function Callback
---@field space? string Namespace when building the legend
---@field align? "left" | "right" | "center" Alignment when returning this legend

---@param self Rabbit.UI.Workspace.Keybind
---@param align? "left" | "right" | "center" Alignment
local function keybind_build(self, align)
	local ret = {
		{
			text = self.label,
			hl = { "rabbit.legend.action", self.space },
			align = align,
		},
		{
			text = ":",
			hl = "rabbit.legend.separator",
			align = align,
		},
		{
			text = self.keys[1],
			hl = "rabbit.legend.key",
			align = align,
		},
	}

	table.insert(ret, align == "right" and #ret + 1 or 1, { text = " ", align = align })
	return ret
end

-- Binds a keymap to this workspace and returns a legend entry
---@param self Rabbit.UI.Workspace
---@param kwargs Rabbit.UI.Workspace.BindKwargs
---@return Rabbit.Term.HlLine[] "Legend entry"
function workspace.bind(self, kwargs)
	local mode = kwargs.mode or "n"
	local label = kwargs.label
	local key = kwargs.key
	local callback = kwargs.callback
	local shown = kwargs.shown == nil and true or kwargs.shown
	local space = kwargs.space or "rabbit.types.plugin"

	if type(key) == "string" then
		key = { key }
	end

	if type(mode) == "string" then
		mode = { mode }
	end
	mode = SET.new(mode)

	for i = #self.keys, 1, -1 do
		local bound = self.keys[i]
		if bound.label == label and mode:idx(bound.mode) ~= nil then
			table.remove(self.keys, i)
			for _, k in ipairs(bound.keys) do
				_ = pcall(vim.keymap.del, bound.mode, k, { buffer = self.buf })
			end
		end
	end

	if #key == 0 then
		return {}
	end

	assert(callback ~= nil, "Callback can only be nil if there are no keys")
	for _, m in ipairs(mode) do
		for _, k in ipairs(key) do
			-- Unbind duplicate keymaps
			for i = #self.keys, 1, -1 do
				local v = self.keys[i]
				if v.mode == m then
					if v.keys:idx(k) ~= nil then
						v.keys:del(k)
					end
					if #v.keys == 0 then
						table.remove(self.keys, i)
					end
				end
			end

			vim.keymap.set(m, k, callback, { buffer = self.buf, desc = label })
		end

		table.insert(self.keys, {
			label = label,
			keys = SET.new(key),
			mode = m,
			shown = shown,
			space = space,
			legend = keybind_build,
		})
	end

	return self.keys[#self.keys]:legend(kwargs.align)
end

-- Returns true if a label is bound to a keymap
---@param self Rabbit.UI.Workspace
---@param label string
---@return boolean
function workspace.bound(self, label)
	for _, key in ipairs(self.keys) do
		if key.label == label then
			return true
		end
	end
	return false
end

-- Unbinds a keymap from this workspace
---@param self Rabbit.UI.Workspace
---@param labels string | string[] Description/legend label
function workspace.unbind(self, labels)
	if type(labels) == "string" then
		labels = { labels }
	end
	for _, label in ipairs(labels) do
		self:bind({
			mode = { "n", "i", "v", "x" },
			label = label,
			callback = nil,
			key = {},
		})
	end
end

---@class Rabbit.UI.Workspace.ExtKwargs
---@field ns? integer | string Highlight namespace
---@field line integer Start line number
---@field col integer Start column number
---@field opts vim.api.keyset.set_extmark

-- Shorthand for vim.api.nvim_buf_set_extmark
---@param self Rabbit.UI.Workspace
---@param kwargs Rabbit.UI.Workspace.ExtKwargs
function workspace.set_extmark(self, kwargs)
	local ns = kwargs.ns or self.ns
	if type(ns) == "string" then
		ns = vim.api.nvim_create_namespace(ns)
	end

	return vim.api.nvim_buf_set_extmark(self.buf, ns, kwargs.line, kwargs.col, kwargs.opts)
end

---@param self Rabbit.UI.Workspace
---@param ns? integer | string Highlight namespace
function workspace.clear_extmarks(self, ns)
	if ns == nil then
		ns = self.ns
	elseif type(ns) == "string" then
		ns = vim.api.nvim_create_namespace(ns)
	end
	vim.api.nvim_buf_clear_namespace(self.buf, ns, 0, -1)
end

-- Created a legend map for this workspace
---@param self Rabbit.UI.Workspace
---@param space? string Legend namespace
---@param align? "left" | "right" | "center" Legend alignment
---@return Rabbit.Term.HlLine[]
function workspace.legend(self, space, align)
	table.sort(self.keys, function(a, b)
		return a.label < b.label
	end)

	local actions = {}

	local mode = vim.fn.mode():lower()
	for _, key in ipairs(self.keys) do
		if key.shown and key.mode == mode then
			if space == nil or space == key.space then
				table.insert(actions, key:legend(align))
			end
		end
	end

	return actions
end

-- Sets the lines in the buffer
---@param self Rabbit.UI.Workspace
---@param lines (Rabbit.Term.HlLine | string)[]
---@param opts? { many: boolean, start: number, strict: boolean }
function workspace.set_lines(self, lines, opts)
	if opts == nil then
		opts = { strict = false, start = 0, many = true }
	end

	HL.set_lines({
		bufnr = self.buf,
		lineno = opts.start,
		lines = lines,
		ns = self.ns,
		strict = opts.strict,
		many = opts.many,
		width = self.conf.width,
	})
end

-- Returns the lines in the buffer
---@param self Rabbit.UI.Workspace
---@param start? integer
---@param end_? integer
---@param strict? boolean
function workspace.get_lines(self, start, end_, strict)
	return vim.api.nvim_buf_get_lines(self.buf, start or 0, end_ or -1, strict or false)
end

-- Sets the cursor position
---@param self Rabbit.UI.Workspace
---@param line integer
---@param col integer
function workspace.move_cur(self, line, col)
	vim.api.nvim_win_set_cursor(self.win, { line, col })
end

-- Gets the cursor position
---@param self Rabbit.UI.Workspace
function workspace.get_cur(self)
	return vim.api.nvim_win_get_cursor(self.win)
end

-- Focuses the window
---@param self Rabbit.UI.Workspace
---@return Rabbit.UI.Workspace "Itself for chaining"
function workspace.focus(self)
	vim.api.nvim_set_current_win(self.win)
	return self
end

---@param self Rabbit.UI.Workspace.Autocmd
local function autocmd_del(self)
	vim.api.nvim_del_autocmd(self.id)
	local arr = self.target.autocmds[self.event]
	for i = #arr, 1, -1 do
		if arr[i] == self then
			table.remove(arr, i)
			return
		end
	end
	error("Unreachable: Autocmd must be found")
end

-- Adds an autocmd listener
---@param self Rabbit.UI.Workspace
---@param event string Event name
---@param kwargs vim.api.keyset.create_autocmd | fun(evt: NvimEvent) Kwargs
---@return Rabbit.UI.Workspace.Autocmd
---@overload fun(self: Rabbit.UI.Workspace, events: table<string, vim.api.keyset.create_autocmd | fun(evt: NvimEvent)>): table<string, Rabbit.UI.Workspace.Autocmd>
function workspace.listen(self, event, kwargs)
	if type(event) == "table" then
		local ret = {}
		for k, v in pairs(event) do
			ret[k] = self:listen(k, v)
		end
		return ret
	end

	if self.autocmds[event] == nil then
		self.autocmds[event] = {}
	end

	if type(kwargs) == "function" then
		kwargs = {
			callback = kwargs,
			buffer = self.buf,
			desc = "Rabbit Autocmd",
		}
	elseif kwargs.buffer == nil and kwargs.pattern == nil then
		kwargs.buffer = self.buf
	end

	---@type Rabbit.UI.Workspace.Autocmd
	local ret = {
		event = event,
		kwargs = kwargs,
		del = autocmd_del,
		target = self,
		id = 0,
	}

	if kwargs.callback ~= nil then
		local cb = kwargs.callback or function() end
		kwargs.callback = function(evt)
			local v = cb(evt)
			if v == false or kwargs.once then
				ret:del()
			end
		end
	end

	ret.id = vim.api.nvim_create_autocmd(event, kwargs)

	table.insert(self.autocmds[event], ret)
	return ret
end

-- Removes all autocmd listeners of a certain type
-- @param self Rabbit.UI.Workspace
---@param ... string
function workspace.unlisten(self, ...)
	local varargs = { ... }
	if #varargs == 0 then
		for k, _ in pairs(self.autocmds) do
			self:unlisten(k)
		end
		return
	end

	for _, event in ipairs(varargs) do
		for _, v in ipairs(self.autocmds[event] or {}) do
			v:del()
		end
	end
end

-- Adds a workspace to the stack, and binds the WinClosed and BufDelete events
---@param bufid integer
---@param winid integer
---@param parent? Rabbit.UI.Workspace Will close this one if the parent is closed
---@return Rabbit.UI.Workspace
function CTX.append(bufid, winid, parent)
	local ws = CTX.workspace(bufid, winid)
	table.insert(CTX.stack, ws)

	local parents = { parent }
	while #parents > 0 do
		local p = table.remove(parents, 1)
		for _, v in ipairs(p) do
			table.insert(parents, v)
		end
		if p.add_child ~= nil then
			p:add_child(ws)
		end
	end

	return ws
end

-- Creates a workspace object
---@param bufid? integer
---@param winid? integer
---@return Rabbit.UI.Workspace
function CTX.workspace(bufid, winid)
	local ws = { ---@type Rabbit.UI.Workspace
		buf = bufid or vim.api.nvim_get_current_buf(),
		win = winid or vim.api.nvim_get_current_win(),
		ns = 0,
		view = vim.fn.winsaveview(),
		children = {},
		keys = {},
		container = false,
		close = CTX.close,
		autocmds = {},
		add_child = workspace.add_child,
		set_lines = workspace.set_lines,
		get_lines = workspace.get_lines,
		move_cur = workspace.move_cur,
		get_cur = workspace.get_cur,
		focus = workspace.focus,
		bind = workspace.bind,
		legend = workspace.legend,
		unbind = workspace.unbind,
		listen = workspace.listen,
		unlisten = workspace.unlisten,
		bound = workspace.bound,
		set_extmark = workspace.set_extmark,
		clear_extmarks = workspace.clear_extmarks,
	}
	ws.conf = CTX.win_config(ws.win)

	CTX.used.buf:add(bufid)
	CTX.used.win:add(winid)

	return ws
end

-- Returns the current window configuration, including the width and height.
-- Nil if window doesn't exist.
---@param winid integer
---@return vim.api.keyset.win_config | nil
function CTX.win_config(winid)
	if vim.api.nvim_win_is_valid(winid) == false then
		return nil
	end
	local conf = vim.api.nvim_win_get_config(winid)
	conf.width = conf.width or vim.api.nvim_win_get_width(winid)
	conf.height = conf.height or vim.api.nvim_win_get_height(winid)
	if conf.row == nil or conf.col == nil then
		conf.row, conf.col = unpack(vim.api.nvim_win_get_position(winid))
	end
	return conf
end

-- Clears the stack; closes all windows and buffers
function CTX.clear()
	while #CTX.stack > 0 do
		local ws = CTX.stack[1]
		_ = pcall(vim.api.nvim_win_close, ws.win, true)
		if not ws.container then
			_ = pcall(vim.api.nvim_buf_delete, ws.buf, { force = true })
		end
		_ = pcall(table.remove, CTX.stack, 1)
	end
end

-- Closes the current workspace
---@param ws Rabbit.UI.Workspace
---@return nil
function CTX.close(ws)
	_ = pcall(vim.api.nvim_win_close, ws.win, true)
	if not ws.container then
		_ = pcall(vim.api.nvim_buf_delete, ws.buf, { force = true })
	end
	for i = #CTX.stack, 1, -1 do
		if CTX.stack[i] == ws then
			_ = pcall(table.remove, CTX.stack, i)
		end
	end
end

workspace.close = CTX.close

-- Creates a scratch buffer and window and appends it to the stack
---@param opts Rabbit.Term.ScratchKwargs
---@return Rabbit.UI.Workspace
function CTX.scratch(opts)
	if opts.focus then
		CTX.scratch_time = vim.uv.hrtime()
	end
	if type(opts) ~= "table" then
		error("Expected table, got " .. type(opts))
	end

	if opts.focus == nil then
		opts.focus = true
	end

	local bufid = vim.api.nvim_create_buf(false, true)
	local winid = vim.api.nvim_open_win(bufid, opts.focus, opts.config)

	local ws = CTX.append(bufid, winid, opts.parent)

	if opts.name then
		vim.api.nvim_buf_set_name(bufid, opts.name)
	end

	ws.ns = vim.api.nvim_create_namespace(opts.ns or tostring(winid .. ":" .. bufid))

	for k, v in pairs(opts.wo or {}) do
		vim.wo[winid][k] = v
	end

	for k, v in pairs(opts.bo or {}) do
		vim.bo[bufid][k] = v
	end

	for k, v in pairs(opts.autocmd or {}) do
		ws:listen(k, { buffer = bufid, callback = v })
	end

	if opts.lines then
		require("rabbit.term.highlight").set_lines({
			bufnr = bufid,
			lines = opts.lines,
			width = ws.conf.width,
			ns = ws.ns,
			lineno = 0,
			strict = false,
			many = opts.many,
		})
	end

	if opts.cursor then
		vim.api.nvim_win_set_cursor(winid, opts.cursor)
	end

	return ws
end

---@class (exact) Rabbit.Term.ScratchKwargs
---@field name? string Buffer name
---@field focus boolean Focus the window immediately after creation
---@field config vim.api.keyset.win_config Window configuration
---@field parent? Rabbit.UI.Workspace | Rabbit.UI.Workspace[] Will close this one if the parent is closed
---@field ns? string Highlight namespace
---@field wo? vim.wo Window options
---@field bo? vim.bo Buffer options
---@field autocmd? table<string, fun(evt: NvimEvent): nil | boolean> Buffer Autocmds
---@field lines? (Rabbit.Term.HlLine | string)[] Highlight line
---@field many? boolean If true, the lines field will be treated as many lines
---@field cursor? integer[] Cursor position

return CTX
