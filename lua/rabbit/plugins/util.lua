local M = {}

-- Find the first index of an entry in the table
---@param t table
---@param e any
---@return integer | nil The index, or nil if not found
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
---@return boolean If anything was removed
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


-- Removes references to deleted files and folders
---@param tbl Rabbit.Plugin.Listing.Persist
---@return Rabbit.Plugin.Listing.Persist
function M.clean(tbl)
    for dir, ls in pairs(tbl) do
        local stat = vim.uv.fs_stat(dir)
        if stat == nil or stat.type == "file" then
            tbl[dir] = nil
            goto continue
        end

        M.clean_recursive(ls)

        ::continue::
    end
    return tbl
end

-- Removes references to deleted files and folders
---@param tbl Rabbit.Plugin.Listing.Persist.Table
---@return Rabbit.Plugin.Listing.Persist.Table
function M.clean_recursive(tbl)
    for key, file in pairs(tbl) do
        if type(key) == "number" and file == vim.NIL then
            table.remove(tbl, key)
        elseif type(key) == "number" and type(file) == "table" then
            local name = file[1]
            M.clean_recursive(file)
            table.insert(file, 1, name)
        elseif type(key) == "number" and vim.uv.fs_stat(file) == nil then
            table.remove(tbl, key)
        elseif type(key) == "table" then
            local name = key.__name__
            M.clean_recursive(key)
            key.__name__ = name
        elseif type(key) == "string" and vim.uv.fs_stat(key) == nil then
            if type(tbl.age) == "number" and type(tbl.count) == "number" then
                tbl[key] = nil
            end
        end
    end
    return tbl
end

return M
