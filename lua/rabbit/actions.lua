local CTX = require("rabbit.term.ctx")

---@type Rabbit.Plugin.Actions
local ACT = {}

function ACT.select(entry)
	if entry.class == "entry" then
		entry = entry --[[@as Rabbit.Entry]]
		if entry.type == "file" then
			entry = entry --[[@as Rabbit.Entry.File]]
			CTX.clear()
			if entry.target_winid ~= nil then
				vim.api.nvim_set_current_win(entry.target_winid)
			else
				vim.api.nvim_set_current_win(CTX.user.win)
			end

			if entry.closed then
				vim.cmd("e '" .. entry.path .. "'")
			else
				vim.api.nvim_set_current_buf(entry.bufid)
			end
			return
		elseif entry.type == "collection" then
			return entry
		end
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
