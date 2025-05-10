--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

local SET = require("rabbit.util.set")
local MEM = require("rabbit.util.mem")
local TERM = require("rabbit.util.term")
local TRAIL = require("rabbit.plugins.trail.list")
local TRAIL_ACTIONS = require("rabbit.plugins.trail.actions")
local ENV = require("rabbit.plugins.hollow.env")

---@class Rabbit*Hollow.List
local LIST = {}

---@type { [string]: Rabbit*Hollow.SaveFile[] }
LIST.hollow = {}

LIST.bufs = TRAIL.copy_bufs(function(buf)
	buf = buf:as(ENV.winid)
	buf.idx = true
	for k, v in ipairs(buf.actions) do
		if v then
			buf.actions[k] = TRAIL_ACTIONS[k]
		end
	end
	return buf
end)

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

---@type { [string]: Rabbit*Hollow.C.Major }
LIST.major = setmetatable({}, {
	__index = function(self, key)
		---@class Rabbit*Hollow.C.Major: Rabbit.Entry.Collection
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
			---@class Rabbit*Hollow.C.Major.Ctx
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

---@class Rabbit*Hollow.SaveFile
---@field name string
---@field color Rabbit.Colors.Paint
---@field time integer
---@field win_order integer[]
---@field win_specs { [string]: Rabbit*Hollow.SaveFile.Win }
---@field buf_order string[]
---@field buf_open integer[]
---@field tab_layout Rabbit*Hollow.SaveFile.Tab[]
---@field cwd string

---@class Rabbit*Hollow.SaveFile.Tab
---@field name string
---@field color Rabbit.Colors.Paint
---@field layout vim.fn.winlayout.ret
---@field cwd? string

---@class Rabbit*Hollow.SaveFile.Win
---@field id integer
---@field bufs integer[] Buffer IDs
---@field name string Window name
---@field width integer Window width
---@field height integer Window height
---@field view vim.fn.winsaveview.ret
---@field cwd? string

---@alias vim.fn.winlayout.ret
---| vim.fn.winlayout.leaf
---| vim.fn.winlayout.branch
---@alias vim.fn.winlayout.leaf [ "leaf", integer ]
---@alias vim.fn.winlayout.branch [ "row" | "col", vim.fn.winlayout.ret[] ]

-- Produces a save file for the current list
---@param name string
---@param color Rabbit.Colors.Paint
---@return Rabbit*Hollow.SaveFile save_data
function LIST.save(name, color)
	local global_bufs = {}
	local buf_names = {} ---@type string[]
	local buf_open = {}
	for i, bufid in ipairs(TRAIL.major.ctx.bufs) do
		global_bufs[bufid] = i
		local buf = TRAIL.bufs[bufid]
		buf_names[i] = buf.path
		if not buf.closed and MEM.exists(buf.path) then
			table.insert(buf_open, i)
		end
	end

	local global_cwd = vim.fn.getcwd(-1, -1)
	local win_specs = {}
	local tab_layout = {}

	for _, tabnr in ipairs(vim.api.nvim_list_tabpages()) do
		if not vim.api.nvim_tabpage_is_valid(tabnr) then
			goto continue
		end

		---@type vim.fn.winlayout.ret
		local layout = vim.fn.winlayout(tabnr)
		if layout == nil or #layout == 0 then
			goto continue
		end

		local tab_cwd = vim.fn.getcwd(-1, tabnr)

		---@type Rabbit*Hollow.SaveFile.Tab
		local tab = {
			color = tostring(vim.t[tabnr].RabbitColor) or "iris",
			name = tostring(vim.t[tabnr].RabbitLabel) or ("Tab " .. tabnr),
			layout = layout,
			cwd = tab_cwd ~= global_cwd and tab_cwd or nil,
		}

		table.insert(tab_layout, tab)

		local queue = vim.deepcopy({ layout })
		while #queue > 0 do
			---@type vim.fn.winlayout.ret
			local branch = table.remove(queue, 1)
			if branch[1] == "leaf" then
				branch = branch --[[@as vim.fn.winlayout.leaf]]
				win_specs[tostring(branch[2])] = LIST.save_win(branch[2], global_bufs)
			else
				branch = branch --[[@as vim.fn.winlayout.branch]]
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
		tab_layout = tab_layout,
		win_specs = win_specs,
		win_order = SET.new(TRAIL.major.ctx.wins),
		buf_order = buf_names,
		buf_open = buf_open,
		tab_names = {},
		cwd = global_cwd,
	}
end

---@param winid integer
---@param files integer[]
---@return Rabbit*Hollow.SaveFile.Win
function LIST.save_win(winid, files)
	local win = TRAIL.wins[winid]
	local win_config = TERM.win_config(winid)
	assert(win_config ~= nil, "Window doesn't exist")
	local bufs = {}
	for _, bufid in ipairs(win.ctx.bufs) do
		table.insert(bufs, files[bufid])
	end

	local win_cwd = vim.fn.getcwd(winid)
	local global_cwd = vim.fn.getcwd(-1, -1)

	---@type Rabbit*Hollow.SaveFile.Win
	local ret = {
		id = winid,
		name = win.label.text,
		width = win_config.width,
		height = win_config.height,
		bufs = bufs,
		cwd = win_cwd ~= global_cwd and win_cwd or nil,
		view = vim.api.nvim_win_call(winid, vim.fn.winsaveview),
	}

	return ret
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
