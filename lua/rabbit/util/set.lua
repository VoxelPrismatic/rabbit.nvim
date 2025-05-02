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
	elseif idx < 0 then
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
	if idx == nil then
		idx = 1
	elseif idx < 0 then
		idx = idx + #self + 1
	end
	return table.remove(self, idx)
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

	local target = nil
	while target == nil and #elem > 0 do
		target = SET.idx(self, table.remove(elem, 1))
	end
	if target == nil then
		return self
	end

	SET.pop(self, target)
	SET.add(self, new, target)
	SET.del(self, elem)

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

-- Returns logical XOR (difference)
---@generic T
---@param self Rabbit.Table.Set<T>
---@param elem Rabbit.Table.Set<T>
---@return Rabbit.Table.Set<T> difference
function SET:XOR(elem)
	local ret = SET.OR(self, elem)
	ret:del(SET.AND(self, elem))
	return ret
end

-- Returns keys from pairs
---@param t table
---@return any[] keys
function SET.keys(t)
	local ret = {}
	for k in pairs(t or {}) do
		table.insert(ret, k)
	end
	return ret
end

-- Creates a new set from multiple lists
---@generic T
---@param ... T[]
---@return Rabbit.Table.Set<T>
function SET.extend(...)
	local ret = SET.new()
	for _, v in ipairs({ ... }) do
		ret:add(v)
	end
	return ret
end

-- Maps all elements in the set with a function
---@generic T
---@generic R
---@param self Rabbit.Table.Set<T>
---@param fn fun(idx: integer | string, elem: T): R?
---@return Rabbit.Table.Set<R> mapped New set with mapped values
function SET:map(fn)
	local ret = SET.new()
	for k, v in pairs(self) do
		if type(k) == "integer" then
			table.insert(ret, fn(k, v))
		else
			ret[k] = fn(k, v)
		end
	end
	return ret
end

-- Maps all elements in the set with a function, regardless of
-- key value
---@generic T
---@generic R
---@param self Rabbit.Table.Set<T>
---@param fn fun(elem: T): R
---@return Rabbit.Table.Set<R> mapped New set with mapped values
function SET:imap(fn)
	local ret = SET.new()
	for _, v in ipairs(self) do
		table.insert(ret, fn(v))
	end
	return ret
end

-- Sorts the set
---@generic T
---@param self Rabbit.Table.Set<T>
---@param fn fun(a: T, b: T): boolean
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
	local idxs = {}
	for k, v in pairs(self) do
		if type(k) == "number" then
			table.insert(idxs, k)
		else
			ret[k] = v
		end
	end

	table.sort(idxs, function(a, b)
		return a > b
	end)

	for _, v in ipairs(idxs) do
		ret:add(self[v])
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
	assert(type(idx) == "number", "Expected integer, got " .. type(idx))
	assert(math.floor(idx) == idx, "Expected integer, got " .. type(idx))

	if idx <= #self + 1 and idx > 0 then
		SET.add(self, elem, idx)
		return self
	end

	local sign = idx <= 0 and -1 or 1

	local swap = self[idx]
	self[idx] = elem
	while swap do
		idx = idx + sign
		swap, self[idx] = self[idx], swap
	end

	return self
end

-- Allows you to look for an element with a key set to a specific value
---@generic I, K, V
---@param key K
---@param tbl { [I]: { [K]: V } }
---@return { [I]: { [K]: V }, [V]: { [K]: V } }
function SET.lookup(key, tbl)
	return setmetatable(tbl, {
		__index = function(self, k)
			for _, v in pairs(self) do
				if v[key] == k then
					return v
				end
			end
		end,
	})
end

return SET
