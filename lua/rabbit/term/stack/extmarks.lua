---@class Rabbit.Stack.Extmarks
local EXTMARKS = setmetatable({
	-- Target workspace
	---@type Rabbit.Stack.Workspace
	target = nil,

	-- Marks by name
	---@type table<string, { id: integer, ns: integer }>
	marks = {},
}, {
	__index = function(self, key)
		assert(self.target ~= nil, "Cannot get extmarks from nil workspace")
		assert(type(key) == "string", "Extmark key must be a string")
	end,
})

function EXTMARKS.new(workspace)
	return setmetatable({ target = workspace }, { __index = EXTMARKS })
end

---@class (exact) Rabbit.Stack.Kwargs.AddExtmark
---@field line integer Line number
---@field col integer Column number
---@field ns? integer | string Highlight namespace
---@field opts vim.api.keyset.set_extmark Kwargs passed to vim.api.nvim_buf_set_extmark
---@field name? string Name of the extmark so you can later reuse it

-- Adds an extmark to the buffer
---@param kwargs Rabbit.Stack.Kwargs.AddExtmark
---@return integer
function EXTMARKS:set(kwargs)
	local ns = kwargs.ns or self.target.ns
	if type(ns) == "string" then
		ns = vim.api.nvim_create_namespace(ns)
	end

	if kwargs.name and self.marks[kwargs.name] and kwargs.opts.id == nil then
		kwargs.opts.id = self.marks[kwargs.name].id
	end

	local id = vim.api.nvim_buf_set_extmark(self.target.buf.id, ns, kwargs.line, kwargs.col, kwargs.opts)
	if kwargs.name then
		self.marks[kwargs.name] = {
			id = id,
			ns = ns,
		}
	end
	return id
end

-- Clears all the extmarks of a namespace
---@param ns? integer | string Highlight namespace. Leave nil to clear all
function EXTMARKS:clear(ns)
	ns = ns or -1
	if type(ns) == "string" then
		ns = vim.api.nvim_create_namespace(ns)
	end
	vim.api.nvim_buf_clear_namespace(self.target.buf.id, ns, 0, -1)
end

-- Delete an extmark given a name
---@param name string
function EXTMARKS:del(name)
	if self.marks[name] then
		vim.api.nvim_buf_del_extmark(self.target.buf.id, self.marks[name].ns, self.marks[name].id)
		self.marks[name] = nil
	end
end

return EXTMARKS
