local LIST = require("rabbit.plugins.forage.list")
local ENV = require("rabbit.plugins.forage.env")
local TERM = require("rabbit.util.term")
local MEM = require("rabbit.util.mem")

local EVT = {} ---@type Rabbit.Plugin.Events

function EVT.BufAdd(evt, ctx)
	if ENV.open then
		-- Ignore everything that happens when Rabbit is open
		return
	end

	if vim.fn.buflisted(evt.buf) == 0 then
		-- Ignore unlisted buffers
		return
	end

	evt.file = vim.api.nvim_buf_get_name(evt.buf)
	if MEM.is_type(evt.file, "file") then
		vim.print("touching " .. evt.file)
		LIST.touch(evt.file)
	end
end

return EVT
