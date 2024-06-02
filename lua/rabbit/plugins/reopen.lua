local set = require("rabbit.plugins.util")

---@type Rabbit.Plugin
local M = {
    color = "#907aa9",
    name = "reopen",
    func = {},
    switch = "o",
    listing = {},
    empty_msg = "There's no buffer to reopen! Get started by closing a buffer",
    skip_same = true,
    keys = {},
    evt = {},
    init = function(_) end,
}

---@param evt NvimEvent
---@param winid integer
function M.evt.BufEnter(evt, winid)
    set.sub(M.listing[winid], evt.file)
end


---@param evt NvimEvent
---@param winid integer
function M.evt.BufDelete(evt, winid)
    if #evt.file > 0 and evt.file:sub(1, 1) == "/" then
        set.add(M.listing[winid], evt.file)
    end
end

return M
