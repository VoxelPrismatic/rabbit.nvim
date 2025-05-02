local SET = require("rabbit.util.set")
local MEM = require("rabbit.util.mem")
local TERM = require("rabbit.util.term")
local TRAIL = require("rabbit.plugins.trail.list")
local ENV = require("rabbit.plugins.hollow.env")

---@class Rabbit*Hollow.List
local LIST = {}

---@type { [string]: Rabbit*Hollow.SaveFile[] }
LIST.hollow = {}

---@param path string
function LIST.load(path)
	LIST.hollow = setmetatable(MEM.Read(path), {
		---@param self Rabbit.Writeable<integer, Rabbit*Hollow.SaveFile[]>
		__index = function(self, key)
			local ret = setmetatable({}, {
				__index = function(_, s_key)
					if type(s_key) == "number" then
						return nil
					end

					for _, sv in ipairs(self[key]) do
						if sv.name == s_key then
							return sv
						end
					end

					local s_ret = LIST.save(s_key, "iris")
					table.insert(self[key], s_ret)
					self:__Save()
					return s_ret
				end,
			})
			self[key] = ret
			return ret
		end,
	})
end

LIST.major = setmetatable({}, {
	__index = function(self, key)
		---@class Rabbit*Hollow.Major: Rabbit.Entry.Collection
		local ret = {
			class = "entry",
			type = "collection",
			idx = true,
			label = {
				text = key,
				hl = {
					"rabbit.types.collection",
					"rabbit.paint.iris",
				},
			},
			actions = {
				children = true,
				select = true,
				parent = true,
				rename = true,
				collect = true,
			},
			---@class Rabbit*Hollow.Major.Ctx
			ctx = {
				---@type string
				type = "major",

				---@type string
				key = key,

				---@type Rabbit*Hollow.SaveFile[]
				real = LIST.hollow[key],
			},
		}
		self[key] = ret
		return ret
	end,
})

---@type { [string]: Rabbit*Hollow.Collection }
LIST.collection_cache = {}

---@param savefile Rabbit*Hollow.SaveFile
---@return Rabbit*Hollow.Collection
function LIST.make_collection(savefile)
	local addr = tostring(savefile)
	if LIST.collection_cache[addr] == nil then
		---@class Rabbit*Hollow.Collection: Rabbit.Entry.Collection
		LIST.collection_cache[addr] = {
			class = "entry",
			type = "collection",
			idx = true,
			label = {
				text = savefile.name,
				hl = {
					"rabbit.types.collection",
					"rabbit.paint." .. savefile.color,
				},
			},
			actions = {
				children = true,
				select = true,
				parent = true,
				collect = true,
				rename = true,
			},
			---@class Rabbit*Hollow.Collection.Ctx
			ctx = {
				---@type string
				type = "leaf",

				---@type Rabbit*Hollow.SaveFile
				real = savefile,
			},
		}
	end

	return LIST.collection_cache[addr]
end

---@class Rabbit*Hollow.SaveFile
---@field name string
---@field color Rabbit.Colors.Paint
---@field time integer
---@field win_layout vim.api.keyset.winlayout[]
---@field win_order Rabbit.Table.Set<integer>
---@field buf_order Rabbit.Table.Set<integer>
---@field buf_open Rabbit.Table.Set<integer>

---@class Rabbit*Hollow.SaveFile.Wins
---@field id integer
---@field bufs integer[] Buffer IDs
---@field name string Window name
---@field width integer Window width
---@field height integer Window height
---@field cwd string

---@alias vim.api.keyset.winlayout
---| vim.api.keyset.winlayout.leaf
---| vim.api.keyset.winlayout.branch
---@alias vim.api.keyset.winlayout.leaf [ "leaf", integer ]
---@alias vim.api.keyset.winlayout.branch [ "row" | "col", vim.api.keyset.winlayout[] ]

-- Produces a save file for the current list
---@param name string
---@param color Rabbit.Colors.Paint
---@return Rabbit*Hollow.SaveFile save_data
function LIST.save(name, color)
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

	local win_specs = {}
	local win_layout = {}

	for _, tabnr in ipairs(vim.api.nvim_list_tabpages()) do
		if not vim.api.nvim_tabpage_is_valid(tabnr) then
			goto continue
		end

		---@type vim.api.keyset.winlayout
		local layout = vim.fn.winlayout(tabnr)
		if layout == nil then
			goto continue
		end

		table.insert(win_layout, layout)

		local queue = vim.deepcopy({ layout })
		while #queue > 0 do
			---@type vim.api.keyset.winlayout
			local branch = table.remove(queue, 1)
			if branch[1] == "leaf" then
				branch = branch --[[@as vim.api.keyset.winlayout.leaf]]
				win_specs[tostring(branch[2])] = LIST.save_win(branch[2], global_bufs)
			else
				branch = branch --[[@as vim.api.keyset.winlayout.branch]]
				for _, child in ipairs(branch[2]) do
					table.insert(queue, child)
				end
			end
		end

		::continue::
	end

	---@type Rabbit*Hollow.SaveFile
	return {
		name = name,
		color = color,
		time = os.time(),
		win_layout = win_layout,
		win_specs = win_specs,
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
		cwd = vim.fn.getcwd(winid),
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
