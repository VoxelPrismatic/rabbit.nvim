local LIST = require("rabbit.plugins.trail.list")
local ENV = require("rabbit.plugins.trail.env")

---@type Rabbit.Plugin.Events
local EVT = {}

function EVT.BufEnter(evt, ctx)
	if ENV.open then
		return -- Ignore everything that happens when Rabbit is open
	end
	_ = LIST.bufs[evt.buf] -- Create the buffer entry if it doesn't exist
	LIST.wins[ctx.winid].ctx.bufs:add(evt.buf)
	LIST.major.ctx.bufs:add(evt.buf)
	LIST.major.ctx.wins:add(ctx.winid)
end

return EVT
