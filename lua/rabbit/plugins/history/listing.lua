local SET = require("rabbit.util.set")
local UIL = require("rabbit.term.listing")

---@class Rabbit._.History.Listing
local LIST = {
	---@type table<integer, Rabbit._.History.Window>
	win = {},

	-- How windows are ordered in the list
	---@type integer[]
	order = {},

	-- Current window in listing
	---@type integer | nil
	action = nil,
}

-- Initializes a window entry if one doesn't exist yet
---@param winnr integer
function LIST.init(winnr)
	if LIST.win[winnr] == nil then
		LIST.win[winnr] = { ---@type Rabbit._.History.Window
			killed = false,
			name = "" .. winnr,
			history = {},
			closed = {},
		}
	else
		LIST.win[winnr].killed = false
	end

	return LIST.win[winnr]
end

---@class Rabbit._.History.Window
---@field killed boolean Whether or not the window was closed
---@field name string Custom name for the window
---@field history integer[] List of buffers in the window
---@field closed string[] List of buffers that have been closed

-- Creates a listing
---@return Rabbit.Listing.Entry[]
function LIST.generate()
	local ls = {}

	if LIST.action == nil then
		for _, v in ipairs(LIST.order) do
			local w = LIST.win[v]

			---@type Rabbit.Listing.Entry
			local e = {
				type = "action",
				label = w.name,
				color = w.killed and "rose" or "iris",
				tail = "" .. v,
				head = "",
				actions = {
					delete = not w.killed,
					parent = false,
				},
			}

			table.insert(ls, e)
		end
	else
		local win
		local files
		table.insert(ls, {
			type = "action",
			label = "All Windows",
			color = "iris",
			actions = {
				delete = false,
			},
		})
		if LIST.action < 0 then
			win = LIST.win[-LIST.action]
			files = win.closed
			table.insert(ls, {
				type = "action",
				label = "Opened buffers",
				color = "iris",
				actions = {
					delete = false,
				},
			})
		else
			win = LIST.win[LIST.action]
			files = win.history
			table.insert(ls, {
				type = "action",
				label = "Closed buffers",
				color = "love",
				actions = {
					delete = false,
				},
			})
		end

		for i, filename in ipairs(files) do
			if type(filename) == "number" then
				if not vim.api.nvim_buf_is_valid(filename) then
					table.remove(files, i)
					goto continue
				end

				filename = vim.api.nvim_buf_get_name(filename)
			end

			table.insert(ls, {
				type = "file",
				label = filename,
				color = "iris",
				actions = {
					delete = win.killed,
				},
			})
			::continue::
		end
	end

	return ls
end

return LIST
