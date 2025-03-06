---@type Rabbit.Plugin.Events
local EVT = {}
local LIST = require("rabbit.plugins.history.listing")
local OPTS = require("rabbit.plugins.history.config")
local SET = require("rabbit.util.set")

function EVT.BufEnter(evt, ctx)
	if OPTS.ignore_unlisted and vim.bo[evt.buf].buflisted == false then
		return
	end

	SET.add(LIST.init(ctx.winid).history, evt.buf)
	SET.add(LIST.order, ctx.winid)
end

function EVT.BufDelete(evt, ctx)
	local r = LIST.init(ctx.winid)
	if SET.sub(r.history, evt.buf) then
		SET.add(r.closed, evt.file)
	end
end

function EVT.WinClosed(_, ctx)
	LIST.init(ctx.winid).killed = true
end

return EVT
