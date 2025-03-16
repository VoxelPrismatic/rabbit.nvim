local SET = require("rabbit.util.set")

local CTX = {
	user = { ns = 0 }, ---@type Rabbit.UI.Workspace
	stack = {}, ---@type Rabbit.UI.Workspace[]
	used = {
		win = SET.new(),
		buf = SET.new(),
	},
}

-- Adds a parent workspace
---@param self Rabbit.UI.Workspace
---@param child Rabbit.UI.Workspace
local function add_child(self, child)
	table.insert(self.children, child)
	if #self.children == 1 then
		vim.api.nvim_create_autocmd({ "WinClosed", "BufDelete", "QuitPre" }, {
			buffer = self.buf,
			callback = function()
				while #self.children > 0 do
					table.remove(self.children, 1):close()
				end
			end,
		})
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
	if parent ~= nil then
		parent:add_child(ws)
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

-- Returns the current window configuration, including the width and height
---@param winid integer
---@return vim.api.keyset.win_config
function CTX.win_config(winid)
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
		local v = CTX.stack[1]
		_ = pcall(vim.api.nvim_win_close, v.win, true)
		_ = pcall(vim.api.nvim_buf_delete, v.buf, { force = true })
		_ = pcall(table.remove, CTX.stack, 1)
	end
end

-- Closes the current workspace
---@param ws Rabbit.UI.Workspace
function CTX.close(ws)
	_ = pcall(vim.api.nvim_win_close, ws.win, true)
	_ = pcall(vim.api.nvim_buf_delete, ws.buf, { force = true })
	for i = #CTX.stack, 1, -1 do
		if CTX.stack[i] == ws then
			_ = pcall(table.remove, CTX.stack, i)
		end
	end
end

return CTX
