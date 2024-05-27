local M = {}

-- Find the first index of an entry in the table
---@param t table
---@param e any
function M.index(t, e)
    for i, v in ipairs(t) do
        if v == e then
            return i
        end
    end
    return nil
end


-- Treats table like a set; removes all instances of the entry
---@param t table
---@param e any
function M.sub(t, e)
    local i = M.index(t, e)
    local ret = i ~= nil
    while i ~= nil do
        table.remove(t, i)
        i = M.index(t, e)
    end
    return ret
end


-- Treats the table like a set; removes all instances of the entry and inserts it at the beginning
---@param t table
---@param e any
function M.add(t, e)
    M.sub(t, e)
    table.insert(t, 1, e)
end


return M
