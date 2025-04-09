---@class Rabbit.Stack.Autocmd
local AUTOCMD = {
	-- Target workspace
	---@type Rabbit.Stack.Workspace
	target = nil,

	-- Actual event listeners
	---@type table<string, Rabbit.Stack.Autocmd.Event[]>
	events = {},
}

-- Creates a new autocmd manager
---@param workspace Rabbit.Stack.Workspace
function AUTOCMD.new(workspace)
	return setmetatable({ target = workspace }, { __index = AUTOCMD })
end

---@param self Rabbit.Stack.Autocmd.Event
local function autocmd_del(self)
	_ = pcall(vim.api.nvim_del_autocmd, self.id)
	local arr = self.target.events[self.event]
	for i = #arr, 1, -1 do
		if arr[i] == self then
			table.remove(arr, i)
			break
		end
	end
end

---@alias Rabbit.Autocmd vim.api.keyset.create_autocmd | (fun(evt: NvimEvent): nil | boolean)

-- Adds an autocmd listener
---@param event string Event name
---@param kwargs Rabbit.Autocmd Kwargs
---@return Rabbit.Stack.Autocmd.Event
---@overload fun(self: Rabbit.Stack.Autocmd, events: table<string, Rabbit.Autocmd>): table<string, Rabbit.Stack.Autocmd.Event>
---@overload fun(self: Rabbit.Stack.Autocmd, events: string[], kwargs: Rabbit.Autocmd): table<string, Rabbit.Stack.Autocmd.Event>
function AUTOCMD:add(event, kwargs)
	assert(self.target ~= nil, "Cannot add autocmds to nil workspace")

	if type(event) == "table" then
		local ret = {}

		for i = #event, 1, -1 do
			event[table.remove(event, i)] = kwargs
		end

		for k, v in pairs(event) do
			ret[k] = self:add(k, v)
		end
		return ret
	end

	if self.events[event] == nil then
		self.events[event] = {}
	end

	if type(kwargs) == "function" then
		kwargs = {
			callback = kwargs,
			buffer = self.target.buf.id,
			desc = "Rabbit Autocmd",
		}
	elseif kwargs.buffer == nil and kwargs.pattern == nil then
		vim.print(kwargs)
		kwargs.buffer = self.target.buf.id
	end

	---@class Rabbit.Stack.Autocmd.Event
	local ret = {
		-- Event name
		---@type string
		event = event,

		-- Kwargs used to create this event
		---@type vim.api.keyset.create_autocmd
		kwargs = kwargs,

		-- Delete this autocmd
		del = autocmd_del,

		-- Target manager
		---@type Rabbit.Stack.Autocmd
		target = self,

		-- Autocmd ID
		---@type integer
		id = 0,
	}

	if kwargs.callback ~= nil then
		local cb = kwargs.callback or function() end
		kwargs.callback = function(evt)
			local v = cb(evt)
			if v == false or kwargs.once then
				ret:del()
			end
		end
	end

	ret.id = vim.api.nvim_create_autocmd(event, kwargs)
	table.insert(self.events[event], ret)
	return ret
end

-- Deletes all autocmds of a given event
---@param ... string Event names
function AUTOCMD:del(...)
	local varargs = { ... }
	if #varargs == 0 then
		varargs = vim.tbl_keys(self.events)
	end

	for _, evt in ipairs(varargs) do
		for _, v in ipairs(self.events[evt] or {}) do
			v:del()
		end
	end
end

-- Clears all autocmds
function AUTOCMD:clear()
	for k, v in pairs(self.events) do
		for _, e in ipairs(v) do
			e:del()
		end
		self[k] = nil
	end
end

return AUTOCMD
