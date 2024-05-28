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

-- Tries to read the file as a table. Returns {} if it fails
---@param s string File name
---@return table
function M.read(s)
    local f = io.open(s, "r")
    if f == nil then
        return {}
    end

    local serial = f:read("*a")
    f:close()

    local status, tbl = pcall(vim.fn.json_decode, serial)
    if not status then
        return {}
    end
    return tbl
end


-- Saves the table to a file
---@param s string File name
---@param tbl table Table to save
---@return boolean If the save was successful
function M.save(s, tbl)
    local f = io.open(s, "w+")
    if f == nil then
        return false
    end
    local status, serial = pcall(vim.fn.json_encode, tbl)
    if not status then
        f:close()
        return false
    end
    f:write(serial)
    f:close()
    return true
end

return M
