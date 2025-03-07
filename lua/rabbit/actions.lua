---@type Rabbit.Plugin.Actions
local ACT = {}

function ACT.select(_, entry, _)
	if entry.type == "file" then
		require("rabbit.term.ctx").clear()
		vim.cmd("e '" .. entry.label .. "'")
	end

	error("Action not implemented by plugin")
end

function ACT.close(_, _, _)
	local CTX = require("rabbit.term.ctx")
	CTX.clear()
	vim.api.nvim_set_current_win(CTX.user.win)
	vim.api.nvim_set_current_buf(CTX.user.buf)
end

function ACT.delete(idx, _, entries)
	local UIL = require("rabbit.term.listing")
	table.remove(entries, idx)
	UIL._plugin.list()
end

return ACT
