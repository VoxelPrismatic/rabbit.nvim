---@class Rabbit.Table.Set<T>: { [integer]: T }
local SET = {}

-- Creates a new set
---@generic T
---@param arr? T[]
---@return Rabbit.Table.Set<T> set New set object
function SET.new(arr)
	if arr == nil then
		return setmetatable({}, { __index = SET })
	end

	assert(type(arr) == "table", "Expected table, got " .. type(arr))

	---@type Rabbit.Table.Set
	local ret = setmetatable(vim.deepcopy(arr), { __index = SET })

	if #ret < 2 then
		return ret
	end

	local seen = {}
	for i = #ret, 1, -1 do
		local v = tostring(ret[i])
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
---@param elem
---| T # Insert single element
---| T[] # Insert multiple elements
---@param idx? 1 | integer The index to insert the element at. Negative numbers insert at end, eg -1 = last, -2 = second to last
---@return Rabbit.Table.Set<T> self Self for chaining
function SET:add(elem, idx)
	if idx == nil then
		idx = 1
	elseif idx < 1 then
		idx = idx + #self + 2
	elseif type(idx) ~= "number" or math.floor(idx) ~= idx then
		error("Expected integer, got " .. type(idx))
	end

	local to_add = type(elem) == "table" and elem or { elem }

	SET.del(self, to_add)

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
---@return T elem The popped element
function SET:pop(idx)
	return table.remove(self, idx or 1)
end

-- Removes an element (or elements) from the set
---@generic T
---@param elem T | T[]
---@return Rabbit.Table.Set<T> self Self for chaining
---@return integer count How many elements were removed (usually 1)
function SET:del(elem)
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

	return self, count
end

-- Toggles an element
---@generic T
---@param self Rabbit.Table.Set<T>
---@param elem T
---@param include _ Nil to toggle element.
---| true # Force include.
---| false # Force exclude.
---| nil # Toggle element (remove if present, add if not present).
---@return boolean state Whether the element was added or removed
function SET:tog(elem, include)
	if include == nil then
		include = SET.idx(self, elem) == nil
	end

	if include then
		SET.add(self, elem)
	else
		SET.del(self, elem)
	end

	return include
end

-- Returns the index of an element
---@generic T
---@param elem T
---@return integer? idx Index of element, nil if not found
function SET:idx(elem)
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
---@return Rabbit.Table.Set<T> self Self for chaining
function SET:sub(elem, new)
	if type(elem) ~= "table" then
		elem = { elem }
	end

	local done = SET.idx(self, new) ~= nil

	for _, e in ipairs(elem) do
		local idx = SET.idx(self, e)
		while idx do
			if not done then
				self[idx] = new
				done = true
			else
				table.remove(self, idx)
			end
			idx = SET.idx(self, e)
		end
	end

	return self
end

-- Returns logical AND (intersection)
---@generic T
---@param self Rabbit.Table.Set<T>
---@param elem Rabbit.Table.Set<T>
---@return Rabbit.Table.Set<T> intersection
function SET:AND(elem)
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
---@return Rabbit.Table.Set<T> union
function SET:OR(elem)
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
---@return Rabbit.Table.Set<T> negate
function SET:XOR(elem)
	local ret = SET.OR(self, elem)
	ret:del(SET.AND(self, elem))
	return ret
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

-- Maps all elements in the set with a function
---@generic T
---@generic R
---@param self Rabbit.Table.Set<T>
---@param fn fun(idx: integer, elem: T): R?
---@param all_pairs boolean? True to use pairs() instead of ipairs()
---@return Rabbit.Table.Set<R> mapped New set with mapped values
function SET:map(fn, all_pairs)
	local ret = SET.new()
	for k, v in (all_pairs and pairs or ipairs)(self) do
		table.insert(ret, fn(k, v))
	end
	return ret
end

-- Sorts the set
---@generic T
---@param self Rabbit.Table.Set<T>
---@param fn fun(a: T, b: T): boolean?
---@return Rabbit.Table.Set<T> self Self for chaining
function SET:sort(fn)
	table.sort(self, fn)
	return self
end

-- Removes gaps between elements
---@generic T
---@param self Rabbit.Table.Set<T>
---@return Rabbit.Table.Set<T> compacted New compacted set
function SET:compact()
	local ret = SET.new()
	for k, v in pairs(self) do
		if type(k) == "string" then
			ret[k] = v
		else
			table.insert(ret, v)
		end
	end
	return ret
end

-- Puts an element into the set, incrementing the
-- index until a free slot is found
---@generic T
---@param self Rabbit.Table.Set<T>
---@param idx integer
---@param elem T
---@return Rabbit.Table.Set<T> self Self for chaining
function SET:put(idx, elem)
	if idx <= #self + 1 then
		table.insert(self, idx, elem)
		return self
	end

	local swap = self[idx]
	self[idx] = elem
	while swap do
		idx = idx + 1
		self[idx] = swap
		swap = self[idx]
	end

	return self
end

return SET
