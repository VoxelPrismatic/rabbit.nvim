local NVIM = {}

-- Shorthand for vim.api.nvim_create_namespace
---@type table<string | number, integer>
NVIM.ns = setmetatable({}, {
	__index = function(self, name)
		if name == nil then
			return -1
		elseif type(name) == "number" then
			return name
		end

		local ret = vim.api.nvim_create_namespace(name)
		rawset(self, name, ret)
		return ret
	end,
})

-- Shorthand for vim.filetype.match({ filename = <name> })
---@type table<string, string>
NVIM.ft = setmetatable({}, {
	__index = function(self, name)
		local ret = vim.filetype.match({ filename = name })
		rawset(self, name, ret)
		return ret
	end,
})

-- Shorthand for function() return <cb>(...) end
---@generic T
---@param cb fun(...): T Callback
---@param ...any any Arguments to pass to the callback
---@return fun(): T
function NVIM.bind(cb, ...)
	local args = { ... }
	return function()
		return cb(unpack(args))
	end
end

return NVIM
