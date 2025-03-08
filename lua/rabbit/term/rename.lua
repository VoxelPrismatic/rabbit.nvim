local CTX = require("rabbit.term.ctx")
local UIL = require("rabbit.term.listing")
local REN = {}

-- Allows you to rename an entry
-- Spawns a window above the current line so it's seamless
---@param entry Rabbit.Listing.Entry
---@param callback fun(new_name: string, entry: Rabbit.Listing.Entry)
function REN.rename(entry, callback)
	local linenr = vim.fn.line(".")
	local linetext = vim.api.nvim_buf_get_lines(0, linenr - 1, linenr, true)[1]
	local start = linetext:find(tostring(entry.label), 3) or 1
	local fin = start + #tostring(entry.label)
	local target = math.max(start, math.min(fin, vim.fn.col(".")))

	vim.api.nvim_win_set_cursor(0, { vim.fn.line("."), target - 1 })
	UIL._bufid = vim.api.nvim_create_buf(false, true)

	UIL._winid = vim.api.nvim_open_win(UIL._bufid, true, {
		relative = "win",
		row = linenr - 1,
		col = start - 1,
		height = 1,
		width = CTX.stack[#CTX.stack].conf.width - start - #tostring(entry.tail),
		style = "minimal",
		zindex = CTX.stack[#CTX.stack].conf.zindex + 1,
	})
	local ws = CTX.append(UIL._bufid, UIL._winid)

	vim.wo[UIL._winid].cursorline = true
	vim.api.nvim_buf_set_lines(UIL._bufid, 0, -1, false, { tostring(entry.label) })
	_ = pcall(vim.api.nvim_win_set_cursor, UIL._winid, { 1, target - start })
	vim.fn.feedkeys("i", "n")

	local function cb()
		local new_name = table.concat(vim.api.nvim_buf_get_lines(UIL._bufid, 0, -1, false), "")
		vim.cmd("stopinsert")
		callback(new_name, entry)
		CTX.close(ws)
	end

	vim.api.nvim_create_autocmd("InsertLeave", {
		buffer = UIL._bufid,
		callback = cb,
	})

	vim.api.nvim_create_autocmd("CursorMovedI", {
		buffer = UIL._bufid,
		callback = function()
			if vim.fn.line("$") > 1 then
				cb()
			end
		end,
	})
end

return REN
