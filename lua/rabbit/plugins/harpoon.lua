local set = require("rabbit.plugins.util")


---@class Rabbit.Plugin.Harpoon.Options
---@field public ignore_opened? boolean Do not display currently open buffers
---@field public path_key? string|function:string Scope your working directory


---@class Rabbit.Plugin.Harpoon: Rabbit.Plugin
local M = { ---@type Rabbit.Plugin
    color = "#ff733f",
    name = "harpoon",
    func = {},
    switch = "p",
    listing = {},
    empty_msg = "There's nowhere to jump to! Get started by adding a file",
    skip_same = false,
    keys = {},
    evt = {},
    memory = "",

    _dir = "",

    ---@type Rabbit.Plugin.Harpoon.Options
    opts = {
        ignore_opened = false,
        path_key = nil,
    },

    ---@param p Rabbit.Plugin.Harpoon
    init = function(p)
        p.listing[0] = {}
        p.listing.paths = {}
        p.listing.persist = set.clean(set.read(p.memory))
        p.listing.opened = {}
        p.listing.collections = {}
        p.listing.recursive = nil
    end,

    ctx = {},
}


---@param n integer
function M.func.group(n)
    require("rabbit.input").prompt("Collection name", function(name)
        n = math.max(1, math.min(#M.listing[0] + 1, n))
        if #M.listing.paths[M._dir] > 0 then
            set.add(M.listing[0], "rabbitmsg://#up!\n" .. M._path())
            n = math.max(2, n)
        end

        if string.find(name, "#up!") == 1 then
            vim.print("That's a reserved name!")
            return
        end

        if set.index(M.listing[0], "rabbitmsg://" .. name) ~= nil then
            vim.print("That name already exists!")
            return
        end

        table.insert(M.listing[0], n, "rabbitmsg://" .. name)
        table.insert(M.listing.recursive, n, { name })

        set.save(M.memory, M.listing.persist)
        require("rabbit").Redraw()
    end, function(name)
        if name == "" then
            return false
        end
        if string.find(name, "#up!") == 1 then
            return false
        end
        if set.index(M.listing[0], "rabbitmsg://" .. name) ~= nil then
            return false
        end
        return true
    end)
end


---@param n integer
function M.func.select(n)
    M.listing[0] = require("rabbit").ctx.listing
    vim.print(n)
    if string.find(M.listing[0][n], "rabbitmsg://") ~= 1 then
        vim.print("Not a group")
        return require("rabbit").func.select(n)
    end

    local entry = M.listing[0][n]:sub(#"rabbitmsg://" + 1)

    if string.find(entry, "#up!") == 1 then
        table.remove(M.listing.paths[M._dir], #M.listing.paths[M._dir])
        M.listing.recursive = M.listing.persist[M._dir]
        for _, v in ipairs(M.listing.paths[M._dir]) do
            M.listing.recursive = M.listing.recursive[v]
        end
    else
        table.insert(M.listing.paths[M._dir], n)
        local t = M.listing.recursive[n]
        if type(t) == "table" then
            M.listing.recursive = t
        end
    end

    M._generate()
    if #M.listing.paths[M._dir] > 0 then
        set.add(M.listing[0], "rabbitmsg://#up!\n" .. M._path())
    end
    require("rabbit").Redraw()
end

---@param evt NvimEvent
---@param winid integer
function M.evt.BufEnter(evt, winid)
    if vim.uv.fs_stat(evt.file) == nil then
        return -- Not a local file
    end
    set.add(M.listing[winid], evt.file)
    M.listing.opened[1] = evt.file
end


---@param evt NvimEvent
---@param winid integer
function M.evt.BufDelete(evt, winid)
    set.sub(M.listing[winid], set.index(M.listing[winid], evt.file))
end


---@param n integer
function M.func.file_add(n)
    M.listing[0] = require("rabbit").ctx.listing

    local cur = M.listing.opened[1] or vim.api.nvim_buf_get_name(require("rabbit").user.buf)
    M.listing.opened[1] = cur

    local collection = M.listing.collections[cur]
    if collection == nil and vim.uv.fs_stat(tostring(cur)) == nil then
        return
    end

    set.sub(M.listing.recursive, cur)
    set.sub(M.listing[0], cur)
    n = math.max((#M.listing.paths[M._dir] > 0 and 2 or 1), math.min(#M.listing[0] + 1, n))

    if collection ~= nil then
        for i, v in ipairs(M.listing.recursive) do
            if v[1] == collection[1] then
                table.remove(M.listing.recursive, i)
            end
        end
        table.insert(M.listing.recursive, n, collection)
        table.insert(M.listing[0], n, "rabbitmsg://" .. collection[1])
    else
        table.insert(M.listing.recursive, n, cur)
        table.insert(M.listing[0], n, cur)
    end
    set.save(M.memory, M.listing.persist)
    require("rabbit").Redraw()
end


---@param n integer
function M.func.file_del(n)
    M.listing[0] = require("rabbit").ctx.listing
    local entry = M.listing[0][n]
    if entry == nil then
        return
    end

    if string.find(entry, "#up!") == #"rabbitmsg://" then
        vim.print("That's a reserved name!")
        return
    end

    set.sub(M.listing[0], entry)
    if string.find(entry, "rabbitmsg://") == 1 then
        local t = M.listing.recursive[n]
        if type(t) == "table" then
            M.listing.collections[entry] = vim.deepcopy(t)
            M.listing.opened[1] = entry
        end

        table.remove(M.listing.recursive, n)
    else
        set.sub(M.listing.recursive, entry)
        M.listing.opened[1] = entry
    end

    set.save(M.memory, M.listing.persist)
    require("rabbit").Redraw()
end


---@param winid integer
function M.evt.RabbitEnter(evt, winid)
    M.listing.opened[1] = nil
    M.ctx.winid = winid

    if M.listing.persist[evt.match] == nil then
        M.listing.persist[evt.match] = {}
    end

    if M.listing.recursive == nil then
        M.listing.persist[evt.match] = M.listing.persist[evt.match] or {}
        M.listing.recursive = M.listing.persist[evt.match]
    end

    if M.listing.paths[evt.match] == nil then
        M.listing.paths[evt.match] = {}
    end

    if M._dir ~= evt.match then
        M._dir = evt.match
        M.listing.recursive = M.listing.persist[evt.match]
        for _, v in ipairs(M.listing.paths[M._dir]) do
            M.listing.recursive = M.listing.recursive[v]
        end
    end

    M._generate()

    if #M.listing.paths[evt.match] > 0 then
        table.insert(M.listing[0], 1, "rabbitmsg://#up!\n" .. M._path())
    end
end


function M._generate()
    M.listing[0] = {}
    for i, v in pairs(M.listing.recursive) do
        if i == 1 and #M.listing.paths[M._dir] > 0 then
            -- pass
        elseif type(v) == "table" then
            table.insert(M.listing[0], "rabbitmsg://" .. v[1])
        elseif not M.opts.ignore_opened or set.index(M.listing[M.ctx.winid], v) == nil then
            table.insert(M.listing[0], v)
        end
    end
end


---Returns the collection path
---@return string string
function M._path()
    local s = (#M.listing.paths[M._dir] > 3 and require("rabbit").opts.window.overflow or "~")
    local recur = M.listing.persist[M._dir]
    local l = require("rabbit").opts.window.path_len
    for i = 1, #M.listing.paths[M._dir] do
        recur = recur[M.listing.paths[M._dir][i]]
        if i > #M.listing.paths[M._dir] - 3 then
            local a = recur[1]
            if #a > l then
                a = a:sub(1, l - 1) .. "…"
            end
            s = s .. "/" .. a
        end
    end
    return s
end


function M.func.group_up()
    if #M.listing.paths[M._dir] > 0 then
        M.func.select(1)
    end
end

return M
