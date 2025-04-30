local SET = require("rabbit.util.set")
local MEM = require("rabbit.util.mem")
local CONFIG = require("rabbit.plugins.trail.config")
local GLOBAL_CONFIG = require("rabbit.config")
local LIST = {
	wins = {}, ---@type Rabbit*Trail.Win.User[]
	bufs = {}, ---@type Rabbit*Trail.Buf[]
	yank = SET.new(), ---@type Rabbit.Table.Set<integer>
	real = {
		wins = {}, ---@type Rabbit*Trail.Win.User[]
		bufs = {}, ---@type Rabbit*Trail.Buf[]
	},
}

---@class Rabbit*Trail.Win: Rabbit.Entry.Collection

---@class Rabbit*Trail.Win.Major: Rabbit*Trail.Win
---@field ctx Rabbit*Trail.Win.Ctx
---@field as fun(self: Rabbit*Trail.Win.Major, label: string): Rabbit*Trail.Win.Major Sets the tail label

---@class Rabbit*Trail.Win.Ctx
---@field wins Rabbit.Table.Set<integer>
---@field bufs Rabbit.Table.Set<integer>

---@class Rabbit*Trail.Win.Copy: Rabbit*Trail.Win
---@field ctx Rabbit*Trail.Win.Copy.Ctx

---@class Rabbit*Trail.Win.Copy.Ctx
---@field source integer Source window ID

---@class Rabbit*Trail.Win.User: Rabbit*Trail.Win
---@field ctx Rabbit*Trail.Win.User.Ctx
---@field Len fun(self: Rabbit*Trail.Win.User): integer

---@class Rabbit*Trail.Win.User.Ctx
---@field winid integer Window ID
---@field bufs Rabbit.Table.Set<integer> Buffer IDs
---@field killed boolean Whether or not the window has been closed

---@class Rabbit*Trail.Buf: Rabbit.Entry.File
---@field ctx Rabbit*Trail.Buf.Ctx
---@field as fun(self: Rabbit*Trail.Buf, winid: integer): Rabbit*Trail.Buf Sets the target window

---@class Rabbit*Trail.Buf.Ctx
---@field listed boolean Whether or not the buffer is listed

---@type Rabbit*Trail.Win.Major
LIST.major = {
	class = "entry",
	type = "collection",
	idx = "⮭",
	label = {
		text = "All Windows",
		hl = {
			"rabbit.types.collection",
			"rabbit.paint.iris",
		},
	},
	tail = {
		text = "",
		hl = { "rabbit.types.tail" },
		align = "right",
	},
	actions = {
		children = true,
		select = true,
		parent = true,
	},
	ctx = {
		wins = SET.new(),
		bufs = SET.new(),
	},
	as = function(self, label)
		self.tail.text = tostring(label) .. " "
		return self
	end,
}

local user_meta = {}
---@param self Rabbit*Trail.Win.User
---@return integer
function user_meta:__len()
	local count = 0
	for _, bufid in ipairs(self.ctx.bufs) do
		if LIST.bufs[bufid].ctx.listed then
			count = count + 1
		end
	end
	return count
end

---@param self Rabbit*Trail.Win.User
---@param key integer
---@return Rabbit*Trail.Buf | nil
function user_meta:__index(key)
	if type(key) ~= "number" or math.floor(key) ~= key then
		return nil
	end

	local idx = 0
	for _, bufid in ipairs(self.ctx.bufs) do
		if LIST.bufs[bufid].ctx.listed then
			idx = idx + 1
			if idx == key then
				return LIST.bufs[bufid]:as(self.ctx.winid)
			end
		end
	end
	return LIST.bufs[vim.api.nvim_win_get_buf(self.ctx.winid)]
end

local win_meta = {}

---@param winid integer
---@return Rabbit*Trail.Win.User | nil
function win_meta.__index(_, winid)
	if type(winid) ~= "number" or math.floor(winid) ~= winid then
		error("Expected integer, got " .. type(winid))
	end

	---@type Rabbit*Trail.Win.User
	local ret = LIST.real.wins[winid]

	if ret == nil then
		if not vim.api.nvim_win_is_valid(winid) then
			return nil
		end

		ret = {
			class = "entry",
			type = "collection",
			idx = true,
			label = {
				text = tostring(winid),
				hl = { "rabbit.paint.iris" },
			},
			actions = {
				children = true,
				select = true,
				hover = true,
				parent = true,
				rename = true,
			},
			ctx = {
				winid = winid,
				bufs = SET.new(),
				killed = false,
			},
			Len = user_meta.__len,
		}
		setmetatable(ret, user_meta)
		LIST.real.wins[winid] = ret
	elseif vim.api.nvim_win_is_valid(winid) then
		ret.label.hl = { "rabbit.types.collection", "rabbit.paint.iris" }
		ret.ctx.killed = false
		ret.actions.delete = false
		ret.actions.rename = true
	else
		ret.label.hl = { "rabbit.types.collection", "rabbit.paint.rose" }
		ret.ctx.killed = true
		ret.actions.delete = true
		ret.actions.rename = false
	end

	if GLOBAL_CONFIG.window.beacon.nrs then
		ret.tail = {
			text = tostring(winid) .. " ",
			hl = { "rabbit.types.tail" },
			align = "right",
		}
	else
		ret.tail = nil
	end

	return ret
end

setmetatable(LIST.wins, win_meta)

---@param self Rabbit*Trail.Buf
---@param winid integer
local function buf_as(self, winid)
	self.target_winid = winid
	return self
end

local buf_meta = {}

---@param bufid integer | string Integer: Buffer ID; String: File path
---@return Rabbit*Trail.Buf
function buf_meta:__index(bufid)
	if type(bufid) == "string" then
		bufid = vim.fn.fnamemodify(bufid, ":p")
		for _, obj in pairs(LIST.real.bufs) do
			if obj.path == bufid then
				-- Update actions and whatnot
				return self[obj.bufid]
			end
		end
	elseif type(bufid) ~= "number" or math.floor(bufid) ~= bufid then
		error("Expected integer or string, got " .. type(bufid))
	end

	---@type Rabbit*Trail.Buf
	local ret = LIST.real.bufs[bufid]

	if ret == nil then
		local true_bufid ---@type integer
		local true_path ---@type string
		local true_listed ---@type boolean

		if type(bufid) == "number" then
			if not vim.api.nvim_buf_is_valid(bufid) then
				error("Rabbit: Invalid buffer id: " .. bufid)
			end

			true_bufid = bufid
			true_path = vim.api.nvim_buf_get_name(bufid)
			true_listed = vim.fn.buflisted(bufid) == 1
		elseif type(bufid) == "string" then
			if not MEM.exists(bufid) then
				error("Invalid file path: " .. bufid)
			end

			true_bufid = vim.uv.hrtime()
			true_path = bufid
			true_listed = false
		end

		ret = {
			class = "entry",
			type = "file",
			idx = true,
			bufid = true_bufid,
			target_winid = 0,
			closed = type(bufid) == "number",
			path = true_path,
			actions = {
				select = true,
				delete = true,
				hover = type(bufid) == "number",
				parent = true,
				rename = false,
				insert = false,
				collect = false,
				visual = true,
				cut = true,
				yank = true,
				paste = false,
			},
			ctx = {
				listed = true_listed,
			},
			as = buf_as,
		}

		LIST.real.bufs[true_bufid] = ret
		LIST.handle_duped_bufs(true_bufid)
	else
		bufid = bufid --[[@as integer]]

		ret.closed = not vim.api.nvim_buf_is_valid(bufid)
		ret.actions.hover = true
		if not ret.closed then
			ret.ctx.listed = vim.fn.buflisted(bufid) == 1 or not CONFIG.ignore_unlisted
		elseif MEM.exists(ret.path) then
			ret.ctx.listed = true
		else
			ret.ctx.listed = false
		end
	end

	return ret
end

setmetatable(LIST.bufs, buf_meta)

-- Remove buffers that are not referenced anywhere
---@param bufs_to_del integer[]
function LIST.clean_bufs(bufs_to_del)
	for _, bufid in ipairs(bufs_to_del) do
		if LIST.major.ctx.bufs:idx(bufid) or LIST.yank:idx(bufid) then
			goto referenced
		end

		for _, winid in ipairs(LIST.major.ctx.wins) do
			local winobj = LIST.wins[winid]
			if winobj.ctx.bufs:idx(bufid) then
				goto referenced
			end
		end

		LIST.real.bufs[bufid] = nil

		-- Only delete buffers that are not referenced anywhere
		::referenced::
	end
end

-- Finds duplicate buffers based on a bufid or path
---@param bufid integer | string
---@return integer[]
function LIST.find_dupes(bufid)
	local target = LIST.bufs[bufid]
	local ret = {}
	for id, obj in pairs(LIST.real.bufs) do
		if obj.path == target.path and id ~= target.bufid and not vim.api.nvim_buf_is_valid(id) then
			table.insert(ret, id)
		end
	end
	return ret
end

-- Handles duplicate buffers
---@param bufid integer
function LIST.handle_duped_bufs(bufid)
	local dupes = LIST.find_dupes(bufid)
	LIST.major.ctx.bufs:sub(dupes, bufid)
	for _, winid in ipairs(LIST.major.ctx.wins) do
		LIST.wins[winid].ctx.bufs:sub(dupes, bufid)
	end

	LIST.clean_bufs(dupes)
end

-- Creates a deep copy operation on the buffer list, allowing for easy extension
---@param fn fun(e: Rabbit*Trail.Buf): Rabbit*Trail.Buf? Any additional actions you want to perform on the entry
---@return table<integer | string, Rabbit*Trail.Buf>
function LIST.copy_bufs(fn)
	fn = fn or function() end
	return setmetatable({}, {
		__index = function(_, key)
			local c = vim.deepcopy(LIST.bufs[key])
			return fn(c) or c
		end,
		__new_index = function(_, _, _)
			error("Read-only")
		end,
	})
end

return LIST
