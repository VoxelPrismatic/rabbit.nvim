local set = require("rabbit.plugins.util")

---@class Rabbit.Plugin.History.Options
---@field public ignore_unlisted? boolean If true, will ignore unlisted buffers (like Oil)


---@type Rabbit.Plugin
---@class Rabbit.Plugin.History
---@field opts Rabbit.Plugin.History.Options
local M = {
    color = "#d7827e",
    name = "history",
    func = {},
    switch = "r",
    listing = {},
    empty_msg = "There's nowhere to jump to! Get started by opening another buffer",
    skip_same = true,
    keys = {},
    evt = {},
    init = function(_) end,
    opts = {
        ignore_unlisted = false
    }
}

---@param evt NvimEvent
---@param winid integer
function M.evt.BufEnter(evt, winid)
    if M.opts.ignore_unlisted and not vim.fn.getbufinfo(evt.buf)[1].listed then
        return
    end
    set.add(M.listing[winid], evt.buf)
end


---@param evt NvimEvent
---@param winid integer
function M.evt.BufDelete(evt, winid)
    set.sub(M.listing[winid], evt.buf)
end

return M
