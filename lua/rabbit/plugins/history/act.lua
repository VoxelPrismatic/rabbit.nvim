---@type Rabbit.Plugin.Actions
local ACT = {}
local SET = require("rabbit.util.set")
local UIL = require("rabbit.term.listing")
local LIST = require("rabbit.plugins.history.listing")

function ACT.select(_, entry, _)
	if entry.type == "file" then
		UIL.close()
		vim.api.nvim_set_current_win(entry.ctx.winnr)

		if entry.ctx.valid then
			vim.api.nvim_set_current_buf(entry.ctx.bufnr)
		else
			vim.cmd("e " .. entry.ctx.file)
		end

		return
	end

	if entry.ctx.copy then
		LIST.win[entry.ctx.winnr] = vim.deepcopy(LIST.win[LIST.winnr])
		LIST.win[entry.ctx.winnr].killed = false
		if tostring(LIST.win[entry.ctx.winnr].name) == tostring(LIST.winnr) then
			LIST.win[entry.ctx.winnr].name = tostring(entry.ctx.winnr)
		end
		table.remove(LIST.win, LIST.winnr)
		SET.sub(LIST.order, LIST.winnr)
		SET.add(LIST.order, entry.ctx.winnr)
		LIST.winnr = entry.ctx.winnr
	end

	local old_win = LIST.winnr
	LIST.winnr = entry.ctx.winnr

	local entries = UIL.list(LIST.generate())

	if LIST.winnr == nil and old_win ~= nil then
		for i, item in ipairs(entries) do
			if item.ctx.winnr == old_win then
				vim.api.nvim_win_set_cursor(UIL._fg.win, { i, 0 })
				break
			end
		end
	else
		_ = pcall(vim.api.nvim_win_set_cursor, UIL._fg.win, { LIST.win[LIST.winnr].killed and 2 or 3, 0 })
	end
end

function ACT.delete(_, entry, _)
	if entry.type == "file" then
		SET.sub(LIST.winnr == nil and LIST.global or LIST.win[LIST.winnr].history, entry.ctx.bufnr)
	else
		SET.sub(LIST.order, entry.ctx.winnr)
		table.remove(LIST.win, entry.ctx.winnr)
	end

	UIL.list(LIST.generate())
end

function ACT.parent(_, _, _)
	LIST.winnr = nil
	UIL.list(LIST.generate())
end

function ACT.rename(idx, entry, entries)
	require("rabbit.term.rename").rename(entry, function(new_name, e)
		LIST.win[e.ctx.winnr].name = new_name
		UIL.list(LIST.generate())
	end)
end

return ACT
