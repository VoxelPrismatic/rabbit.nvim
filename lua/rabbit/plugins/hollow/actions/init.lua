---@type { [string]: Rabbit.Plugin.Actions }
local scopes = setmetatable({}, {
	__index = function(self, key)
		local ok, ret = pcall(require, "rabbit.plugins.hollow.actions." .. key)
		if not ok then
			return nil
		end

		self[key] = ret
		return ret
	end,
})

---@param action string
---@return fun(entry: Rabbit.Entry): Rabbit.Response
local function route_action(action)
	---@param entry Rabbit.Entry
	return function(entry)
		local t = (entry.ctx or {}).type
		assert(t ~= nil, "Unknown entry type: " .. vim.inspect(entry))

		local scope = scopes[t]
		assert(scope ~= nil, "Not implemented: `" .. t .. "'")

		local cb = scope[action]
		assert(cb ~= nil, "Action `" .. action .. "' for `" .. t .. "' not implemented")

		return cb(entry)
	end
end

---@type Rabbit.Plugin.Actions
local ACTIONS = {
	children = route_action("children"),
	parent = route_action("parent"),
	rename = route_action("rename"),
	collect = route_action("collect"),
}

return ACTIONS
