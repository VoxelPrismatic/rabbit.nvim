local box_lines = {
    tl = "╭",
    bl = "╰",
    tr = "╮",
    br = "╯",
    h = "─",
    v = "│",
}

Rabbit = {
    rabid = nil,
    winid = nil,
    history = {}
}


function Rabbit.RelPath(source, target)
    local source_parts = {}
    for part in source:gmatch("[^/]+") do
        table.insert(source_parts, part)
    end

    local target_parts = {}
    for part in target:gmatch("[^/]+") do
        table.insert(target_parts, part)
    end

    local shared_parts = 0
    for i = 1, math.min(#source_parts, #target_parts) do
        if source_parts[i] == target_parts[i] then
            shared_parts = shared_parts + 1
        else
            break
        end
    end

    local distance = #source_parts - shared_parts - 1
    local ret = ""
    local final = target_parts[#target_parts]

    vim.print(distance .. "|" .. final)
    if distance < 0 and #source_parts ~= #target_parts then
        ret = "./"
    elseif distance == 0 and #source_parts == #target_parts then
        return final
    elseif distance < 3 then
        ret = ("."):rep(distance + 1) .. "/"
    else
        ret = ":::/"
    end

    for i = math.max(shared_parts + 1, #target_parts - 3), #target_parts do
        ret = ret .. target_parts[i] .. "/"
    end

    return ret:sub(1, -2)
end


function Rabbit.Close()
    if Rabbit.rabid ~= nil then
        vim.api.nvim_win_close(Rabbit.rabid, true)
        Rabbit.rabid = nil
    end
end


function Rabbit.Select(lineno)
    if lineno <= 1 then
        lineno = 2 -- Index 1 is the current buffer
    else
        lineno = lineno + 1
    end
    vim.api.nvim_win_close(Rabbit.rabid, true)
    if lineno >= 1 and lineno <= #(Rabbit.history[Rabbit.winid]) then
        vim.cmd("b " .. Rabbit.history[Rabbit.winid][lineno])
    end
    Rabbit.rabid = nil
end


function Rabbit.Window()
    if Rabbit.rabid ~= nil then
        vim.api.nvim_win_close(Rabbit.rabid, true)
        Rabbit.rabid = nil
        return
    end

    local width = 64
    local height = 24

    Rabbit.winid = vim.api.nvim_get_current_win()
    if #(Rabbit.history[Rabbit.winid]) <= 1 then
        vim.print("There's nowhere to jump to!")
        return
    end


    local buf = vim.api.nvim_create_buf(false, true)
    local ui = vim.api.nvim_list_uis()[1]

    local opts = {
        relative = "editor",
        width = width,
        height = height,
        col = ui.width - width - 1,
        row = ui.height - height - 1,
        style = "minimal",
    }

    Rabbit.rabid = vim.api.nvim_open_win(buf, true, opts)

    local title = " Rabbit "
    local center = (width - 2 - #title) / 2
    local titlebar = box_lines.h:rep(center) .. title .. box_lines.h:rep(center)
    local top_border = box_lines.tl .. titlebar .. box_lines.tr
    local bot_border = box_lines.bl .. box_lines.h:rep(width - 2) .. box_lines.br
    local mid_border = box_lines.v .. string.rep(" ", width - 2) .. box_lines.v
    local border = { top_border, mid_border }

    local window_bufs = Rabbit.history[Rabbit.winid]

    local buf_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(window_bufs[1]), ":p")

    for i = 1, height - 4 do
        local line = box_lines.v .. " "
        if i < #window_bufs then
            if i <= 10 then
                vim.api.nvim_buf_set_keymap(
                    buf, "n", ("" .. i):sub(-1), "<cmd>lua Rabbit.Select(" .. i .. ")<CR>",
                    { noremap = true, silent = true }
                )
            end
            line =  line .. (i < 10 and " " or "") .. i .. ". "
            local trg_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(window_bufs[i + 1]), ":p")
            line = line .. Rabbit.RelPath(buf_path, trg_path)
        end

        line = line .. string.rep(" ", width - #line) .. " " .. box_lines.v
        border[#border + 1] = line

    end
    border[#border + 1] = mid_border
    border[#border + 1] = bot_border

    -- Neovim stuck at Lua 5.1
    ---@diagnostic disable-next-line: deprecated
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, border)

    local close_keys = {
        "<Esc>", "<leader>", "q",
    }

    for _, key in ipairs(close_keys) do
        vim.api.nvim_buf_set_keymap(
            buf, "n", key, "<cmd>lua Rabbit.Close()<CR>",
            { noremap = true, silent = true }
        )
    end

    vim.api.nvim_buf_set_keymap(
        buf, "n", "<CR>", "<cmd>lua Rabbit.Select(vim.fn.line('.') - 2)<CR>",
        {
            noremap = true,
            silent = true,
        }
    )

    vim.api.nvim_create_autocmd("WinLeave", {
        buffer = buf,
        callback = Rabbit.Close
    })

    vim.api.nvim_create_autocmd("WinClosed", {
        buffer = buf,
        callback = Rabbit.Close
    })
end

vim.api.nvim_create_autocmd("BufEnter", {
    pattern = {"*"},
    callback = function(evt)
        if evt.file:sub(1, 1) ~= "/" then
            -- vim.print(evt.file)
            return
        end

        local winid = vim.fn.win_getid()

        if Rabbit.history[winid] == nil then
            Rabbit.history[winid] = {}
        end

        -- Remove duplicates
        for i = 1, #(Rabbit.history[winid]) do
            if Rabbit.history[winid][i] == evt.buf then
                table.remove(Rabbit.history[winid], i)
                break
            end
        end
        table.insert(Rabbit.history[winid], 1, evt.buf)
        -- vim.print(buf_history)
    end,
})

vim.api.nvim_create_autocmd("BufDelete", {
    pattern = {"*"},
    callback = function(evt)
        for i = 1, #Rabbit.history do
            if Rabbit.history[i] == evt.buf then
                table.remove(Rabbit.history, i)
                return
            end
        end
    end,
})

vim.api.nvim_create_autocmd("WinClosed", {
    pattern = {"*"},
    callback = function(evt)
        table.remove(Rabbit.history, evt.file)
    end,
})

vim.keymap.set("n", "<leader>r", "<cmd>lua Rabbit.Window()<CR>", {
    desc = "Jump to last buffer",
    noremap = true,
    silent = true,
})

return {}
