---@type Rabbit.Plugin.Actions
local ACT = {}

function ACT.select(_, entry, _)
	if entry.type == "file" then
		require("rabbit.term.ctx").clear()
		vim.cmd("e '" .. entry.label .. "'")
	end

	error("Action not implemented by plugin")
end

function ACT.close(_, _, _)
	require("rabbit.term.ctx").clear()
end

return ACT
