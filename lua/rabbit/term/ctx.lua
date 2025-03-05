CTX = {
	user = { ns = 0 }, ---@type Rabbit.UI.Workspace
	stack = {}, ---@type Rabbit.UI.Workspace[]
}

-- Adds a workspace to the stack, and binds the WinClosed and BufDelete events
---@param bufnr integer
---@param winnr integer
---@return Rabbit.UI.Workspace
function CTX.append(bufnr, winnr)
	local ws = CTX.workspace(bufnr, winnr)
	table.insert(CTX.stack, ws)
	vim.api.nvim_create_autocmd({ "WinClosed", "BufDelete" }, {
		buffer = ws.buf,
		callback = function()
			_ = pcall(vim.api.nvim_buf_delete, ws.buf, { force = true })
			_ = pcall(vim.api.nvim_win_close, ws.win, true)
			for i, j in ipairs(CTX.stack) do
				if j == ws then
					table.remove(CTX.stack, i)
				end
			end
		end,
	})

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

return CTX
