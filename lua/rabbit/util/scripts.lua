local UI = require("rabbit.term.listing")
local SCRIPTS = {}

---@param plugin string Plugin name
---@param ...
---| integer Entry index to select, ignoring non-indexed entries (like 'All Windows' in trail)
---| { idx: integer, action: string } Entry index and action to perform
function SCRIPTS.select(plugin, ...)
	UI.spawn(plugin)
	for idx in pairs({ ... }) do
		if type(idx) == "table" then
			UI.bind_callback(idx.action, UI._entries[idx.idx], true)()
		else
			for _, entry in ipairs(UI._entries) do
				local real = entry._env.real
				if real == idx then
					UI.bind_callback("select", entry, true)()
					break
				elseif (real or 0) > idx then
					return
				end
			end
		end
	end
end

---@param plugin string Plugin name
---@param ...
---| integer Entry index to select, ignoring non-indexed entries (like 'All Windows' in trail)
---| { idx: integer, action: string } Entry index and action to perform
---@return fun() callback
function SCRIPTS.bind_select(plugin, ...)
	local vararg = { ... }
	return function()
		SCRIPTS.select(plugin, unpack(vararg))
	end
end

return SCRIPTS
