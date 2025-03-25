local LIST = require("rabbit.plugins.trail.list")
local ENV = require("rabbit.plugins.trail.env")

---@type Rabbit.Plugin.Events
local EVT = {}

function EVT.BufEnter(evt, ctx)
	if ENV.open then
		return -- Ignore everything that happens when Rabbit is open
	end

	local dupes = LIST.find_dupes(LIST.bufs[evt.buf].path)
	LIST.wins[ctx.winid].ctx.bufs:add(evt.buf):del(dupes)
	LIST.major.ctx.bufs:add(evt.buf):del(dupes)
	LIST.major.ctx.wins:add(ctx.winid)

	LIST.clean_bufs(dupes)
end

function EVT.BufDelete(evt, _)
	LIST.clean_bufs({ evt.buf })
end

-- EVT.WinEnter = EVT.BufEnter

return EVT
