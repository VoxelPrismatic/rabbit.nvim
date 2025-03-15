local SET = { Meta = {} }

---@class Rabbit.Table.Set<T>: table<T>
SET.Func = {}

-- Creates a new set
---@generic T
---@param arr? `T`[]
---@return Rabbit.Table.Set<T>
function SET.new(arr)
	---@type Rabbit.Table.Set
	local ret = arr or {}
	setmetatable(ret, SET.Meta)
	for k, v in pairs(SET.Func) do
		ret[k] = v
	end

	return ret
end

-- Inserts an element (or elements) into the set
---@generic T
---@param self Rabbit.Table.Set<`T`>
---@param elem T
---@param idx? 1 | integer The index to insert the element at
---@overload fun(self: Rabbit.Table.Set<`T`>, elem: `T`[], idx?: 1 | integer)
function SET.Func:add(elem, idx)
	if idx == nil then
		idx = 1
	elseif type(idx) ~= "number" or math.floor(idx) ~= idx then
		error("Expected integer, got " .. type(idx))
	end

	local to_add = type(elem) == "table" and elem or { elem }
	for i, v in ipairs(to_add) do
		self:del(v)
		table.insert(self, idx + i - 1, v)
	end
end

-- Pops an element from the set
---@generic T
---@param self Rabbit.Table.Set<`T`>
---@param idx 1 | integer The index of the element to pop
---@return `T`
function SET.Func:pop(idx)
	return table.remove(self, idx)
end

-- Removes an element (or elements) from the set
---@generic T
---@param self Rabbit.Table.Set<`T`>
---@param elem T | T[]
---@return integer "How many elements were removed (usually 1)"
function SET.Func:del(elem)
	local count = 0
	for i, v in ipairs(self) do
		if v == elem then
			table.remove(self, i)
			count = count + 1
		end
	end
	return count
end

return SET
