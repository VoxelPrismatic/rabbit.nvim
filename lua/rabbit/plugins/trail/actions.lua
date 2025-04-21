local ENV = require("rabbit.plugins.trail.env")
local LIST = require("rabbit.plugins.trail.list")
local CONFIG = require("rabbit.config")
local TERM = require("rabbit.util.term")
local SET = require("rabbit.util.set")
local PLUGIN_CONFIG = require("rabbit.plugins.trail.config")
local MEM = require("rabbit.util.mem")

---@type Rabbit.Plugin.Actions
---@diagnostic disable-next-line: missing-fields
local ACTIONS = {}

local default = 0

---@param source_winid integer
---@return Rabbit.Entry.Collection
local function cb_copy_win(source_winid)
	---@type Rabbit*Trail.Win.Copy
	return {
		class = "entry",
		type = "collection",
		label = {
			text = "Copy Window",
			hl = { "rabbit.paint.gold" },
		},
		tail = {
			text = "to " .. LIST.wins[ENV.winid].label.text .. " ",
			hl = { "rabbit.types.tail" },
			align = "right",
		},

		idx = false,
		actions = {
			select = true,
			delete = false,
			children = true,
			parent = true,
			hover = true,
			rename = false,
			insert = false,
			collect = false,
			paste = #LIST.yank > 0,
			yank = false,
			cut = false,
			visual = false,
		},
		ctx = {
			source = source_winid,
			winid = ENV.winid,
		},
	}
end

---@param entry Rabbit*Trail.Win
---@return Rabbit.Entry[]
function ACTIONS.children(entry)
	local entries = {} ---@type Rabbit.Entry[]
	local can_paste = #LIST.yank > 0
	if entry.ctx.source ~= nil then
		entry = entry --[[@as Rabbit*Trail.Win.Copy]]
		local source = LIST.wins[entry.ctx.source]
		local target = LIST.wins[ENV.winid]
		target.ctx.bufs:add(source.ctx.bufs)
		LIST.major.ctx.wins:del(entry.ctx.source)
		LIST.major.ctx.wins:add(ENV.winid)
		LIST.real.wins[entry.ctx.source] = nil
		entries = ACTIONS.children(target)
	elseif entry.ctx.winid == nil then
		entry = entry --[[@as Rabbit*Trail.Win.Major]]
		ENV.from_major = true
		local wins_to_del, bufs_to_del = {}, {}
		for _, winid in ipairs(entry.ctx.wins) do
			local win = LIST.wins[winid]
			win.actions.paste = can_paste
			if win == nil then
				-- pass
			elseif win:Len() >= 1 then
				if entry._env and default == 0 then
					win.default = win.ctx.winid == entry._env.parent.ctx.winid
				else
					win.default = false
				end
				table.insert(entries, win)
			elseif win.ctx.killed and win:Len() == 0 then
				table.insert(wins_to_del, winid)
				LIST.real.wins[winid] = nil
			end
		end

		if PLUGIN_CONFIG.sort_wins then
			table.sort(entries --[[@as Rabbit*Trail.Win.User[]=]], function(a, b)
				return a.label.text < b.label.text
			end)
		end

		for _, bufid in ipairs(entry.ctx.bufs) do
			local buf = LIST.bufs[bufid]:as(ENV.winid)
			if buf.ctx.listed then
				buf.idx = true
				buf.actions.visual = true
				buf.actions.paste = can_paste
				table.insert(entries, buf)
			else
				table.insert(bufs_to_del, bufid)
			end
		end

		entry.ctx.wins:del(wins_to_del)
		entry.ctx.bufs:del(bufs_to_del)

		LIST.clean_bufs(bufs_to_del)
	else
		entry = entry --[[@as Rabbit*Trail.Win.User]]
		if #LIST.yank == 1 and LIST.yank[1] == entry.ctx.bufs[1] then
			can_paste = false
		end
		LIST.major.actions.paste = can_paste
		table.insert(entries, LIST.major:as(entry.label.text))
		if entry.ctx.killed then
			table.insert(entries, cb_copy_win(entry.ctx.winid))
		end

		local bufs_to_del = {}
		for i, bufid in ipairs(entry.ctx.bufs) do
			local buf = LIST.bufs[bufid]:as(entry.ctx.winid)
			buf.idx = i ~= 1 or ENV.from_major
			buf.actions.visual = buf.idx
			buf.actions.paste = can_paste
			if buf.ctx.listed then
				table.insert(entries, buf)
			else
				table.insert(bufs_to_del, bufid)
			end
		end

		entry.ctx.bufs:del(bufs_to_del)

		LIST.clean_bufs(bufs_to_del)
	end

	if default ~= 0 then
		if entries[default] ~= nil then
			entries[default] = vim.deepcopy(entries[default])
			entries[default].default = true
		end
		default = 0
	end

	return entries
end

function ACTIONS.hover(entry)
	if entry.type == "file" then
		entry = entry --[[@as Rabbit*Trail.Buf]]
		if entry._env.parent == LIST.major then
			entry:as(ENV.winid)
		end
		return {
			class = "message",
			type = "preview",
			file = entry.path,
			bufid = entry.bufid,
			winid = entry.target_winid,
		}
	end

	entry = entry --[[@as Rabbit*Trail.Win.User | Rabbit*Trail.Win.Copy]]
	assert(entry.ctx.winid ~= nil, "major listing should never be hovered")

	if entry.ctx.source ~= nil then
		entry = entry --[[@as Rabbit*Trail.Win.Copy]]
		return {
			class = "message",
			type = "preview",
			bufid = LIST.wins[ENV.winid][1].bufid,
			winid = ENV.winid,
		}
	end

	return {
		class = "message",
		type = "preview",
		bufid = entry[1].bufid,
		winid = entry.ctx.winid,
	}
end

function ACTIONS.parent(_)
	return LIST.major
end

---@param entry Rabbit*Trail.Win.User
---@param new_name string
---@return string
local function check_rename(entry, new_name)
	if new_name == "" then
		new_name = tostring(entry.ctx.winid)
	end

	local names = {}
	for _, winobj in pairs(LIST.real.wins) do
		if winobj.ctx.winid ~= entry.ctx.winid then
			names[winobj.label.text] = true
		end
	end

	return MEM.next_name(names, new_name)
end

---@param entry Rabbit*Trail.Win.User
---@param new_name string
---@return string
local function apply_rename(entry, new_name)
	entry.label.text = check_rename(entry, new_name)
	return entry.label.text
end

function ACTIONS.rename(entry)
	assert(entry.type == "collection", "only collections can be renamed")
	assert(entry.ctx.winid ~= nil, "major window should never be renamed")
	assert(entry.ctx.source == nil, "copy window should never be renamed")

	entry = entry --[[@as Rabbit*Trail.Win.User]]

	assert(not entry.ctx.killed, "killed window should never be renamed")

	return { ---@type Rabbit.Message.Rename
		class = "message",
		type = "rename",
		apply = apply_rename,
		check = check_rename,
		color = false,
		name = entry.label.text,
	}
end

-- Closes the buffer, but also opens new buffers in windows that have that buffer open
---@param target integer
local function migrate_closing_buf(target)
	local blank = -1
	for _, winid in ipairs(LIST.major.ctx.wins) do
		if not vim.api.nvim_win_is_valid(winid) or vim.api.nvim_win_get_buf(winid) ~= target then
			goto continue
		end

		local try_bufs = LIST.wins[winid].ctx.bufs
		local try_buf = blank
		for _, b in ipairs(try_bufs) do
			if b ~= target and vim.api.nvim_buf_is_valid(b) then
				try_buf = b
				break
			end
		end

		if try_buf == -1 then
			blank = vim.api.nvim_create_buf(true, false)
			try_buf = blank
		end

		vim.api.nvim_win_set_buf(winid, try_buf)
		LIST.wins[winid].ctx.bufs:add(try_buf)
		LIST.major.ctx.bufs:add(try_buf)
		ENV.hov[winid] = try_buf
		::continue::
	end
end

function ACTIONS.delete(entry)
	default = entry._env.idx
	if entry.type == "collection" then
		entry = entry --[[@as Rabbit*Trail.Win.User | Rabbit*Trail.Win.Major]]
		assert(entry.ctx.winid ~= nil, "major window should never be deleted")
		assert(entry.ctx.killed == true, "non-killed window should never be deleted")

		LIST.major.ctx.wins:del(entry.ctx.winid)
		if default >= #entry._env.siblings then
			default = #entry._env.siblings - 1
		end

		return entry._env.parent
	end

	entry = entry --[[@as Rabbit*Trail.Buf]]
	assert(entry.type == "file", "unknown entry type")
	local parent = entry._env.parent --[[@as Rabbit*Trail.Win.User | Rabbit*Trail.Win.Major]]

	if entry.closed then
		parent.ctx.bufs:del(entry.bufid)
		LIST.clean_bufs({ entry.bufid })
		if default >= #entry._env.siblings then
			default = #entry._env.siblings - 1
		end
		return entry._env.parent
	end

	-- Closes the associated buffer
	---@param write? boolean
	---@return Rabbit.Entry.Collection | Rabbit.Entry.Search
	local function close(write)
		migrate_closing_buf(entry.bufid)

		if write then
			vim.api.nvim_buf_call(entry.bufid, vim.cmd.write)
		end

		vim.api.nvim_buf_delete(entry.bufid, { force = true })
		return entry._env.parent
	end

	if vim.bo[entry.bufid].modified == false then
		return close()
	end

	return { ---@type Rabbit.Message.Menu
		class = "message",
		type = "menu",
		title = "Unsaved Changes",
		options = {
			{
				label = "Write",
				icon = CONFIG.window.icons.file_write,
				callback = function()
					return close(true)
				end,
			},
			{
				label = "Discard",
				icon = CONFIG.window.icons.file_delete,
				color = "love",
				callback = close,
			},
		},
	}
end

function ACTIONS.yank(entry)
	local start_idx, end_idx = TERM.get_yank()

	LIST.clean_bufs(LIST.yank)
	LIST.yank = SET.new()
	local siblings = entry._env.siblings --[[@as Rabbit*Trail.Buf[]=]]
	for i = start_idx, end_idx do
		local sibling = siblings[i]
		assert(sibling.type == "file", "only files can be yanked")
		LIST.yank:add(sibling.bufid, -1)
	end

	default = start_idx

	return { class = "message" }
end

function ACTIONS.cut(entry)
	ACTIONS.yank(entry)
	entry._env.parent.ctx.bufs:del(LIST.yank)

	return entry._env.parent
end

function ACTIONS.paste(entry)
	local target = entry._env.parent --[[@as Rabbit*Trail.Win.User | Rabbit*Trail.Win.Major]]
	local target_bufs = target.ctx.bufs
	local siblings = entry._env.siblings
	assert(siblings ~= nil, "no siblings")

	local first = 1
	while first < #siblings and (siblings[first].type ~= "file" or siblings[first].actions.visual == false) do
		first = first + 1
	end

	default = math.max(entry._env.idx or 0, first)

	local idx = default - first + 1
	local y = vim.deepcopy(LIST.yank)
	if target ~= LIST.major then
		y:del(target_bufs[1])
		if idx == 1 then
			idx = 2
			default = default + 1
		end
	end

	target_bufs:add(y, idx)

	return target
end

return ACTIONS
