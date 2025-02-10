local set = require("rabbit.plugins.util")


---@class Rabbit.Plugin.Oxide.Options
---@field public maxage? integer Like zoxide's AGING algorithm
---@field public ignore_opened? boolean Do not display currently open buffers
---@field public path_key? string|function:string Scope your working directory


---@class QuickSortEntry
---@field name string Context name; untouched
---@field score integer Score


---@class Rabbit.Plugin.Oxide: Rabbit.Plugin
local M = { ---@type Rabbit.Plugin
    color = "#8aaacd",
    name = "oxide",
    func = {},
    switch = "x",
    listing = {},
    empty_msg = "There's nothing to recover!",
    skip_same = false,
    keys = {},
    evt = {},
    memory = "",

    ---@type Rabbit.Plugin.Oxide.Options
    opts = {
        maxage = 1000,
        ignore_opened = true,
        path_key = nil,
    },

    ---@param p Rabbit.Plugin.Oxide
    init = function(p)
        p.listing[0] = {}
        p.listing.persist = set.clean(set.read(p.memory))
    end
}


---@param arr Rabbit.Plugin.Listing.Persist.Table
---@return Rabbit.Plugin.Listing.Persist.Table, string[]
local function quickscore(arr, maxage)
    local ret = {} ---@type QuickSortEntry[]
    local time = os.time()
    local sum = 0
    for k, _ in pairs(arr or {}) do
        local v = arr[k] ---@type Rabbit.Plugin.Listing.Persist.Entry
        if vim.uv.fs_stat(k) == nil then
            arr[k] = nil
            goto continue
        end

        local score = v.count
        local diff = time - v.age

        if diff < 3600 then         -- Within the last hour
            score = score * 4
        elseif diff < 86400 then    -- Within the last day
            score = score * 2
        elseif diff < 604800 then   -- Within the last week
            score = score / 2
        else
            score = score / 4
        end

        sum = sum + score
        ret[#ret + 1] = {
            name = k,
            score = score,
        }
        ::continue::
    end

    if sum > maxage then
        local clip = (maxage * 0.9) / sum
        for i, v in ipairs(ret) do
            ret[i].score = v.score * clip
            if ret[i].score < 1 then
                table.remove(ret, i)
                arr[v.name] = nil
            end
        end
    end

    if maxage == M.opts.maxage then
        table.sort(ret, function(a, b) return a.score > b.score end)
    end

    local names = {}
    local winid = require("rabbit").user.win
    for _, v in ipairs(ret) do
        if not M.opts.ignore_opened or set.index(M.listing[winid], v.name) == nil then
            table.insert(names, v.name)
        end
    end
    return arr, names
end


function M.evt.RabbitEnter(evt)
    M.listing.persist[evt.match], M.listing[0] = quickscore(M.listing.persist[evt.match], M.opts.maxage)
    set.save(M.memory, M.listing.persist)
end


function M.evt.BufEnter(evt, winid)
    if vim.uv.fs_stat(evt.file) == nil then
        return -- Not a local file
    elseif set.index(M.listing[winid], evt.file) then
        return -- Already opened
    end

    table.insert(M.listing[winid], evt.file)

    local cwd = require("rabbit").path_key_fallback(M)
    local entry = M.listing.persist[cwd] ---@type Rabbit.Plugin.Listing.Persist.Table

    if entry == nil then
        entry = { [evt.file] = { age = 0, count = 0 } }
    elseif entry[evt.file] == nil then
        entry[evt.file] = { age = 0, count = 0 }
    end

    entry[evt.file].age = os.time()
    entry[evt.file].count = entry[evt.file].count + 1
    M.listing.persist[cwd] = entry

    set.save(M.memory, M.listing.persist)
end


function M.evt.BufDelete(evt, winid)
    set.sub(M.listing[winid], evt.file)
end


function M.evt.RabbitInvalid(evt, _)
    set.sub(M.listing.persist[require("rabbit").path_key_fallback(M)], evt.file)
    set.save(M.memory, M.listing.persist)
end


function M.evt.RabbitFileRename(evt, _)
    for dir, _ in pairs(M.listing.persist) do
        local ls = M.listing.persist[dir] ---@type Rabbit.Plugin.Listing.Persist.Table
        for k, v in pairs(ls) do
            if k == evt.match then
                ls[evt.file] = v
                ls[k] = nil
            end
        end
    end
    set.save(M.memory, M.listing.persist)
end


---@param ln integer Current entry number
function M.func.file_del(ln)
    local arr = require("rabbit").ctx.listing ---@type string[]
    local filename = arr[ln]
    local cwd = require("rabbit").path_key_fallback(M)
    if filename == nil or M.listing.persist[cwd][filename] == nil then
        return
    end
    M.listing.persist[cwd][filename] = nil
    table.remove(M.listing[0], ln)
    require("rabbit").Redraw()
end


return M
