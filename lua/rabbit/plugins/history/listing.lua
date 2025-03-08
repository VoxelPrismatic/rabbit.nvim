local CTX = require("rabbit.term.ctx")
local MEM = require("rabbit.util.mem")
local SET = require("rabbit.util.set")

---@class Rabbit._.History.Listing
local LIST = {
	---@type table<integer, Rabbit._.History.Window>
	win = {},

	global = {},

	---@type table<integer, string>
	buffers = {},

	-- How windows are ordered in the list
	---@type integer[]
	order = {},

	-- Current window in listing
	---@type integer | nil
	winnr = nil,
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
	local entries = {} ---@type Rabbit.Listing.Entry[]
	local files = {} ---@type string[]
	local target_winnr = LIST.winnr or CTX.user.win
	local winobj

	if LIST.winnr == nil then
		for _, winid in ipairs(LIST.order) do
			winobj = LIST.init(winid)
			LIST.cache_win(winid, winobj)

			if winobj.system == true then
				goto continue
			end

			winobj.killed = not vim.api.nvim_win_is_valid(winid)

			SET.insert(entries, {
				type = "action",
				label = winobj.name,
				color = winobj.killed and "rose" or "iris",
				tail = winobj.killed and "~" or tostring(winid),
				system = true,
				actions = {
					parent = false,
					delete = winobj.killed,
				},
				ctx = {
					winnr = winid,
				},
			})

			::continue::
		end

		files = LIST.global
		winobj = nil
	else
		winobj = LIST.init(LIST.winnr)
		files = winobj.history
		SET.insert(entries, {
			type = "action",
			label = "All Windows",
			color = "iris",
			system = true,
			tail = winobj.name,
			idx = false,
			actions = {
				delete = false,
				rename = false,
			},
			ctx = {
				winnr = nil,
			},
		})
		if winobj.killed then
			target_winnr = CTX.user.win
			SET.insert(entries, {
				type = "action",
				label = "Copy History",
				color = "gold",
				system = true,
				tail = LIST.win[CTX.user.win].name,
				idx = false,
				actions = {
					delete = false,
					rename = false,
				},
				ctx = {
					winnr = CTX.user.win,
					copy = true,
				},
			})
		end
	end

	local skip_first = LIST.winnr == CTX.user.win
	if skip_first and #files == 1 then
		if #files == 1 then
			SET.insert(entries, {
				type = "action",
				label = "There's nowhere to jump to!",
				color = "rose",
				system = "true",
				idx = false,
				actions = {
					delete = false,
					select = false,
					rename = false,
				},
			})
		end
		return entries
	end

	for i, bufnr in ipairs(files) do
		local filename = LIST.buffers[bufnr]

		if filename == nil then
			goto continue -- File has been reopened and we should skip this
		end

		local ctx = {
			winnr = target_winnr,
			file = filename,
			bufnr = bufnr,
			valid = vim.api.nvim_buf_is_valid(bufnr),
		}

		local label = filename ---@type Rabbit.Term.HlLine | string
		if not ctx.valid then
			if vim.uv.fs_stat(filename) == nil or filename == "" then
				goto continue
			else
				local rel_path = MEM.rel_path(filename)
				if rel_path.name == "" then
					goto continue
				end

				label = { ---@type Rabbit.Term.HlLine[]
					{ text = rel_path.dir, hl = { "rabbit.files.path" } },
					{ text = rel_path.name, hl = { "rabbit.files.closed" } },
				}
			end
		end

		SET.insert(entries, {
			type = "file",
			tail = ctx.valid and tostring(bufnr) or "~",
			label = label,
			idx = not (skip_first and i == 1),
			actions = {
				delete = not ctx.valid or (winobj ~= nil and winobj.killed or false),
				parent = LIST.winnr ~= nil,
				rename = false,
			},
			highlight = (skip_first and i == 1) and { "rabbit.types.index" } or nil,
			ctx = ctx,
		})

		::continue::
	end

	return entries
end

return LIST
