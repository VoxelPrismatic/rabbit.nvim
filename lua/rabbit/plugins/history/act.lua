---@type Rabbit.Plugin.Actions
local ACT = {}
local UIL = require("rabbit.term.listing")
local LIST = require("rabbit.plugins.history.listing")

function ACT.select(_, entry, _)
	if entry.type == "action" then
		LIST.action = entry.ctx.new_win
		UIL.list(LIST.generate())
		return
	end

	UIL.close()
	vim.api.nvim_set_current_win(entry.ctx.winnr)
	local target = entry.ctx.bufnr
	if type(target) == "string" then
		vim.cmd("e " .. target)
	else
		vim.cmd("b " .. target)
	end
end

function ACT.delete(idx, entry, listing) end

return ACT
