CTX = {
	user = { ns = 0 }, ---@type Rabbit.UI.Workspace
	stack = {}, ---@type Rabbit.UI.Workspace[]
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
			CTX.close(ws.buf, ws.win)
		end,
	})

	if parent ~= nil then
		CTX.link(parent, ws)
	end

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
---@param bufnr integer
---@param winnr integer
function CTX.close(bufnr, winnr)
	_ = pcall(vim.api.nvim_win_close, winnr, true)
	_ = pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
	for i, j in ipairs(CTX.stack) do
		if j.buf == bufnr or j.win == winnr then
			_ = pcall(table.remove, CTX.stack, i)
			return
		end
	end
end

-- Sets the parent so when the parent closes, this one will too.
---@param parent Rabbit.UI.Workspace
---@param child Rabbit.UI.Workspace
function CTX.link(parent, child)
	vim.api.nvim_create_autocmd({ "WinClosed", "BufDelete" }, {
		buffer = parent.buf,
		callback = function()
			CTX.close(child.buf, child.win)
		end,
	})
end

return CTX
