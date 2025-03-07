local CTX = require("rabbit.term.ctx")

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
	end

	return LIST.win[winnr]
end

---@class Rabbit._.History.Window
---@field killed boolean Whether or not the window was closed.
---@field name string Custom name for the window.
---@field history integer[] List of buffers in the window.
---@field closed string[] List of buffers that have been closed.
---@field system? boolean Whether or not this window was created by Rabbit itself.

-- Makes sure that system windows aren't listed
function LIST.cache_system()
	for winid, winobj in pairs(LIST.win) do
		for _, winnr in ipairs(CTX.used.win) do
			if winnr == winid then
				winobj.system = true
				break
			end
		end
	end
end

---@param winid integer Window ID
---@param winobj Rabbit._.History.Window
function LIST.cache_win(winid, winobj)
	if winobj.system == nil then
		winobj.system = false
		for _, winnr in ipairs(CTX.used.win) do
			if winnr == winid then
				winobj.system = true
				return
			end
		end
	end
end

-- Creates a listing
---@return Rabbit.Listing.Entry[]
function LIST.generate()
	local ls = {}

	if LIST.action == nil then
		for _, v in ipairs(LIST.order) do
			local w = LIST.win[v]
			LIST.cache_win(v, w)

			if w.system == true then
				goto continue
			end

			w.killed = not vim.api.nvim_win_is_valid(v)

			table.insert(ls, {
				type = "action",
				label = w.name,
				color = w.killed and "rose" or "iris",
				tail = "" .. v,
				system = true,
				actions = {
					parent = false,
					delete = w.killed,
				},
				ctx = {
					new_win = v,
				},
			})

			::continue::
		end
	else
		local winnr = math.abs(LIST.action) or 1000
		local win = LIST.init(winnr)
		local files
		table.insert(ls, {
			type = "action",
			label = "All Windows",
			color = "iris",
			system = true,
			tail = win.name,
			idx = false,
			actions = {
				delete = false,
			},
			ctx = {
				new_win = nil,
			},
		})

		if LIST.action < 0 then
			files = win.closed
			table.insert(ls, {
				type = "action",
				label = "Opened Buffers",
				color = "tree",
				system = true,
				idx = false,
				actions = {
					delete = false,
				},
				ctx = {
					new_win = -LIST.action,
				},
			})
		else
			files = win.history
			table.insert(ls, {
				type = "action",
				label = "Closed Buffers",
				color = "love",
				system = true,
				idx = false,
				actions = {
					delete = false,
				},
				ctx = {
					new_win = -LIST.action,
				},
			})
		end

		for i, filename in ipairs(files) do
			if i == 1 and LIST.action == CTX.user.win then
				goto continue
			elseif type(filename) == "number" then
				if not vim.api.nvim_buf_is_valid(filename) then
					table.remove(files, i)
					goto continue
				end

				filename = vim.api.nvim_buf_get_name(filename)
			elseif vim.uv.fs_stat(filename) == nil then
				table.remove(files, i)
				goto continue
			end

			table.insert(ls, {
				type = "file",
				tail = type(files[i]) == "number" and tostring(files[i]) or "",
				label = filename,
				actions = {
					delete = win.killed,
				},
				ctx = {
					bufnr = files[i],
					winnr = winnr,
				},
			})
			::continue::
		end
	end

	return ls
end

return LIST
