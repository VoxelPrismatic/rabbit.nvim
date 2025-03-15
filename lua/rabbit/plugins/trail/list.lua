local SET = require("rabbit.tables.set")
local CONFIG = require("rabbit.plugins.trail.config")
local GLOBAL_CONFIG = require("rabbit.config")
local LIST = {
	wins = {}, ---@type Rabbit*Trail.Win.User[]
	bufs = {}, ---@type Rabbit*Trail.Buf[]
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
	idx = false,
	label = {
		text = "All Windows",
		hl = { "rabbit.paint.iris" },
	},
	tail = {
		text = "",
		hl = { "rabbit.types.tail" },
		align = "right",
	},

	actions = {
		delete = false,
		children = true,
		select = true,
	},
	ctx = {
		wins = SET.new(),
		bufs = SET.new(),
	},
	as = function(self, label)
		self.tail.text = tostring(label)
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
				delete = false,
				children = true,
				select = true,
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
	else
		ret.label.hl = { "rabbit.types.collection", "rabbit.paint.rose" }
		ret.ctx.killed = true
		ret.actions.delete = true
	end

	if GLOBAL_CONFIG.window.nrs then
		ret.tail = {
			text = tostring(winid),
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

---@param bufid integer
---@return Rabbit*Trail.Buf
function buf_meta:__index(bufid)
	if type(bufid) ~= "number" or math.floor(bufid) ~= bufid then
		error("Expected integer, got " .. type(bufid))
	end

	---@type Rabbit*Trail.Buf
	local ret = LIST.real.bufs[bufid]

	if ret == nil then
		if not vim.api.nvim_buf_is_valid(bufid) then
			error("Buffer " .. bufid .. " does not exist")
		end

		ret = {
			class = "entry",
			type = "file",
			idx = true,
			bufid = bufid,
			target_winid = 0,
			closed = false,
			path = vim.api.nvim_buf_get_name(bufid),
			actions = {
				select = true,
				delete = false,
			},
			ctx = {
				listed = vim.fn.buflisted(bufid) == 1,
			},
			as = buf_as,
		}
		LIST.real.bufs[bufid] = ret
	else
		ret.closed = not vim.api.nvim_buf_is_valid(bufid)
		if not ret.closed then
			ret.ctx.listed = vim.fn.buflisted(bufid) == 1 or not CONFIG.ignore_unlisted
		elseif vim.loop.fs_stat(ret.path) then
			ret.ctx.listed = true
		else
			ret.ctx.listed = false
		end
	end

	return ret
end

setmetatable(LIST.bufs, buf_meta)

return LIST
