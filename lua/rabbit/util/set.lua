local SET = { Meta = {} }

---@class Rabbit.Table.Set<T>: table<T>
SET.Func = {}

-- Creates a new set
---@generic T
---@param arr? T[]
---@return Rabbit.Table.Set<T>
function SET.new(arr)
	---@type Rabbit.Table.Set
	local ret = vim.deepcopy(arr or {})
	assert(type(ret) == "table", "Expected table, got " .. type(ret))
	setmetatable(ret, SET.Meta)
	for k, v in pairs(SET.Func) do
		ret[k] = v
	end

	local seen = {}
	for i = #ret, 1, -1 do
		local v = ret[i]
		if seen[v] then
			table.remove(ret, i)
		else
			seen[v] = true
		end
	end

	return ret
end

-- Inserts an element (or elements) into the set
---@generic T
---@param self Rabbit.Table.Set<T>
---@param elem T
---@param idx? 1 | integer The index to insert the element at
---@return Rabbit.Table.Set<T> "Self for chaining"
---@overload fun(self: Rabbit.Table.Set<`T`>, elem: `T`[], idx?: 1 | integer)
function SET.Func:add(elem, idx)
	if idx == nil then
		idx = 1
	elseif idx < 1 then
		idx = idx + #self + 2
	elseif type(idx) ~= "number" or math.floor(idx) ~= idx then
		error("Expected integer, got " .. type(idx))
	end

	local to_add = type(elem) == "table" and elem or { elem }

	SET.Func.del(self, to_add)

	idx = math.min(math.max(1, idx), #self + 1)

	for i = #to_add, 1, -1 do
		table.insert(self, idx, to_add[i])
	end

	return self
end

-- Pops an element from the set
---@generic T
---@param self Rabbit.Table.Set<T>
---@param idx? 1 | integer The index of the element to pop
---@return T "The popped element"
function SET.Func:pop(idx)
	return table.remove(self, idx or 1)
end

-- Removes an element (or elements) from the set
---@generic T
---@param self Rabbit.Table.Set<T>
---@param elem T | T[]
---@return integer "How many elements were removed (usually 1)"
function SET.Func:del(elem)
	local count = 0
	if type(elem) ~= "table" then
		elem = { elem }
	end

	for _, e in ipairs(elem) do
		for i = #self, 1, -1 do
			if self[i] == e then
				table.remove(self, i)
				count = count + 1
			end
		end
	end

	return count
end

-- Toggles an element
---@generic T
---@param self Rabbit.Table.Set<T>
---@param elem T
---@param include? boolean True = Force include; False = Force exclude; Nil = Toggle
---@return boolean "Whether the element was added or removed"
function SET.Func:tog(elem, include)
	if include == nil then
		include = SET.Func.idx(self, elem) == nil
	end

	if include then
		SET.Func.add(self, elem)
	else
		SET.Func.del(self, elem)
	end

	return include
end

-- Returns the index of an element
---@generic T
---@param self Rabbit.Table.Set<T>
---@param elem T
---@return integer | nil
function SET.Func:idx(elem)
	for i, v in ipairs(self) do
		if v == elem then
			return i
		end
	end
	return nil
end

-- Replaces all instances of these elements with another
---@generic T
---@param self Rabbit.Table.Set<T>
---@param elem T | T[]
---@param new T
---@return Rabbit.Table.Set<T>
function SET.Func:sub(elem, new)
	if type(elem) ~= "table" then
		elem = { elem }
	end

	local done = SET.Func.idx(self, new) ~= nil

	for _, e in ipairs(elem) do
		local idx = SET.Func.idx(self, e)
		while idx do
			if not done then
				self[idx] = new
				done = true
			else
				table.remove(self, idx)
			end
			idx = SET.Func.idx(self, e)
		end
	end

	return self
end

-- Returns logical AND (intersection)
---@generic T
---@param self Rabbit.Table.Set<T>
---@param elem Rabbit.Table.Set<T>
---@return Rabbit.Table.Set<T>
function SET.Func:AND(elem)
	local ret = SET.new()

	for _, v in ipairs(self) do
		if elem:idx(v) then
			ret:add(v)
		end
	end

	return ret
end

-- Returns logical OR (union)
---@generic T
---@param self Rabbit.Table.Set<T>
---@param elem Rabbit.Table.Set<T>
---@return Rabbit.Table.Set<T>
function SET.Func:OR(elem)
	local ret = SET.new()
	for _, v in ipairs(self) do
		ret:add(v)
	end
	for _, v in ipairs(elem) do
		ret:add(v)
	end
	return ret
end

-- Returns logical XOR (exclusive OR)
---@generic T
---@param self Rabbit.Table.Set<T>
---@param elem Rabbit.Table.Set<T>
---@return Rabbit.Table.Set<T>
function SET.Func:XOR(elem)
	return SET.Func.OR(self, elem):del(SET.Func.AND(self, elem))
end

-- Returns keys from pairs
---@param t table
---@return ...any
function SET.keys(t)
	local ret = {}
	for k in pairs(t or {}) do
		table.insert(ret, k)
	end
	return unpack(ret)
end

return SET
