local screen = require("rabbit.screen")
local defaults = require("rabbit.defaults")

---@class rabbit
---@field opts RabbitOptions
---@field history RabbitHistory
---@field winid winnr winnr
---@field rabid winnr winnr
local rabbit = {
    rabid = nil,
    winid = 0,
    opts = defaults.options,
    history = {}
}


-- Expand a table, like js { ...obj, b = 1, c = 2 }
---@param template table
---@return fun(table: table): table
local function spread(template)
    local result = {}
    for key, value in pairs(template) do
        result[key] = value
    end

    return function(table)
        for key, value in pairs(table) do
            result[key] = value
        end
        return result
    end
end


-- Display a message in the buffer
---@param buf bufnr bufnr
---@param text string
function rabbit.ShowMessage(buf, text)
    local line = 2
    local thisline = ""
    for word in text:gmatch("[^ ]+") do
        if #thisline + #word > rabbit.opts.window.width - 4 then
            screen.render(rabbit.rabid, buf, line, {
                { color = rabbit.opts.color.box, text = rabbit.opts.box.vertical .. " " },
                { color = rabbit.opts.color.file, text = thisline },
                { color = rabbit.opts.color.box, text = rabbit.opts.box.vertical, expand = true },
            })
            line = line + 1
            thisline = ""
        end
        thisline = thisline .. word .. " "
    end

    if #thisline > 1 then
        screen.render(rabbit.rabid, buf, line, {
            { color = rabbit.opts.color.box, text = rabbit.opts.box.vertical .. " " },
            { color = rabbit.opts.color.file, text = thisline },
            { color = rabbit.opts.color.box, text = rabbit.opts.box.vertical, expand = true },
        })
    end
end


-- Return the relative path between two paths
---@param source filepath
---@param target filepath
---@return { dir: string, name: string }
function rabbit.RelPath(source, target)
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

    if distance == 0 and #source_parts == #target_parts then
        return { dir = "", name = final }
    elseif distance == 0 and #target_parts - #source_parts > rabbit.opts.paths.min_visible then
        ret = rabbit.opts.paths.overflow .. "/"
    elseif distance < rabbit.opts.paths.min_visible then
        ret = ("."):rep(distance + 1) .. "/"
    else
        ret = rabbit.opts.paths.overflow .. "/"
    end


    for i = math.max(shared_parts + 1, #target_parts - rabbit.opts.paths.min_visible), #target_parts - 1 do
        ret = ret .. target_parts[i]:sub(1, rabbit.opts.paths.rollover) ..
            (#(target_parts[i]) > rabbit.opts.paths.rollover and "…" or "") .. "/"
    end

    return {
        dir = ret,
        name = target_parts[#target_parts],
    }
end


function rabbit.Close()
    if rabbit.rabid ~= nil then
        vim.api.nvim_win_close(rabbit.rabid, true)
        rabbit.rabid = nil
    end
end


function rabbit.Select(lineno)
    if lineno <= 1 then
        lineno = 2 -- Index 1 is the current buffer
    else
        lineno = lineno + 1
    end
    if rabbit.rabid ~= nil then
        pcall(vim.api.nvim_win_close, rabbit.rabid, true)
        rabbit.rabid = nil
    end

    if rabbit.winid == nil then
        rabbit.winid = vim.fn.win_getid()
    end

    if rabbit.history[rabbit.winid] == nil then
        rabbit.history[rabbit.winid] = {}
    end

    if lineno >= 1 and lineno <= #(rabbit.history[rabbit.winid]) then
        vim.cmd("b " .. rabbit.history[rabbit.winid][lineno])
    end
end


function rabbit.Window()
    if rabbit.rabid ~= nil then
        local status, _ = pcall(vim.api.nvim_win_close, rabbit.rabid, true)
        rabbit.rabid = nil

        -- Continue if the window managed to close without us noticing
        if status == true then return end
    end

    rabbit.winid = vim.api.nvim_get_current_win()
    if rabbit.history[rabbit.winid] == nil then
        rabbit.history[rabbit.winid] = {}
    end

    local buf = vim.api.nvim_create_buf(false, true) ---@type bufnr

    local opts = {
        relative = "editor",
        width = rabbit.opts.window.width,
        height = rabbit.opts.window.height,
        col = 10000,
        row = 10000,
        style = "minimal",
    }

    rabbit.rabid = vim.api.nvim_open_win(buf, true, opts)

    local center = (rabbit.opts.window.width - 2 - #(rabbit.opts.window.title)) / 2 - 1
    local emph_width = math.min(center - 4, rabbit.opts.window.emphasis_width)
    center = center - emph_width


    screen.render(rabbit.rabid, buf, 0, {
        {
            color = rabbit.opts.color.box,
            text = {
                rabbit.opts.box.top_left,
                rabbit.opts.box.horizontal:rep(center),
                rabbit.opts.box.emphasis:rep(emph_width)
            },
        },
        {
            color = rabbit.opts.color.title,
            text = " " .. rabbit.opts.window.title .. " ",
        },
        {
            color = rabbit.opts.color.box,
            text = {
                rabbit.opts.box.emphasis:rep(emph_width),
                rabbit.opts.box.horizontal:rep(center),
                rabbit.opts.box.top_right,
            },
        },
    })

    screen.render(rabbit.rabid, buf, 1, {{
        color = rabbit.opts.color.box,
        text = {
            rabbit.opts.box.vertical,
            (" "):rep(rabbit.opts.window.width - 2),
            rabbit.opts.box.vertical,
        }
    }})

    local window_bufs = rabbit.history[rabbit.winid]
    local has_name, buf_path = pcall(vim.api.nvim_buf_get_name, window_bufs[1])
    if not has_name then
        buf_path = ""
    end

    for i = 1, rabbit.opts.window.height - 4 do
        ---@type ScreenSpec[]
        local parts = {{ color = rabbit.opts.color.box, text = rabbit.opts.box.vertical .. " " }}

        if i < #window_bufs then
            if i <= 10 then
                vim.api.nvim_buf_set_keymap(
                    buf, "n", ("" .. i):sub(-1), "<cmd>lua require('rabbit').Select(" .. i .. ")<CR>",
                    { noremap = true, silent = true }
                )
            end
            local valid = vim.api.nvim_buf_is_valid(window_bufs[i + 1])
            while not valid do
                table.remove(window_bufs, i + 1)
                if #window_bufs == 1 then
                    vim.print("KILL")
                    break
                end
                valid = vim.api.nvim_buf_is_valid(window_bufs[i + 1])
            end

            if not valid then
                break
            end

            local target = vim.api.nvim_buf_get_name(window_bufs[i + 1])
            if target ~= "" then
                local rel = rabbit.RelPath(buf_path, vim.fn.fnamemodify(target, ":p"))
                table.insert(parts, {
                    { text = (i < 10 and " " or "") .. i .. ". ", color = rabbit.opts.color.index },
                    { text = rel.dir, color = rabbit.opts.color.dir },
                    { text = rel.name, color = rabbit.opts.color.file, }
                })
            else
                table.insert(parts, {
                    { text = (i < 10 and " " or "") .. i .. ". ", color = rabbit.opts.color.index },
                    { text = "#nil " .. window_bufs[i + 1], color = rabbit.opts.color.noname }
                })
            end
        end

        table.insert(parts, {
            color = rabbit.opts.color.box,
            text = rabbit.opts.box.vertical,
            expand = true,
        })

        screen.render(rabbit.rabid, buf, i + 1, parts)
    end

    if #window_bufs <= 1 then
        rabbit.ShowMessage(buf, "There's nowhere else to jump to! Get started by opening another buffer")
    end

    screen.render(rabbit.rabid, buf, rabbit.opts.window.height - 2, {{
        color = rabbit.opts.color.box,
        text = {
            rabbit.opts.box.vertical,
            (" "):rep(rabbit.opts.window.width - 2),
            rabbit.opts.box.vertical,
        }
    }})

    screen.render(rabbit.rabid, buf, rabbit.opts.window.height - 1, {{
        color = rabbit.opts.color.box,
        text = {
            rabbit.opts.box.bottom_left,
            rabbit.opts.box.horizontal:rep(rabbit.opts.window.width - 2),
            rabbit.opts.box.bottom_right,
        },
    }})

    local close_keys = { "<Esc>", "<leader>", "q" }
    for _, key in ipairs(close_keys) do
        vim.api.nvim_buf_set_keymap(
            buf, "n", key, "<cmd>lua require('rabbit').Close()<CR>",
            { noremap = true, silent = true }
        )
    end

    vim.api.nvim_buf_set_keymap(
        buf, "n", "<CR>", "<cmd>lua require('rabbit').Select(vim.fn.line('.') - 2)<CR>",
        { noremap = true, silent = true, }
    )

    vim.api.nvim_create_autocmd("WinLeave", { buffer = buf, callback = rabbit.Close })
    vim.api.nvim_create_autocmd("BufLeave", { buffer = buf, callback = rabbit.Close })
    vim.api.nvim_create_autocmd("WinClosed", { buffer = buf, callback = rabbit.Close })
    vim.api.nvim_create_autocmd("InsertEnter", { buffer = buf, callback = rabbit.Close })
end


vim.api.nvim_create_autocmd("BufEnter", {
    pattern = {"*"},
    callback = function(evt)
        local winid = vim.fn.win_getid()

        if #(evt.file) > 1 and evt.file:sub(1, 1) ~= "/" then
            return
        end

        if rabbit.history[winid] == nil then
            rabbit.history[winid] = {}
        end

        -- Remove duplicates
        for i = 1, #(rabbit.history[winid]) do
            if rabbit.history[winid][i] == evt.buf then
                table.remove(rabbit.history[winid], i)
                break
            end
        end
        table.insert(rabbit.history[winid], 1, evt.buf)
    end,
})


vim.api.nvim_create_autocmd("BufDelete", {
    pattern = {"*"},
    callback = function(evt)
        local winid = vim.fn.win_getid()

        if rabbit.history[winid] == nil then
            rabbit.history[winid] = {}
            return
        end
        for i = 1, #(rabbit.history[winid]) do
            if rabbit.history[winid][i] == evt.buf then
                table.remove(rabbit.history[winid], i)
                return
            end
        end
    end,
})


vim.api.nvim_create_autocmd("WinClosed", {
    pattern = {"*"},
    callback = function(evt)
        rabbit.history[evt.file] = nil
    end,
})


---@param opts RabbitOptions | string
function rabbit.setup(opts)
    rabbit.history[vim.fn.win_getid()] = {}

    if type(opts) == "string" then
        opts = { keys = { open = { opts } } }
    end

    for key, _ in pairs(rabbit.opts) do
        if key ~= "box" and opts[key] ~= nil then
            rabbit.opts[key] = spread(rabbit.opts[key])(opts[key])
        end
    end

    if opts.box ~= nil then
        if type(opts.box) == "string" then
            rabbit.opts.box = defaults.box[opts.box] or defaults.box.square
        else
            rabbit.opts.box = spread(defaults.box.square)(opts.box)
        end
    end

    for _, key in ipairs(rabbit.opts.keys.open) do
        vim.keymap.set("n", key, rabbit.Window, {
            desc = "Open Rabbit",
            noremap = true,
            silent = true
        })
    end
end

return rabbit
