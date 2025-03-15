local CTX = require("rabbit.term.ctx")
local LIST = require("rabbit.plugins.trail.list")
local ACTIONS = {}

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
			text = LIST.wins[source_winid].label[1].text,
			hl = { "rabbit.types.tail" },
			align = "right",
		},

		idx = false,
		actions = {
			select = true,
			delete = false,
			children = false,
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
		local target = LIST.wins[CTX.user.win]
		target.ctx.bufs:add(source.ctx.bufs)
		LIST.major.ctx.wins:del(entry.ctx.source)
		LIST.major.ctx.wins:add(CTX.user.win)
		LIST.real.wins[entry.ctx.source] = nil
		entries = target.actions.children(target)
	elseif entry.ctx.winid == nil then
		entry = entry --[[@as Rabbit*Trail.Win.Major]]
		local wins_to_del, bufs_to_del = {}, {}
		for _, winid in ipairs(entry.ctx.wins) do
			local win = LIST.wins[winid]
			vim.print(win)
			if win == nil then
				-- pass
			elseif win:Len() >= 2 then
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
			local buf = LIST.bufs[bufid]:as(CTX.user.win)
			if buf.ctx.listed then
				buf.idx = true
				table.insert(entries, buf)
			else
				table.insert(bufs_to_del, bufid)
			end
		end

		entry.ctx.wins:del(wins_to_del)
		entry.ctx.bufs:del(bufs_to_del)
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
	end

	return entries
end

return ACTIONS
