local set = require("rabbit.plugins.util")

---@type Rabbit.Plugin
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
}

---@param evt NvimEvent
---@param winid integer
function M.evt.BufEnter(evt, winid)
    set.add(M.listing[winid], evt.buf)
end


---@param evt NvimEvent
---@param winid integer
function M.evt.BufDelete(evt, winid)
    set.sub(M.listing[winid], evt.buf)
end

return M
