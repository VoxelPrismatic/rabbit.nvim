local LIST = require("rabbit.plugins.trail.list")
local ENV = require("rabbit.plugins.trail.env")

---@type Rabbit.Plugin.Events
local EVT = {}

function EVT.BufEnter(evt, ctx)
	if ENV.open then
		return -- Ignore everything that happens when Rabbit is open
	end

	evt.file = vim.api.nvim_buf_get_name(evt.buf)

	local dupes = LIST.find_dupes(LIST.bufs[evt.buf].path)
	LIST.major.ctx.wins:add(ctx.winid)
	LIST.major.ctx.bufs:add(evt.buf):del(dupes)
	LIST.wins[ctx.winid].ctx.bufs:add(evt.buf):del(dupes)

	if #dupes > 0 then
		-- Update all windows with the new buffer
		for _, winid in ipairs(LIST.major.ctx.wins) do
			LIST.wins[winid].ctx.bufs:sub(dupes, evt.buf)
		end
	end

	LIST.clean_bufs(dupes)
end

function EVT.BufDelete(evt, _)
	if not LIST.bufs[evt.buf].ctx.listed or vim.uv.fs_stat(evt.file) == nil then
		LIST.major.ctx.bufs:del({ evt.buf })
		for _, winid in ipairs(LIST.major.ctx.wins) do
			LIST.wins[winid].ctx.bufs:del({ evt.buf })
		end
	end

	LIST.clean_bufs({ evt.buf })
end

-- EVT.WinEnter = EVT.BufEnter

return EVT
