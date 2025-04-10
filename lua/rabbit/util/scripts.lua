local UI = require("rabbit.term.listing")
local SCRIPTS = {}

---@param plugin string Plugin name
---@param idx number Entry index to select, ignoring non-indexed entries (like 'All Windows' in trail)
function SCRIPTS.select(plugin, idx)
	UI.spawn(plugin)
	for _, entry in ipairs(UI._entries) do
		if entry._env.real == idx then
			UI.handle_callback(UI.find_action("select", entry)(entry))
			return
		end
	end
end

return SCRIPTS
