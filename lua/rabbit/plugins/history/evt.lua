---@type Rabbit.Plugin.Events
local EVT = {}
local LIST = require("rabbit.plugins.history.listing")
local OPTS = require("rabbit.plugins.history.config")
local SET = require("rabbit.util.set")
local UIL = require("rabbit.term.listing")

function EVT.BufEnter(evt, ctx)
	if OPTS.ignore_unlisted and vim.bo[evt.buf].buflisted == false then
		return
	end

	local winobj = LIST.init(ctx.winid)
	SET.add(winobj.history, evt.buf)
	SET.add(LIST.global, evt.buf)
	SET.add(LIST.order, ctx.winid)
	LIST.buffers[evt.buf] = evt.file

	-- Clean up reopened buffers
	for k, v in pairs(LIST.buffers) do
		if k ~= evt.buf and v == evt.file then
			LIST.buffers[k] = nil
		end
	end
end

function EVT.BufDelete(_, _) end

function EVT.BufWipeout(evt, ctx)
	if
		UIL._fg == nil
		or not vim.api.nvim_win_is_valid(UIL._fg.win or 1)
		or UIL._plugin ~= ctx.plugin
		or vim.uv.fs_stat(evt.file) ~= nil
	then
		return
	end

	LIST.cache_system()
	for i, e in ipairs(UIL.list(LIST.generate())) do
		if e.ctx.bufnr ~= nil then
			if e.ctx.file == evt.file then
				vim.api.nvim_buf_set_lines(UIL._fg.buf, i - 1, i, false, { "" })
				break
			end
		end
	end
end

function EVT.WinEnter(evt, ctx)
	EVT.BufEnter(evt --[[@as NvimEvent.BufEnter]], ctx)
end

return EVT
