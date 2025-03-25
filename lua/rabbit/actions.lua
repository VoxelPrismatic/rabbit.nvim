local CTX = require("rabbit.term.ctx")
local UI = require("rabbit.term.listing")

---@type Rabbit.Plugin.Actions
---@diagnostic disable-next-line: missing-fields
local ACTIONS = {}

function ACTIONS.select(entry)
	if entry.class == "entry" then
		entry = entry --[[@as Rabbit.Entry]]
		if entry.type == "file" then
			entry = entry --[[@as Rabbit.Entry.File]]
			UI.close()
			if entry.target_winid ~= nil then
				vim.api.nvim_set_current_win(entry.target_winid)
			else
				vim.api.nvim_set_current_win(CTX.user.win)
			end

			if entry.closed then
				vim.cmd("e " .. entry.path)
			else
				vim.api.nvim_set_current_buf(entry.bufid)
			end
			return
		elseif entry.type == "collection" then
			return entry --[[@as Rabbit.Entry.Collection]]
		end
	end

	error("Action not implemented by plugin")
end

function ACTIONS.close(_)
	UI.close()
	vim.api.nvim_set_current_win(CTX.user.win)
	vim.api.nvim_set_current_buf(CTX.user.buf)
end

function ACTIONS.hover(entry)
	if entry.class == "entry" then
		if entry.type == "file" then
			entry = entry --[[@as Rabbit.Entry.File]]
			return { ---@type Rabbit.Message.Preview
				class = "message",
				type = "preview",
				file = entry.path,
				bufid = entry.bufid,
				winid = entry.target_winid,
			}
		end
	end

	error("Action not implemented by plugin")
end

return ACTIONS
