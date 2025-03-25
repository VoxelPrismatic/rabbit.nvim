local ENV = require("rabbit.plugins.trail.env")
local LIST = require("rabbit.plugins.trail.list")

---@type Rabbit.Plugin.Actions
local ACTIONS = {}

---@param source_winid integer
---@return Rabbit.Entry.Collection
local function cb_copy_win(source_winid)
	---@type Rabbit*Trail.Win.Copy
	vim.print(source_winid)
	return {
		class = "entry",
		type = "collection",
		label = {
			text = "Copy Window",
			hl = { "rabbit.paint.gold" },
		},
		tail = {
			text = LIST.wins[source_winid].label[1].text,
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
		},
		ctx = {
			source = source_winid,
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
				if entry._env then
					win.default = win.ctx.winid == entry._env.parent.ctx.winid
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
	elseif entry.ctx.winid == nil then
		error("Unreachable (major listing should never be hovered)")
	elseif entry.ctx.source ~= nil then
		entry = entry --[[@as Rabbit*Trail.Win.Copy]]
		return {
			class = "message",
			type = "preview",
			bufid = LIST.wins[ENV.winid][1].bufid,
			winid = ENV.winid,
		}
	end

	entry = entry --[[@as Rabbit*Trail.Win.User]]
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
	if entry.type == "file" then
		error("Unreachable (file should never be renamed)")
	elseif entry.ctx.winid == nil then
		error("Unreachable (major listing should never be renamed)")
	elseif entry.ctx.source ~= nil then
		error("Unreachable (copy listing should never be renamed)")
	end

	entry = entry --[[@as Rabbit*Trail.Win.User]]

	if entry.ctx.killed then
		error("Unreachable (killed window should never be renamed)")
	end

	return { ---@type Rabbit.Message.Rename
		class = "message",
		type = "rename",
		apply = apply_rename,
		color = false,
		name = entry.label.text,
	}
end

return ACTIONS
