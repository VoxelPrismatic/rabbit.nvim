local SET = require("rabbit.util.set")

local CTX = {
	user = { ns = 0 }, ---@type Rabbit.UI.Workspace
	stack = {}, ---@type Rabbit.UI.Workspace[]
	used = {
		win = {},
		buf = {},
	},
}

-- Adds a workspace to the stack, and binds the WinClosed and BufDelete events
---@param bufnr integer
---@param winnr integer
---@param parent? Rabbit.UI.Workspace Will close this one if the parent is closed
---@return Rabbit.UI.Workspace
function CTX.append(bufnr, winnr, parent)
	local ws = CTX.workspace(bufnr, winnr)
	table.insert(CTX.stack, ws)
	vim.api.nvim_create_autocmd({ "WinClosed", "BufDelete" }, {
		buffer = ws.buf,
		callback = function()
			CTX.close(ws)
			if ws.parent ~= nil then
				CTX.close(ws.parent)
			end
		end,
	})

	ws.parent = parent

	return ws
end

-- Creates a workspace object
---@param bufnr? integer
---@param winnr? integer
---@return Rabbit.UI.Workspace
function CTX.workspace(bufnr, winnr)
	local ws = { ---@type Rabbit.UI.Workspace
		buf = bufnr or vim.api.nvim_get_current_buf(),
		win = winnr or vim.api.nvim_get_current_win(),
		view = vim.fn.winsaveview(),
	}

	ws.conf = vim.api.nvim_win_get_config(ws.win)
	ws.conf.width = ws.conf.width or vim.api.nvim_win_get_width(ws.win)
	ws.conf.height = ws.conf.height or vim.api.nvim_win_get_height(ws.win)

	SET.add(CTX.used.buf, bufnr)
	SET.add(CTX.used.win, winnr)

	return ws
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
	for i, j in ipairs(CTX.stack) do
		if j == ws then
			_ = pcall(table.remove, CTX.stack, i)
			return
		end
	end
end

return CTX
