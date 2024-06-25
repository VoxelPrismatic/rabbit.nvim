local set = require("rabbit.plugins.util")

---@class Rabbit.Plugin.History.Options
---@field public ignore_unlisted? boolean If true, will ignore unlisted buffers (like Oil)


---@class Rabbit.Plugin.History: Rabbit.Plugin
local M = { ---@type Rabbit.Plugin
    color = "#d08e95",
    name = "history",
    func = {},
    switch = "r",
    listing = {},
    empty_msg = "There's nowhere to jump to! Get started by opening another buffer",
    skip_same = true,
    keys = {},
    evt = {},

    ---@param p Rabbit.Plugin.History
    init = function(p)
        p.listing.last_closed = {}
        p.listing.opened = {}
    end,

    ---@type Rabbit.Plugin.History.Options
    opts = {
        ignore_unlisted = true
    }
}


function M.evt.BufEnter(evt, winid)
    local is_listed = vim.api.nvim_get_option_value("buflisted", { buf = evt.buf })
    if M.opts.ignore_unlisted and not is_listed then
        return
    end
    set.add(M.listing[winid], evt.buf)
    set.add(M.listing.opened, evt.buf)
end


function M.evt.BufDelete(evt, winid)
    set.sub(M.listing[winid], evt.buf)
    set.sub(M.listing.opened, evt.buf)
end


function M.evt.RabbitEnter(_, winid)
    M.listing[0] = nil
    if #M.listing[winid] > 1 then
        return
    end

    if #M.listing.last_closed > 1 then
        M.listing[0] = vim.deepcopy(M.listing.last_closed)
        table.insert(M.listing[0], 1, "rabbitmsg://Restore full history")
        M.listing.last_closed = {}
    elseif #M.listing.opened > 1 then
        M.listing[0] = vim.deepcopy(M.listing.opened)
        table.insert(M.listing[0], 1, "rabbitmsg://Open all buffers")
    end
end


function M.evt.WinClosed(_, winid)
    if M.listing[winid] ~= nil and #M.listing[winid] > 0 then
        M.listing.last_closed = M.listing[winid]
    end
    M.listing[winid] = nil
end


---@param n integer
function M.func.select(n)
    local rabbit = require("rabbit")
    if M.listing[0] == nil or n ~= 1 then
        return rabbit.func.select(n)
    end

    M.listing[0] = rabbit.ctx.listing
    table.remove(M.listing[0], 1)
    M.listing[rabbit.user.win] = M.listing[0]
    vim.api.nvim_win_set_buf(rabbit.user.win, tonumber(M.listing[0][1]) or 0)
    M.listing[0] = nil

    rabbit.func.close()
end


---@param n integer
function M.func.file_del(n)
    local rabbit = require("rabbit")
    M.listing[rabbit.user.win] = rabbit.ctx.listing
    table.remove(M.listing[rabbit.user.win], n)
    table.insert(M.listing[rabbit.user.win], 1, rabbit.user.buf)
    if M.listing[0] ~= nil then
        table.remove(M.listing[rabbit.user.win], 1)
        M.listing[0] = vim.deepcopy(M.listing[rabbit.user.win])
        table.insert(M.listing[0], 1, "rabbitmsg://Restore full history")
    end
    require("rabbit").Redraw()
end


return M
