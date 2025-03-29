local SET = require("rabbit.util.set")

local CTX = {
	user = { ns = 0 }, ---@type Rabbit.UI.Workspace
	stack = {}, ---@type Rabbit.UI.Workspace[]
	used = {
		win = SET.new(),
		buf = SET.new(),
	},
	scratch_time = 0,
}

-- Adds a parent workspace
---@param self Rabbit.UI.Workspace
---@param child Rabbit.UI.Workspace
---@return Rabbit.UI.Workspace
local function add_child(self, child)
	table.insert(self.children, child)
	if #self.children == 1 then
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

	return child
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
		view = vim.fn.winsaveview(),
		children = {},
	}
	ws.conf = CTX.win_config(ws.win)
	ws.add_child = add_child
	ws.close = CTX.close

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
		vim.api.nvim_create_autocmd(k, { buffer = bufid, callback = v })
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
---@field autocmd? table<string, fun()> Buffer Autocmds
---@field lines? Rabbit.Term.HlLine[] Highlight line
---@field many? boolean If true, the lines field will be treated as many lines
---@field cursor? integer[] Cursor position

return CTX
