local CTX = require("rabbit.term.ctx")
local UI = require("rabbit.term.listing")

---@param action string
---@return fun(...)
local function not_implemented(action)
	return function() error("Action '" .. action .. "' not implemented by plugin") end
end

---@class Rabbit.Plugin.Actions
local ACTIONS = {}

---@alias Rabbit.Action.Select fun(entry: Rabbit.Entry): Rabbit.Response
---@type Rabbit.Action.Select
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
				vim.bo.filetype = vim.filetype.match({ filename = entry.path })
			else
				vim.api.nvim_set_current_buf(entry.bufid)
			end
			return
		elseif entry.type == "collection" then
			return entry --[[@as Rabbit.Entry.Collection]]
		end
	end

	error("Action 'select' not implemented by plugin")
end

---@alias Rabbit.Action.Close fun(entry: Rabbit.Entry.Collection): nil
---@type Rabbit.Action.Close
function ACTIONS.close(_)
	UI.close()
	vim.api.nvim_set_current_win(CTX.user.win)
	vim.api.nvim_set_current_buf(CTX.user.buf)
end

---@alias Rabbit.Action.Hover fun(entry: Rabbit.Entry): Rabbit.Response
---@type Rabbit.Action.Hover
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

	error("Action 'hover' not implemented by plugin")
end

---@alias Rabbit.Action.Delete fun(entry: Rabbit.Entry): Rabbit.Response
---@type Rabbit.Action.Delete
ACTIONS.delete = not_implemented("delete")

---@alias Rabbit.Action.Children fun(entry: Rabbit.Entry.Collection): Rabbit.Entry[]
---@type Rabbit.Action.Children
ACTIONS.children = not_implemented("children")

---@alias Rabbit.Action.Rename fun(entry: Rabbit.Entry): Rabbit.Response
---@type Rabbit.Action.Rename
ACTIONS.rename = not_implemented("rename")

---@alias Rabbit.Action.Insert fun(entry: Rabbit.Entry): Rabbit.Response
---@type Rabbit.Action.Insert
ACTIONS.insert = not_implemented("insert")

---@alias Rabbit.Action.Parent fun(entry: Rabbit.Entry): Rabbit.Entry.Collection
---@type Rabbit.Action.Parent
ACTIONS.parent = not_implemented("parent")

---@alias Rabbit.Action.Collect fun(entry: Rabbit.Entry.Collection): Rabbit.Response
---@type Rabbit.Action.Collect
ACTIONS.collect = not_implemented("collect")

---@alias Rabbit.Action.Visual fun(entry: Rabbit.Entry): nil
---@type Rabbit.Action.Visual
ACTIONS.visual = function(_)
	vim.fn.feedkeys("V", "n")
end

return ACTIONS
