local screen = require("rabbit.screen")
local defaults = require("rabbit.defaults")

function table.set_subtract(t1, e)
    for i, v in ipairs(t1) do
        if v == e then
            table.remove(t1, i)
            return true
        end
    end
    return false
end

function table.set_insert(t1, e)
    table.set_subtract(t1, e)
    table.insert(t1, 1, e)
end

---@class rabbit
---@field opts RabbitOptions
---@field listing RabbitListing
---@field rab RabbitWS
---@field usr RabbitWS
---@field ctx RabbitContext
local rabbit = {
    rab = {
        win = nil,
        buf = nil,
        ns = vim.api.nvim_create_namespace("rabbit"),
    },

    ctx = {
        border_color = "Function",
        listing = {},
        mode = "history",
    },

    usr = {
        win = nil,
        buf = nil,
        ns = nil,
    },

    opts = defaults.options,

    listing = {
        history = {},
        reopen = {},
    },

    messages = {
        history = "There's nowhere to jump to! Get started by opening another buffer",
        reopen = "There's no buffer to reopen! Get started by closing a buffer",
        __default__ = "There's nothing to do! Also, be sure to add a custom message for this plugin",
    },

    autocmd = {},
}

-- Expand a table, like js { ...obj, b = 1, c = 2 }
---@param template table
---@return fun(table: table): table
local function spread(template)
    return function(table)
        return vim.tbl_extend("force", template, table)
    end
end


-- Display a message in the buffer
---@param text string
function rabbit.ShowMessage(text)
    screen.display_message(text)
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
    if rabbit.rab.win ~= nil then
        if rabbit.rab.win == rabbit.usr.win then
            vim.api.nvim_win_set_buf(rabbit.usr.win, rabbit.usr.buf)
        else
            vim.api.nvim_win_close(rabbit.rab.win, true)
            vim.api.nvim_tabpage_set_win(0, rabbit.usr.win) -- For splits
        end
        rabbit.rab.win = nil
    end
end


function rabbit.Select(lineno)
    lineno = math.max(lineno, 1)

    if rabbit.rab.win ~= nil then
        if rabbit.rab.win == rabbit.usr.win then
            vim.api.nvim_win_set_buf(rabbit.usr.win, rabbit.usr.buf)
            vim.api.nvim_win_set_hl_ns(rabbit.usr.win, rabbit.usr.ns)
        else
            pcall(vim.api.nvim_win_close, rabbit.rab.win, true)
        end
        rabbit.rab.win = nil
    end

    if rabbit.usr.win == nil then
        rabbit.usr.win = vim.fn.win_getid()
    end

    if lineno >= 1 and lineno <= #(rabbit.ctx.listing) then
        local b = rabbit.ctx.listing[lineno]
        if type(b) == "string" then
            b = vim.cmd.edit(b)
        else
            vim.api.nvim_win_set_buf(rabbit.usr.win, b)
        end
    end
end


---@param winid winnr
function rabbit.ensure_listing(winid)
    if winid == nil then
        winid = vim.api.nvim_get_current_win()
    end

    for k, _ in pairs(rabbit.listing) do
        if rabbit.listing[k] == nil then
            rabbit.listing[k] = { [winid] = {} }
        elseif rabbit.listing[k][winid] == nil then
            rabbit.listing[k][winid] = {}
        end
    end
end


---@param mode ValidMode
function rabbit.MakeBuf(mode)
    rabbit.usr.buf = vim.api.nvim_get_current_buf()
    rabbit.usr.win = vim.api.nvim_get_current_win()
    rabbit.usr.ns = 0

-- Ensure all lists exist
    rabbit.ensure_listing(rabbit.usr.win)

-- Prepare context to save time later
    if mode == nil or rabbit.listing[mode] == nil then
        mode = "history"
    end

    rabbit.ctx.border_color = rabbit.opts.color.box[mode] or rabbit.opts.color.box.history
    rabbit.ctx.mode = mode
    rabbit.ctx.listing = vim.deepcopy(rabbit.listing[mode][rabbit.usr.win])

    if #rabbit.ctx.listing > 0 then
        local same_id = rabbit.ctx.listing[1] == rabbit.usr.buf
        local same_name = rabbit.ctx.listing[1] == vim.api.nvim_buf_get_name(rabbit.usr.buf)

        if same_id or same_name then
            table.remove(rabbit.ctx.listing, 1)
        end
    end

    local buf = vim.api.nvim_create_buf(false, true)
    rabbit.rab.buf = buf

    local win_conf = vim.api.nvim_win_get_config(rabbit.usr.win)

-- Generate configuration
    local opts = {
        width = math.min(rabbit.opts.window.width, win_conf.width),
        height = math.min(rabbit.opts.window.height, win_conf.height),
        style = "minimal",
    }

    local floating = rabbit.opts.window.float
    local splitting = rabbit.opts.window.split
    if floating == true then
        opts.relative = "win"
        opts.row = win_conf.height - opts.height
        opts.col = win_conf.width - opts.width
    elseif floating then
        opts.relative = "win"
        opts.row = floating.top or (floating[1] == "top" and 0 or (win_conf.height - opts.height))
        opts.col = floating.left or (floating[2] == "left" and 0 or (win_conf.width - opts.width))
    elseif splitting == true then
        opts.split = "right"
        opts.height = win_conf.height
    elseif splitting == "left" or splitting == "right" then
        opts.split = splitting
        opts.height = win_conf.height
    elseif splitting == "above" or splitting == "below" then
        opts.split = splitting
        opts.width = win_conf.width
    else
        opts.width = win_conf.width
        opts.height = 4
    end

    if floating or splitting then
        rabbit.rab.win = vim.api.nvim_open_win(buf, true, opts)
    else
        rabbit.rab.win = rabbit.usr.win
        rabbit.bufid = vim.api.nvim_buf_get_number(0)
        vim.api.nvim_win_set_buf(rabbit.usr.win, buf)
    end

    vim.api.nvim_win_set_hl_ns(rabbit.rab.win, rabbit.rab.ns)

-- Set key maps & auto commands
    for _, key in ipairs(rabbit.opts.keys.quit) do
        vim.api.nvim_buf_set_keymap(
            buf, "n", key, "<cmd>lua require('rabbit').Close()<CR>",
            { noremap = true, silent = true }
        )
    end

    for _, key in ipairs(rabbit.opts.keys.confirm) do
        vim.api.nvim_buf_set_keymap(
            buf, "n", key, "<cmd>lua require('rabbit').Select(vim.fn.line('.') - 2)<CR>",
            { noremap = true, silent = true }
        )
    end

    for k, v in pairs(rabbit.opts.keys.to) do
        if k ~= mode and rabbit.listing[k] ~= nil then
            vim.api.nvim_buf_set_keymap(
                buf, "n", v, "<cmd>lua require('rabbit').Switch('" .. (k or "r") .. "')<CR>",
                { noremap = true, silent = true }
            )
        end
    end

    vim.api.nvim_create_autocmd("WinLeave", { buffer = buf, callback = rabbit.Close })
    vim.api.nvim_create_autocmd("BufLeave", { buffer = buf, callback = rabbit.Close })
    vim.api.nvim_create_autocmd("WinClosed", { buffer = buf, callback = rabbit.Close })
    vim.api.nvim_create_autocmd("InsertEnter", { buffer = buf, callback = rabbit.Close })

    vim.api.nvim_create_autocmd("CursorMoved", { buffer = buf, callback = function()
        vim.api.nvim_buf_clear_namespace(rabbit.rab.buf, rabbit.rab.ns, 0, -1)
        local len = #rabbit.ctx.listing
        local line = vim.fn.line(".") - 1
        if line - 1 > 0 and line - 1 <= len then
            local fullscreen = rabbit.rab.win == rabbit.usr.win
            local offset = fullscreen and 0 or #(rabbit.opts.box.vertical)
            vim.api.nvim_buf_add_highlight(
                rabbit.rab.buf, rabbit.rab.ns, "CursorLine",
                line, offset, #(vim.api.nvim_get_current_line()) - offset
            )
        end
    end})

    ---@type ScreenSetBorderKwargs
    local b_kwargs = {
        colors = rabbit.opts.color,
        border_color = rabbit.ctx.border_color,
        width = opts.width,
        height = opts.height,
        emph_width = rabbit.opts.window.emphasis_width,
        box = rabbit.opts.box,
        fullscreen = rabbit.usr.win == rabbit.rab.win,
        title = rabbit.opts.window.title,
        mode = mode,
    }
    return {
        nr = buf,
        w = opts.width,
        h = opts.height,
        fs = screen.set_border(rabbit.rab.win, buf, b_kwargs)
    }
end


---@param mode ValidMode
function rabbit.Window(mode)
    if rabbit.rab.win ~= nil then
        local status, _ = pcall(rabbit.Close)
        rabbit.rab.win = nil

        -- Continue if the window managed to close without us noticing
        if status == true then return end
    end

    local buf = rabbit.MakeBuf(mode)

    if #rabbit.ctx.listing < 1 then
        rabbit.ShowMessage(rabbit.messages[rabbit.ctx.mode] or rabbit.messages.__default__)
        return
    end

    local has_name, buf_path = pcall(vim.api.nvim_buf_get_name, rabbit.usr.buf)
    if not has_name or buf_path:sub(1, 1) ~= "/" then
        buf_path = ""
    end

    for i = 1, #rabbit.ctx.listing do
        local target = ""
        if type(rabbit.ctx.listing[i]) == "number" then
            local valid = vim.api.nvim_buf_is_valid(rabbit.ctx.listing[i])
            while not valid and i < #rabbit.ctx.listing do
                table.remove(rabbit.ctx.listing, i)
                valid = vim.api.nvim_buf_is_valid(rabbit.ctx.listing[i])
            end

            if not valid then
                break
            end

            target = vim.api.nvim_buf_get_name(rabbit.ctx.listing[i])
        else
            target = "" .. rabbit.ctx.listing[i]
        end


        if target == "" then
            screen.add_entry({
                { text = "#nil ", color = rabbit.opts.color.noname },
                { text = rabbit.ctx.listing[i], color = rabbit.opts.color.file },
            })
        elseif target:sub(1, 1) ~= "/" then
            local rel = rabbit.RelPath(buf_path, vim.fn.fnamemodify(target, ":p"))
            screen.add_entry({
                { text = "#" .. rel.name .. " ", color = rabbit.opts.color.shell },
                { text = rabbit.ctx.listing[i], color = rabbit.opts.color.file },
            })
        else
            local rel = rabbit.RelPath(buf_path, vim.fn.fnamemodify(target, ":p"))
            screen.add_entry({
                { text = rel.dir, color = rabbit.opts.color.dir },
                { text = rel.name, color = rabbit.opts.color.file },
            })
        end
    end

    screen.draw_bottom()
    vim.api.nvim_win_set_cursor(rabbit.rab.win, { 3, buf.fs and 0 or #(rabbit.opts.box.vertical) })
end


function rabbit.Switch(mode)
    rabbit.Close()
    rabbit.Window(mode)
end


function rabbit.ensure_autocmd(evt)
    if evt.buf == rabbit.rab.buf then
        return nil
    end
    local winid = vim.fn.win_getid()
    rabbit.ensure_listing(winid)
    return winid
end


function rabbit.autocmd.BufEnter(evt)
    local winid = rabbit.ensure_autocmd(evt)
    if winid == nil then
        return
    end

    table.set_insert(rabbit.listing.history[winid], evt.buf)
    table.set_subtract(rabbit.listing.reopen[winid], evt.file)
end

function rabbit.autocmd.BufDelete(evt)
    local winid = rabbit.ensure_autocmd(evt)
    if winid == nil then
        return
    end

    local exists = table.set_subtract(rabbit.listing.history[winid], evt.buf)
    if exists and #evt.file > 0 and evt.file:sub(1, 1) == "/" then
        table.set_insert(rabbit.listing.reopen[winid], evt.file)
    end
end


vim.api.nvim_create_autocmd("WinClosed", {
    pattern = {"*"},
    callback = function(evt)
        for k, _ in pairs(rabbit.listing) do
            rabbit.listing[k][evt.file] = nil
        end
    end,
})


---@param opts RabbitOptions | string
function rabbit.setup(opts)
    rabbit.ensure_listing(vim.fn.win_getid())
    vim.api.nvim_create_user_command(
        "Rabbit",
        function(o) rabbit.Switch(o.fargs[1]) end,
        {
            nargs = "?",
            complete = function()
                return vim.tbl_keys(rabbit.listing)
            end
        }
    )

    if type(opts) == "string" then
        opts = { keys = { open = { opts } } }
    end

    -- Spread out the options
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

    if type(rabbit.opts.keys.to) == "string" then
        local k = rabbit.opts.keys.to
        rabbit.opts.keys.to = {}
        for v, _ in pairs(rabbit.listing) do
            rabbit.opts.keys.to[v] = k
        end
    end

    for key, val in pairs(rabbit.opts.keys) do
        if type(val) == "string" then
            rabbit.opts.keys[key] = { val }
        end
    end


    if type(rabbit.opts.color.box) == "string" then
        local c = rabbit.opts.color.box
        rabbit.opts.color.box = {}
        for v, _ in pairs(rabbit.listing) do
            rabbit.opts.color.box[v] = c
        end
    end

    for _, key in ipairs(rabbit.opts.keys.open) do
        vim.keymap.set("n", key, rabbit.Window, {
            desc = "Open Rabbit",
            noremap = true,
            silent = true
        })
    end

    for key, val in pairs(rabbit.autocmd) do
        vim.api.nvim_create_autocmd(key, {
            pattern = {"*"},
            callback = val,
        })
    end
end

return rabbit
