local set = require("rabbit.plugins.util")

---@type RabbitPlugin
---@class RabbitOxide
local M = {
    color = "#c4a7e7",
    name = "oxide",
    func = {},
    switch = "x",
    listing = {},
    empty_msg = "There's nothing to recover!",
    skip_same = false,
    keys = {},
    evt = {},
    memory = "",
    opts = { ---@type RabbitOxideOpts
        maxage = 1000
    },
    init = function(p) ---@param p RabbitOxide
        p.listing[0] = {}
        p.listing[1] = set.read(p.memory)
        p.listing[2] = {}
    end
}


---@class RabbitOxideListing
---@field [0] RabbitPluginWinListing Listing shown in Rabbit Oxide plugin
---@field [1] RabbitOxideFreqListing Oxide internal listing
---@field [2] RabbitPluginWinListing Tracks open files to prevent increasing score when moving between buffers


---@class RabbitOxideOpts
---@field maxage integer Like zoxide's AGING algorithm


---@class RabbitOxideFreqListing
---@field [string] table<string, RabbitOxideEntry> Name:Entry table


---@class RabbitOxideEntry
---@field age integer The last time the file was accessed
---@field count integer The total number of times this file was accessed


---@class QuickSortEntry
---@field name string Context name; untouched
---@field score integer Score


---@param arr RabbitOxideFreqListing
---@return RabbitOxideFreqListing, string[]
local function quickscore(arr, maxage)
    local ret = {} ---@type QuickSortEntry[]
    local time = os.time()
    local cwd = vim.fn.getcwd()
    local sum = 0
    for k, _ in pairs(arr) do
        local v = arr[k][cwd] ---@type RabbitOxideEntry
        if v == nil then
            -- Never opened this file from current directory
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
                arr[v.name][cwd] = nil
            end
        end
    end

    if maxage == M.opts.maxage then
        table.sort(ret, function(a, b) return a.score > b.score end)
    end

    local names = {}
    for _, v in ipairs(ret) do
        table.insert(names, v.name)
    end
    return arr, names
end



function M.evt.RabbitEnter()
    M.listing[1], M.listing[0] = quickscore(M.listing[1], M.opts.maxage)
end


---@param evt NvimEvent
function M.evt.BufEnter(evt, _)
    if #evt.file == 0 or evt.file:sub(1, 1) ~= "/" then
        return -- Not a local file
    end

    if set.index(M.listing[2], evt.file) then
        return -- Already opened
    end

    local entry = M.listing[1][evt.file] ---@type table<string, RabbitOxideEntry>
    local cwd = vim.fn.getcwd()
    if entry == nil then
        entry = { [cwd] = { age = 0, count = 0 } }
    elseif entry[cwd] == nil then
        entry[cwd] = { age = 0, count = 0 }
    end

    entry[cwd].age = os.time()
    entry[cwd].count = entry[cwd].count + 1
    M.listing[1][evt.file] = entry

    set.save(M.memory, M.listing[1])
end


---@param evt NvimEvent
function M.evt.BufDelete(evt, _)
    set.sub(M.listing[2], evt.file)
end


---@param ln integer Current entry number
function M.func.file_del(ln)
    local arr = require("rabbit").ctx.listing ---@type string[]
    local filename = arr[ln]
    if filename == nil or M.listing[1][filename] == nil then
        return
    end
    local entry = M.listing[1][filename] ---@type RabbitOxideEntry
    entry[vim.fn.getcwd()] = nil
    require("rabbit").Redraw()
end

return M
