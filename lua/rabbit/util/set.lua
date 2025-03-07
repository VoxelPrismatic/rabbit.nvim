local SET = {}

-- Find the first index of an entry in the table
---@generic T
---@param arr T[]
---@param e T
---@return integer | nil The index, or nil if not found
function SET.index(arr, e)
	for i, v in ipairs(arr) do
		if v == e then
			return i
		end
	end
	return nil
end

-- Removes all instances of the entry
---@generic T
---@param arr T[]
---@param e T
---@return boolean If anything was removed
function SET.sub(arr, e)
	local ret = false
	for i = #arr, 1, -1 do
		if arr[i] == e then
			table.remove(arr, i)
			ret = true
		end
	end
	return ret
end

-- Removes all instances of an entry and appends it to the start
---@generic T
---@param arr T[]
---@param e T
function SET.add(arr, e)
	if e == nil then
		return -- This shouldn't happen
	end
	SET.sub(arr, e)
	table.insert(arr, 1, e)
end

---@generic T
---@param table_ T[]
---@param elem T
---@param idx? integer
function SET.insert(table_, elem, idx)
	table.insert(table_, idx or #table_ + 1, elem)
end

return SET
