local set = require("rabbit.plugins.util")

---@type Rabbit.Plugin
local M = {
    color = "#907aa9",
    name = "reopen",
    func = {},
    switch = "o",
    listing = {},
    empty_msg = "There's no buffer to reopen! Get started by closing a buffer",
    skip_same = false,
    keys = {},
    evt = {},
    init = function(p) ---@param p Rabbit.Plugin
        p.listing[0] = {}
    end,
}

---@param evt NvimEvent
function M.evt.BufEnter(evt, _)
    set.index(M.listing[0], evt.file)
    set.add(M.listing[0], evt.buf)
end

return M
