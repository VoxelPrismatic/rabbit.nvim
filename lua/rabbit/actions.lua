local ACT = {}

---@type Rabbit.Action
function ACT.select(_, entry, _)
	if entry.type == "file" then
		require("rabbit.term.ctx").clear()
		vim.cmd("e '" .. entry.label .. "'")
	end
end

return ACT
