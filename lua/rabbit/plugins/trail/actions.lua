local ENV = require("rabbit.plugins.trail.env")
local LIST = require("rabbit.plugins.trail.list")

---@type Rabbit.Plugin.Actions
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
			children = false,
			parent = true,
			hover = true,
			rename = false,
			insert = false,
			collect = false,
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
	if entry.ctx.source ~= nil then
		entry = entry --[[@as Rabbit*Trail.Win.Copy]]
		local source = LIST.wins[entry.ctx.source]
		local target = LIST.wins[ENV.winid]
		target.ctx.bufs:add(source.ctx.bufs)
		LIST.major.ctx.wins:del(entry.ctx.source)
		LIST.major.ctx.wins:add(ENV.winid)
		LIST.real.wins[entry.ctx.source] = nil
		entries = target.actions.children(target)
	elseif entry.ctx.winid == nil then
		entry = entry --[[@as Rabbit*Trail.Win.Major]]
		local wins_to_del, bufs_to_del = {}, {}
		for _, winid in ipairs(entry.ctx.wins) do
			local win = LIST.wins[winid]
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

		for _, bufid in ipairs(entry.ctx.bufs) do
			local buf = LIST.bufs[bufid]:as(ENV.winid)
			if buf.ctx.listed then
				buf.idx = true
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
		table.insert(entries, LIST.major:as(entry.label.text))
		if entry.ctx.killed then
			table.insert(entries, cb_copy_win(entry.ctx.winid))
		end

		local bufs_to_del = {}
		for i, bufid in ipairs(entry.ctx.bufs) do
			local buf = LIST.bufs[bufid]:as(entry.ctx.winid)
			buf.idx = i ~= 1
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
local function apply_rename(entry, new_name)
	if new_name == "" then
		new_name = tostring(entry.ctx.winid)
	end

	for _, winobj in pairs(LIST.real.wins) do
		if winobj ~= entry and winobj.label.text == new_name then
			local _, _, count, match = new_name:find("(%++)([0-9]*)$")
			if match == nil and count == nil then
				return apply_rename(entry, new_name .. "+")
			elseif match == "" and count ~= "" then
				return apply_rename(entry, new_name .. #count)
			else
				local new_idx = tostring(tonumber(match) + 1)
				return apply_rename(entry, new_name:sub(1, -#new_idx - 1) .. new_idx)
			end
		end
	end
	entry.label.text = new_name
	return new_name
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
		color = false,
		name = entry.label.text,
	}
end

function ACTIONS.delete(entry)
	default = entry._env.idx
	if entry.type == "collection" then
		entry = entry --[[@as Rabbit*Trail.Win.User | Rabbit*Trail.Win.Major]]
		assert(entry.ctx.winid ~= nil, "major window should never be deleted")
		assert(entry.ctx.killed == true, "non-killed window should never be deleted")

		LIST.major.ctx.wins:del(entry.ctx.winid)
		if default == #entry._env.siblings then
			default = default - 1
		end
	elseif entry.type == "file" then
		entry = entry --[[@as Rabbit*Trail.Buf]]
		local parent = entry._env.parent --[[@as Rabbit*Trail.Win.User | Rabbit*Trail.Win.Major]]
		if not entry.closed then
			assert(vim.bo[entry.bufid].modified == false, "modified buffer should never be deleted")
			local bufid = -1
			for _, winid in ipairs(LIST.major.ctx.wins) do
				if vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_buf(winid) == entry.bufid then
					local try_bufs = LIST.wins[winid].ctx.bufs
					local try_buf = bufid
					for _, b in ipairs(try_bufs) do
						if b ~= entry.bufid and vim.api.nvim_buf_is_valid(b) then
							try_buf = b
							break
						end
					end
					if try_buf == -1 then
						bufid = vim.api.nvim_create_buf(true, false)
						try_buf = bufid
					end
					vim.api.nvim_win_set_buf(winid, try_buf)
					LIST.wins[winid].ctx.bufs:add(try_buf)
					require("rabbit.term.listing")._hov[winid] = bufid
				end
			end

			vim.api.nvim_buf_delete(entry.bufid, { force = true })
		else
			parent.ctx.bufs:del(entry.bufid)
			LIST.clean_bufs({ entry.bufid })
			if default == #entry._env.siblings then
				default = default - 1
			end
		end
	else
		error("unknown entry type")
	end

	return entry._env.parent
end

return ACTIONS
