local SET = require("rabbit.util.set")
local MEM = require("rabbit.util.mem")
local TERM = require("rabbit.util.term")
local TRAIL = require("rabbit.plugins.trail.list")

---@class Rabbit*Hollow.List
local LIST = {}

---@type { [string]: Rabbit*Hollow.SaveFile[] }
LIST.major = {}

---@param path string
function LIST.load(path)
	LIST.major = setmetatable(MEM.Read(path), {
		---@param self Rabbit.Writeable<string, Rabbit*Hollow.SaveFile[]>
		__index = function(self, key)
			local ret = setmetatable({}, {
				__index = function(_, s_key)
					local s_ret = LIST.save("rabbit.paint.iris")
					self[key][s_key] = s_ret
					self:__Save()
					return s_ret
				end,
			})
			self[key] = ret
			return ret
		end,
	})
end

---@class Rabbit*Hollow.SaveFile
---@field color string
---@field time integer
---@field layout Rabbit*Hollow.SaveFile.Layout
---@field win_order Rabbit.Table.Set<integer>
---@field buf_order Rabbit.Table.Set<integer>
---@field buf_open Rabbit.Table.Set<integer>

---@class Rabbit*Hollow.SaveFile.Wins
---@field id integer
---@field bufs integer[] Buffer IDs
---@field name string Window name
---@field width integer Window width
---@field height integer Window height

---@alias vim.api.keyset.winlayout
---| vim.api.keyset.winlayout.leaf
---| vim.api.keyset.winlayout.branch
---@alias vim.api.keyset.winlayout.leaf [ "leaf", integer ]
---@alias vim.api.keyset.winlayout.branch [ "row" | "col", vim.api.keyset.winlayout[] ]

---@alias Rabbit*Hollow.SaveFile.Layout
---| Rabbit*Hollow.SaveFile.Layout.Leaf
---| Rabbit*Hollow.SaveFile.Layout.Branch
---@alias Rabbit*Hollow.SaveFile.Layout.Leaf [ "leaf", Rabbit*Hollow.SaveFile.Wins ]
---@alias Rabbit*Hollow.SaveFile.Layout.Branch [ "row" | "col", Rabbit*Hollow.SaveFile.Layout[] ]

-- Produces a save file for the current list
---@param color string
---@return Rabbit*Hollow.SaveFile save_data
function LIST.save(color)
	local global_bufs = {}
	local buf_names = {}
	local buf_open = {}
	for i, bufid in ipairs(TRAIL.major.ctx.bufs) do
		global_bufs[bufid] = i
		local buf = TRAIL.bufs[bufid]
		buf_names[i] = buf.path
		if not buf.closed and MEM.exists(buf.path) then
			table.insert(buf_open, i)
		end
	end

	---@param node vim.api.keyset.winlayout
	---@return Rabbit*Hollow.SaveFile.Layout
	local function process_node(node)
		if node[1] == "leaf" then
			node = node --[[@as vim.api.keyset.winlayout.leaf]]
			return { "leaf", LIST.save_win(node[2], global_bufs) }
		end

		node = node --[[@as vim.api.keyset.winlayout.branch]]

		local ret = { node[1] }
		for _, child in ipairs(node[2]) do
			table.insert(ret, process_node(child))
		end

		return ret
	end

	local layout = process_node(vim.fn.winlayout())

	---@type Rabbit*Hollow.SaveFile
	return {
		color = color,
		time = os.time(),
		layout = layout,
		win_order = SET.new(TRAIL.major.ctx.wins),
		buf_order = buf_names,
		buf_open = buf_open,
	}
end

---@param winid integer
---@param files integer[]
---@return Rabbit*Hollow.SaveFile.Wins
function LIST.save_win(winid, files)
	local win = TRAIL.wins[winid]
	local win_config = TERM.win_config(winid)
	assert(win_config ~= nil, "Window doesn't exist")
	local bufs = {}
	for _, bufid in ipairs(win.ctx.bufs) do
		table.insert(bufs, files[bufid])
	end

	---@type Rabbit*Hollow.SaveFile.Wins
	return {
		id = winid,
		name = win.label.text,
		width = win_config.width,
		height = win_config.height,
		bufs = bufs,
	}
end

local function restore_winlayout(layout)
	-- Helper function to process the layout recursively
	local function process_node(node, is_first)
		if node[1] == "leaf" then
			local winid = node[2]
			-- If window still exists, go to it
			if vim.api.nvim_win_is_valid(winid) then
				vim.api.nvim_set_current_win(winid)
			else
				-- Otherwise, open a new window with the buffer (if known)
				local bufnr = vim.fn.winbufnr(winid) -- Get buffer number
				if bufnr ~= -1 then
					vim.api.nvim_set_current_buf(bufnr)
				else
					-- Fallback: open a new buffer (or use a placeholder)
					vim.cmd("enew")
				end
			end
		elseif node[1] == "row" or node[1] == "col" then
			-- Process each child node
			for i, child in ipairs(node[2]) do
				if i > 1 or not is_first then
					-- Create a split (unless it's the first child at the top level)
					if node[1] == "row" then
						vim.cmd("wincmd s") -- Horizontal split
						vim.cmd("wincmd j") -- Move to the new window below
					else
						vim.cmd("wincmd v") -- Vertical split
						vim.cmd("wincmd l") -- Move to the new window to the right
					end
				end
				process_node(child, false)
			end
		end
	end

	-- Close all windows except the current one to start fresh
	vim.cmd("only")
	-- Process the layout tree
	process_node(layout, true)
end

return LIST
