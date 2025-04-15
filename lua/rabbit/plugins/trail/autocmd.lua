local LIST = require("rabbit.plugins.trail.list")
local ENV = require("rabbit.plugins.trail.env")
local TERM = require("rabbit.util.term")
local MEM = require("rabbit.util.mem")

---@type Rabbit.Plugin.Events
local EVT = {}

function EVT.BufEnter(evt, ctx)
	if ENV.open then
		return -- Ignore everything that happens when Rabbit is open
	end

	if TERM.win_config(ctx.winid).relative ~= "" then
		-- Ignore nested windows
		return
	end

	evt.file = vim.api.nvim_buf_get_name(evt.buf)

	local buf = LIST.bufs[evt.buf]
	LIST.major.ctx.wins:add(ctx.winid)
	LIST.major.ctx.bufs:add(evt.buf)
	LIST.wins[ctx.winid].ctx.bufs:add(evt.buf)

	LIST.handle_duped_bufs(buf.bufid)
end

function EVT.BufDelete(evt, _)
	if not (LIST.bufs[evt.buf].ctx.listed and MEM.exists(evt.file)) then
		LIST.handle_duped_bufs(evt.buf)
		LIST.major.ctx.bufs:del({ evt.buf })
		for _, winid in ipairs(LIST.major.ctx.wins) do
			LIST.wins[winid].ctx.bufs:del({ evt.buf })
		end
	end

	LIST.clean_bufs({ evt.buf })
end

function EVT.BufAdd(evt, _)
	if ENV.open then
		return -- Ignore everything that happens when Rabbit is open
	end

	_ = LIST.bufs[evt.buf]
	LIST.major.ctx.bufs:add(evt.buf, -1)
end

function EVT.WinEnter(evt, ctx)
	if TERM.win_config(ctx.winid).relative ~= "" then
		-- Ignore nested windows
		return
	end

	if not LIST.bufs[ctx.bufid].ctx.listed then
		-- Window was opened with the buffer not listed
		return
	end

	EVT.BufEnter({
		buf = ctx.bufid,
		event = "BufEnter",
		file = "",
		id = evt.id,
		match = "",
	}, ctx)
end

return EVT
