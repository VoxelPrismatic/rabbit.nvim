local set = require("rabbit.plugins.util")


---@class Rabbit.Plugin.Harpoon.Options
---@field public ignore_opened? boolean Do not display currently open buffers


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

    ---@type Rabbit.Plugin.Harpoon.Options
    opts = {
        ignore_opened = false
    },

    ---@param p Rabbit.Plugin.Harpoon
    init = function(p)
        p.listing[0] = {}
        p.listing.persist = set.clean(set.read(p.memory))
        p.listing.opened = {}
    end,
}

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
    local cwd = vim.fn.getcwd()
    M.listing.persist[cwd] = M.listing.persist[cwd] or {}
    n = math.max(1, math.min(#M.listing[0] + 1, n))

    M.listing.opened[1] = M.listing.opened[1] or vim.api.nvim_buf_get_name(require("rabbit").user.buf)
    if vim.uv.fs_stat(M.listing.opened[1] .. "") == nil then
        return
    end

    set.sub(M.listing.persist[cwd], M.listing.opened[1])
    set.sub(M.listing[0], M.listing.opened[1])
    table.insert(M.listing.persist[cwd], n, M.listing.opened[1])
    table.insert(M.listing[0], n, M.listing.opened[1])
    set.save(M.memory, M.listing.persist)
    require("rabbit").Redraw()
end


---@param n integer
function M.func.file_del(n)
    M.listing[0] = require("rabbit").ctx.listing
    local cwd = vim.fn.getcwd()
    M.listing.opened[1] = M.listing[0][n]
    set.sub(M.listing.persist[cwd], M.listing[0][n])
    set.sub(M.listing[0], M.listing[0][n])
    set.save(M.memory, M.listing.persist)
    require("rabbit").Redraw()
end


---@param winid integer
function M.evt.RabbitEnter(winid)
    M.listing[0] = {}
    local cwd = vim.fn.getcwd()
    M.listing.persist[cwd] = M.listing.persist[cwd] or {}
    for _, v in ipairs(M.listing.persist[cwd]) do
        if not M.opts.ignore_opened or set.index(M.listing[winid], v) == nil then
            table.insert(M.listing[0], v)
        end
    end
end

return M
