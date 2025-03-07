---@type Rabbit.Plugin.Actions
local ACT = {}
local UIL = require("rabbit.term.listing")
local LIST = require("rabbit.plugins.history.listing")

function ACT.select(_, entry, _)
	if entry.type == "action" then
		local old_action = LIST.action
		LIST.action = entry.ctx.new_win
		local entries = UIL.list(LIST.generate())

		if LIST.action == nil then
			for i, v in pairs(entries) do
				if v.ctx.new_win == old_action then
					vim.api.nvim_win_set_cursor(UIL._fg.win, { i, 0 })
					return
				end
			end
		elseif old_action == nil then
			_ = pcall(vim.api.nvim_win_set_cursor, UIL._fg.win, { 3, 0 })
		end

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
