local UI = require("rabbit.term.listing")
local TERM = require("rabbit.util.term")
local STACK = require("rabbit.term.stack")

---@param action string
---@return fun(...)
local function not_implemented(action)
	return function()
		error("Action '" .. action .. "' not implemented by plugin")
	end
end

---@class Rabbit.Plugin.Actions
local ACTIONS = {}

---@alias Rabbit.Action.Select fun(entry: Rabbit.Entry): Rabbit.Response
---@type Rabbit.Action.Select
function ACTIONS.select(entry)
	assert(entry.class == "entry", "[Rabbit]: Expected entry, got " .. entry.class)

	entry = entry --[[@as Rabbit.Entry]]
	if entry.type == "collection" or entry.type == "search" then
		return entry --[[@as Rabbit.Entry.Collection]]
	end

	assert(entry.type == "file", "[Rabbit]: Unsupported entry type: " .. entry.type)

	entry = entry --[[@as Rabbit.Entry.File]]
	UI.close()
	if entry.target_winid ~= nil then
		vim.api.nvim_set_current_win(entry.target_winid)
	else
		STACK._.user:focus()
	end

	if entry.closed then
		vim.cmd("e " .. entry.path)
		vim.bo.filetype = vim.filetype.match({ filename = entry.path })
	else
		vim.api.nvim_set_current_buf(entry.bufid)
	end

	if entry.jump then
		vim.api.nvim_win_set_cursor(0, { entry.jump.line, entry.jump.col or 0 })
		vim.api.nvim_win_call(0, function()
			vim.cmd("normal! zz")
		end)
	end

	return false
end

---@alias Rabbit.Action.Close fun(entry: Rabbit.Entry.Collection): nil
---@type Rabbit.Action.Close
function ACTIONS.close(_)
	UI.close()
	STACK._.user:focus(true)
end

---@alias Rabbit.Action.Hover fun(entry: Rabbit.Entry): Rabbit.Response
---@type Rabbit.Action.Hover
function ACTIONS.hover(entry)
	assert(
		entry.class == "entry" and entry.type == "file",
		"[Rabbit]: Expected entry.file, got " .. entry.class .. "." .. entry.type
	)

	entry = entry --[[@as Rabbit.Entry.File]]
	return { ---@type Rabbit.Message.Preview
		class = "message",
		type = "preview",
		file = entry.path,
		bufid = entry.bufid,
		winid = entry.target_winid,
	}
end

---@alias Rabbit.Action.Delete fun(entry: Rabbit.Entry): Rabbit.Response
---@type Rabbit.Action.Delete
ACTIONS.delete = not_implemented("delete")

---@alias Rabbit.Action.Children fun(entry: Rabbit.Entry.Collection | Rabbit.Entry.Search): Rabbit.Entry[]
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

---@alias Rabbit.Action.Visual fun(entry: Rabbit.Entry): Rabbit.Response
---@type Rabbit.Action.Visual
ACTIONS.visual = function(_)
	UI._fg.buf.o.modifiable = true

	TERM.feed("V<Left>" .. (vim.fn.col(".") == 1 and "" or "<Right>"))

	UI._fg.autocmd:add("ModeChanged", {
		buffer = UI._fg.buf.id,
		callback = function(evt)
			if evt.match:sub(3) ~= "n" then
				return true
			end

			UI._fg.buf.o.modifiable = false
			return false
		end,
		desc = "Disable changes once user exits visual mode",
	})
	return {
		class = "message",
	}
end

---@alias Rabbit.Action.Yank fun(entry: Rabbit.Entry): Rabbit.Response
---@type Rabbit.Action.Yank
ACTIONS.yank = not_implemented("yank")

---@alias Rabbit.Action.Cut fun(entry: Rabbit.Entry): Rabbit.Response
---@type Rabbit.Action.Cut
ACTIONS.cut = not_implemented("cut")

---@alias Rabbit.Action.Paste fun(entry: Rabbit.Entry): Rabbit.Response
---@type Rabbit.Action.Paste
ACTIONS.paste = not_implemented("paste")

return ACTIONS
