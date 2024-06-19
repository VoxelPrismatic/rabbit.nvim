local M = {
    attached = {
        "BufEnter",
        "BufDelete",
        "BufUnload",
        "WinClosed",
        "WinResized",
        "WinEnter",
        "RabbitEnter",
    }
}


---@param rabbit Rabbit.Instance
function M.attach(rabbit)
    vim.api.nvim_create_autocmd("BufEnter", {
        pattern = {"*"},
        callback = rabbit.autocmd
    })


    vim.api.nvim_create_autocmd("BufDelete", {
        pattern = {"*"},
        callback = function(evt)
            rabbit.autocmd(evt)
            if rabbit.rabbit.win ~= nil then
                rabbit.Redraw()
            end
        end
    })


    vim.api.nvim_create_autocmd("BufUnload", {
        pattern = {"*"},
        callback = function(_)
            if rabbit.rabbit.win ~= nil then
                rabbit.Redraw()
            end
        end
    })


    vim.api.nvim_create_autocmd("WinClosed", {
        pattern = {"*"},
        callback = function(evt)
            local w = tonumber(evt.file) or -2
            for k, _ in pairs(rabbit.plugins) do
                local p = rabbit.plugins[k] ---@type Rabbit.Plugin
                if p.evt.WinClosed ~= nil then
                    p.evt.WinClosed(evt, w)
                else
                    p.listing[w] = nil
                end
            end
        end,
    })


    vim.api.nvim_create_autocmd("WinResized", {
        pattern = {"*"},
        callback = function()
            if rabbit.rabbit.win ~= nil then
                rabbit.Switch(rabbit.ctx.plugin.name)
            end
        end
    })


    vim.api.nvim_create_autocmd("WinEnter", {
        pattern = {"*"},
        callback = function()
            rabbit.ensure_listing(vim.api.nvim_get_current_win())
        end
    })
end


return M
