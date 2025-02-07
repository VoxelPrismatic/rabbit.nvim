local screen = require("rabbit.screen")
local defaults = require("rabbit.defaults")
local set = require("rabbit.plugins.util")
local compat = require("rabbit.compat")
local autocmd = require("rabbit.autocmd")

-- Somehow Neovim 0.9.5 over alacritty doesn't have vim.uv
vim.uv = vim.uv or vim.loop

-- Replaces terminal codes and keycodes (<CR>, <Esc>, ...) in a string with
-- the internal representation.
---@param str string String to be converted
function vim.fn.feed_termcodes(str, mode)
    vim.fn.feedkeys(vim.api.nvim_replace_termcodes(str, true, true, true), mode or "n")
end


---@class Rabbit.Instance
local rabbit = {
    rabbit = {
        win = nil,
        buf = nil,
        ns = vim.api.nvim_create_namespace("rabbit"),
    },

    ctx = { listing = {} },

    user = {
        win = nil,
        buf = nil,
        ns = -1,
    },

    opts = defaults.options,

    ---This is handled below
    ---@diagnostic disable-next-line: missing-fields
    func = {},

    default = "",
    plugins = {},

    compat = compat,

    input = require("rabbit.input"),
}

-- Display a message in the buffer
---@param text string
function rabbit.ShowMessage(text)
    screen.display_message(text)
    rabbit.Legend(rabbit.ctx.plugin.name)
end


-- Return the relative path between two paths
---@param source string Which file you're coming from
---@param target string Which file you're going to
---@return { dir: string, name: string }
function rabbit.RelPath(source, target)
    -- Get absolute paths
    source = vim.fn.fnamemodify(source, ":p")
    target = vim.fn.fnamemodify(target, ":p")

    -- Split by folder
    local source_parts = vim.split(source, rabbit.compat.path)
    local target_parts = vim.split(target, rabbit.compat.path)

    -- Get common path
    local common = 0
    for i = 1, math.min(#source_parts, #target_parts) do
        if source_parts[i] ~= target_parts[i] then
            break
        end
        common = common + 1
    end

    -- Construct relative path
    local l = rabbit.opts.window.path_len
    local filename = target_parts[#target_parts]
    local distance = #source_parts - common - 1
    local relative = ("../"):rep(distance)
    local fall = rabbit.opts.window.overflow .. "/"

    if distance == 0 and #source_parts == #target_parts then
        return { dir = "", name = filename }
    elseif distance < 3 then
        relative = ("."):rep(distance + 1) .. "/"
    elseif common + 1 == #source_parts - #target_parts then
        relative = fall
    end

    for i = common + 1, #target_parts - 1 do
        local p = target_parts[i]
        if #p > l then
            p = p:sub(1, l - 1) .. "…"
        end
        relative = relative .. p .. "/"
    end

    -- Manage overflow
    local max_w = screen.ctx.width - 8 - #fall
    if (#relative + #filename) > max_w then
        while relative:sub(1, #("../")) == "../" do
            relative = relative:sub(#("../") + 1)
        end

        while (#relative + #filename) > max_w do
            local q = vim.split(relative, "/")
            table.remove(q, 1)
            relative = table.concat(q, "/")
        end

        relative = fall .. relative
    end
    local r, count = string.gsub(relative, "%.%./", "")
    if count >= 3 then
        relative = fall .. r
    elseif count > 1 then
        relative = ("."):rep(count + 1) .. "/" .. r
    end


    return {
        dir = relative ~= "/" and relative or "",
        name = filename,
    }
end


-- Close the Rabbit window
function rabbit.func.close(_)
    if screen.ctx.in_input then
        return
    end

    if rabbit.rabbit.win ~= nil then
        if rabbit.rabbit.win == rabbit.user.win then
            vim.api.nvim_win_set_buf(rabbit.user.win, rabbit.user.buf)
        else
            vim.api.nvim_win_close(rabbit.rabbit.win, true)
            vim.api.nvim_set_current_win(rabbit.user.win) -- For split windows
        end
        rabbit.rabbit.win = nil
    end

    if rabbit.rabbit.buf ~= nil then
        vim.api.nvim_buf_delete(rabbit.rabbit.buf, { force = true })
        rabbit.rabbit.buf = nil
    end

    if rabbit.user.win == nil then
        rabbit.user.win = vim.fn.win_getid()
    end
end


-- The window should not scroll when exiting Rabbit
local function close_with_cursor(_)
    if screen.ctx.in_input then
        return
    end

    (rabbit.ctx.plugin.func.close or rabbit.func.close)()

    local term_codes = ("<Up><Left>"):rep(rabbit.user.view.topline) ..
                       ("<Down>"):rep(rabbit.user.view.topline + rabbit.user.conf.height - 3) ..
                       ("<Up>"):rep(rabbit.user.conf.height - (rabbit.user.view.lnum - rabbit.user.view.topline) - 2) ..
                       ("<Right>"):rep(rabbit.user.view.col)

    vim.fn.feed_termcodes(term_codes, "n")
end


-- Selects a line in the entry
---@param lineno integer
function rabbit.func.select(lineno)
    lineno = math.max(lineno, 1)

    rabbit.func.close()

    if lineno >= 1 and lineno <= #(rabbit.ctx.listing) then
        local b = rabbit.ctx.listing[lineno]
        if type(b) == "string" then
            vim.cmd.edit(b)
        else
            vim.api.nvim_win_set_buf(rabbit.user.win, tonumber(b) or 0)
        end
    end
end


-- Creates associated listings
---@param winid integer Window ID
function rabbit.ensure_listing(winid)
    if winid == nil then
        winid = vim.api.nvim_get_current_win()
    end

    local evt = { ---@type NvimEvent
        buf = vim.api.nvim_get_current_buf(),
        event = "BufEnter",
        id = winid,
        file = vim.fn.expand("%:p"),
        match = ""
    }

    for k, _ in pairs(rabbit.plugins) do
        local p = rabbit.plugins[k] ---@type Rabbit.Plugin
        local handler = (p.evt.BufEnter or function(_, _) end)

        if p.listing == nil then
            p.listing = { [winid] = {} }
            handler(evt, winid)
        elseif p.listing[winid] == nil then
            p.listing[winid] = {}
            handler(evt, winid)
        end
    end
end


-- Highlight manager
function rabbit.BufHighlight()
    vim.api.nvim_buf_clear_namespace(rabbit.rabbit.buf, rabbit.rabbit.ns, 0, -1)
    local len = #rabbit.ctx.listing
    local line = vim.fn.line(".") - 1
    local e = rabbit.ctx.listing[math.max(1, line - 2)]

    if type(e) == "number" and not vim.api.nvim_buf_is_valid(e) then
        return rabbit.Redraw()
    end

    if line - 1 <= 0 or line - 1 > len then
        return
    end

    local fullscreen = rabbit.rabbit.win == rabbit.user.win
    local offset = fullscreen and 0 or #(rabbit.opts.window.box.vertical)
    vim.api.nvim_buf_add_highlight(
        rabbit.rabbit.buf, rabbit.rabbit.ns, "CursorLine",
        line, offset, #(vim.api.nvim_get_current_line()) - offset
    )
end


-- Creates the buffer for the given mode
---@param mode string
---@return Rabbit.Context.Buffer
function rabbit.MakeBuf(mode)
    rabbit.user.buf = vim.api.nvim_get_current_buf()
    rabbit.user.win = vim.api.nvim_get_current_win()
    rabbit.user.ns = 0
    rabbit.user.view = vim.fn.winsaveview()

    local buf = vim.api.nvim_create_buf(false, true)
    rabbit.rabbit.buf = buf

    local win_conf = vim.api.nvim_win_get_config(rabbit.user.win)
    win_conf.width = win_conf.width or vim.api.nvim_win_get_width(rabbit.user.win)
    win_conf.height = win_conf.height or vim.api.nvim_win_get_height(rabbit.user.win)
    rabbit.user.conf = win_conf

    rabbit.ctx.plugin = rabbit.plugins[mode] or rabbit.plugins[rabbit.default]
    mode = rabbit.ctx.plugin.name

    rabbit.ensure_listing(rabbit.user.win)

-- In case the plugin has a listing it must prepare
    if rabbit.ctx.plugin.evt.RabbitEnter ~= nil then
        local path = vim.fn.getcwd()
        if rabbit.ctx.plugin.opts ~= nil then
            if type(rabbit.ctx.plugin.opts.path_key) == "function" then
                path = rabbit.ctx.plugin.opts.path_key()
            end
        end

        local mock_evt = { ---@type Rabbit.Event.Enter
            buf = rabbit.user.buf,
            event = "RabbitEnter",
            id = rabbit.user.win,
            file = vim.fn.expand("%:p"),
            match = path,
        }
        rabbit.ctx.plugin.evt.RabbitEnter(mock_evt, rabbit.user.win)
    end

-- Generate configuration
    local opts = {
        width = math.min(rabbit.opts.window.width or 64, win_conf.width or 64),
        height = math.min(rabbit.opts.window.height or 24, win_conf.height or 24),
        style = "minimal",
    }

    local floating = rabbit.opts.window.float == true and { "bottom", "right" } or rabbit.opts.window.float
    local splitting = rabbit.opts.window.split == true and "right" or rabbit.opts.window.split

    if floating == "center" then
        opts.relative = "win"
        opts.row = (win_conf.height - opts.height) / 2
        opts.col = (win_conf.width - opts.width) / 2
    elseif floating then
        opts.relative = "win"
        opts.row = floating.top or (floating[1] == "top" and 0 or (win_conf.height - opts.height))
        opts.col = floating.left or (floating[2] == "left" and 0 or (win_conf.width - opts.width))
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

-- Open window and buffer
    if floating or splitting then
        rabbit.rabbit.win = vim.api.nvim_open_win(buf, true, opts)
    else
        rabbit.rabbit.win = rabbit.user.win
        rabbit.bufid = vim.fn.bufnr(0)
        vim.api.nvim_win_set_buf(rabbit.user.win, buf)
    end

-- Set autocmds
    vim.api.nvim_create_autocmd(
        { "BufLeave", "WinLeave", "WinClosed" },
        { buffer = buf, callback = rabbit.ctx.plugin.func.close or rabbit.func.close }
    )
    vim.api.nvim_create_autocmd(
        { "InsertEnter" },
        { buffer = buf, callback = close_with_cursor }
    )

    vim.api.nvim_create_autocmd("CursorMoved", { buffer = buf, callback = rabbit.BufHighlight })

-- Set border
    local b_title = rabbit.opts.window.title
    local b_mode = ""

    if rabbit.opts.window.plugin_name_position == "bottom" then
        b_mode = " " .. mode .. " "
    elseif rabbit.opts.window.plugin_name_position == "title" then
        b_title = b_title .. " " .. (mode:sub(1, 1):upper()) .. (mode:sub(2):lower())
    end

    ---@type Rabbit.Screen.Border_Kwargs
    local b_kwargs = {
        colors = rabbit.opts.colors,
        border_color = rabbit.ctx.plugin.color,
        width = opts.width,
        height = opts.height,
        emph_width = rabbit.opts.window.emphasis_width,
        box = rabbit.opts.window.box,
        fullscreen = rabbit.user.win == rabbit.rabbit.win,
        title = b_title or "",
        mode = b_mode,
        pos_col = opts.col,
        pos_row = opts.row,
    }

    local fs = screen.set_border(rabbit.rabbit.win, buf, b_kwargs)

    return { ---@type Rabbit.Context.Buffer
        nr = buf,
        w = opts.width,
        h = opts.height,
        fs = fs,
        pos = fs and 0 or #(b_kwargs.box.vertical),
    }
end


---@param mode string
function rabbit.Window(mode)
    if rabbit.rabbit.win ~= nil then
        local status, _ = pcall(rabbit.ctx.plugin.func.close or rabbit.func.close)
        rabbit.rabbit.win = nil

        -- Continue if the window managed to close without us noticing
        if status == true then return end
    end

    rabbit.ctx.buffer = rabbit.MakeBuf(mode)
    screen.draw_top()
    if rabbit.Redraw() then
        vim.api.nvim_win_set_cursor(rabbit.rabbit.win, { 3, rabbit.ctx.buffer.pos })
    end
end


-- Redraws the window
---@return boolean whether or not the cursor needs to be moved
function rabbit.Redraw()
    local mode = rabbit.ctx.plugin.name
    local buf = rabbit.ctx.buffer

    if rabbit.rabbit.win == nil or buf == nil then
        return false
    end

-- Copy listing; remove first entry if needed
    rabbit.ctx.listing = vim.deepcopy(
        rabbit.ctx.plugin.listing[0] or
        rabbit.ctx.plugin.listing[rabbit.user.win]
    )

    if #rabbit.ctx.listing > 0 and rabbit.ctx.plugin.skip_same then
        local first_entry = rabbit.ctx.listing[1]
        local name = vim.api.nvim_buf_get_name(rabbit.user.buf)
        if first_entry == rabbit.user.buf or first_entry == name then
            table.remove(rabbit.ctx.listing, 1)
        end
    end

    local has_name, buf_path = pcall(vim.api.nvim_buf_get_name, rabbit.user.buf)
    if not has_name or buf_path:sub(1, 1) ~= "/" then
        local path = vim.fn.getcwd()
        if rabbit.ctx.plugin.opts ~= nil then
            if type(rabbit.ctx.plugin.opts.path_key) == "function" then
                path = rabbit.ctx.plugin.opts.path_key()
            end
        end
        buf_path = path .. "/rabbit.txt" -- Relative to CWD if no name set
    end

    local mock_evt = { ---@type Rabbit.Event.Invalid
        buf = rabbit.user.buf,
        event = "RabbitInvalid",
        id = rabbit.user.win
    }

    local invalid_callback = rabbit.ctx.plugin.evt.RabbitInvalid or function() end

    local i = 1
    while i <= #rabbit.ctx.listing do
        local target = ""
        if type(rabbit.ctx.listing[i]) == "number" then
            local j = tonumber(rabbit.ctx.listing[i]) or 0
            if not vim.api.nvim_buf_is_valid(j) then
                mock_evt.file = tostring(j)
                mock_evt.match = "bufnr"
                table.remove(rabbit.ctx.listing, i)
                invalid_callback(mock_evt, rabbit.user.win)
                goto continue
            end
            target = vim.api.nvim_buf_get_name(j)
        elseif type(rabbit.ctx.listing[i]) == "string" then
            target = "" .. rabbit.ctx.listing[i]
            local stat = vim.uv.fs_stat(target)
            if #target <= 0 or (target[1] == "/" and stat == nil) then
                mock_evt.file = target
                mock_evt.match = "filename"
                table.remove(rabbit.ctx.listing, i)
                invalid_callback(mock_evt, rabbit.user.win)
                goto continue
            end
        else
            goto skip
        end

        if target == "" then
            screen.add_entry({
                { text = "#nil ", color = "RabbitNil" },
                { text = rabbit.ctx.listing[i] .. "", color = "RabbitFile" },
            }, i + 1)
        elseif string.find(target, "rabbitmsg://") == 1 then
            target = target:sub(#"rabbitmsg://" + 1) .. "\n"
            local msg = vim.split(target, "\n")[1]
            local extra = vim.split(target, "\n")[2]
            local space = (" "):rep(buf.w - vim.fn.strwidth(msg .. extra .. "| .  |") - math.max(2, #(tostring(i))))
            screen.add_entry({
                { text = msg, color = "RabbitMsg" },
                { text = space .. extra, color = "RabbitDir" },
            }, i + 1)
        elseif target:sub(1, 1) ~= "/" then
            local rel = rabbit.RelPath(buf_path, target)
            local mod = vim.split(target, ":/")[1]
            screen.add_entry({
                { text = "#" .. (#rel.name > 0 and rel.name or mod) .. " ", color = "RabbitTerm" },
                { text = rabbit.ctx.listing[i] .. "", color = "RabbitFile" },
            }, i + 1)
        else
            local rel = rabbit.RelPath(buf_path, target)
            screen.add_entry({
                { text = rel.dir, color = "RabbitDir" },
                { text = rel.name, color = "RabbitFile" },
            }, i + 1)
        end

        ::skip::
        i = i + 1
        ::continue::
    end

    if #rabbit.ctx.listing < 1 then
        rabbit.ShowMessage(rabbit.ctx.plugin.empty_msg or defaults.msg)
        return false
    end

    rabbit.Legend(mode, screen.draw_bottom(i + 1))
    return true
end


-- Renders a little keymap legend below the visible area
---@param mode string
---@param line? integer
function rabbit.Legend(mode, line)
    if rabbit.rabbit.win == nil then
        return
    end

    mode = mode or rabbit.ctx.plugin.name

    local keys = "iIaArR"
    for key in string.gmatch(keys, ".") do
        vim.api.nvim_buf_set_keymap(rabbit.rabbit.buf, "n", key, "", {
            noremap = true, silent = true,
            callback = function()
                (rabbit.ctx.plugin.func.close or rabbit.func.close)()
                vim.fn.feedkeys(key, "t")
            end
        })
    end

    line = screen.newline({
        { color = "RabbitTitle", text = " Switch:" },
    }, line)

    for k, _ in pairs(rabbit.plugins) do
        local v = rabbit.plugins[k] ---@type Rabbit.Plugin
        vim.api.nvim_set_hl(0, "RabbitPlugin_" .. v.name, { fg = v.color, bold = true })
        if k ~= mode then
            vim.api.nvim_buf_set_keymap(rabbit.rabbit.buf, "n", v.switch, "", {
                noremap = true, silent = true,
                callback = function() rabbit.Switch(v.name) end
            })
            line = screen.render(line, {
                { color = "RabbitFile", text = "   " .. v.switch .. " - ", },
                { color = "RabbitPlugin_" .. k, text = v.name, },
            })
        end
    end

    local all_funcs = vim.tbl_keys(rabbit.opts.default_keys)
    set.sub(all_funcs, "open")
    for k, _ in pairs(rabbit.ctx.plugin.keys) do
        set.add(all_funcs, k)
    end

    if #vim.tbl_keys(all_funcs) == 0 then
        return
    end

    line = screen.newline({
        { color = "RabbitTitle", text = " Keys:" },
    }, line)

    for _, k in ipairs(all_funcs) do
        local keys = rabbit.opts.default_keys[k] or rabbit.ctx.plugin.keys[k] or {}
        local cb = rabbit.ctx.plugin.func[k] or rabbit.func[k]
        if cb == nil then
            goto continue
        end
        line = screen.render(line, {
            { color = "RabbitPlugin_" .. mode, text = "   " .. k },
        })
        for _, key in ipairs(keys) do
            line = screen.render(line, {
                { color = "RabbitFile", text = "   - " .. key },
            })
            vim.api.nvim_buf_set_keymap(rabbit.rabbit.buf, "n", key, "", {
                noremap = true, silent = true,
                callback = function() cb(vim.fn.line(".") - 2) end
            })
        end
        ::continue::
    end

end


-- Switches the window
---@param mode string
---@return Rabbit.Instance
function rabbit.Switch(mode)
    rabbit.func.close()
    rabbit.Window(mode)
    return rabbit
end


---@param evt NvimEvent
function rabbit.autocmd(evt)
    if evt.buf == rabbit.rabbit.buf then
        return
    end
    local winid = vim.fn.win_getid()
    rabbit.ensure_listing(winid)

    for k, _ in pairs(rabbit.plugins) do
        local p = rabbit.plugins[k] ---@type Rabbit.Plugin
        if p.evt[evt.event] ~= nil then
            p.evt[evt.event](evt, winid)
        end
    end
end


---@param opts Rabbit.Options | string
function rabbit.setup(opts)
    rabbit.user.ns = 0
    rabbit.ensure_listing(vim.fn.win_getid())
    vim.api.nvim_create_user_command("Rabbit", function(o) rabbit.Switch(o.fargs[1]) end, {
        nargs = "?",
        complete = function()
            return vim.tbl_keys(rabbit.plugins)
        end
    })

    if type(opts) == "string" then
        ---@type Rabbit.Options
        opts = defaults.options
        opts.default_keys.open = { "" .. opts }
    end

    rabbit.opts = vim.tbl_deep_extend("force", rabbit.opts, opts)

    if defaults.box[rabbit.opts.window.box_style] ~= nil then
        rabbit.opts.window.box = defaults.box[rabbit.opts.window.box_style]
    end

    for _, n in ipairs(rabbit.opts.enable) do
        rabbit.attach(n)
    end

    for _, key in ipairs(rabbit.opts.default_keys.open) do
        vim.keymap.set("n", key, rabbit.Window, {
            desc = "Open Rabbit",
            noremap = true,
            silent = true
        })
    end
end


---@param plugin Rabbit.Plugin | Rabbit.Builtin
function rabbit.attach(plugin)
    if rabbit.user.ns ~= 0 then
        error("Call rabbit.setup() before attaching plugins")
    end
    if type(plugin) == "string" then
        local status, p = pcall(require, "rabbit.plugins." .. plugin)
        if not status then
            vim.print("WARNING: Rabbit plugin `" .. plugin .. "` not found")
            return
        end
        plugin = p
    end
    local opts = rabbit.opts.plugin_opts[plugin.name] or {} ---@type Rabbit.Plugin.Options
    plugin.keys = vim.tbl_extend("force", plugin.keys, opts.keys or {})
    plugin.color = opts.color or plugin.color
    plugin.switch = opts.switch or plugin.switch
    if plugin.opts ~= nil then
        plugin.opts = vim.tbl_deep_extend("force", plugin.opts, opts.opts or {})
    end
    if plugin.memory then
        plugin.memory = rabbit.make_mem(plugin.name)
    end
    if #rabbit.default == 0 then
        rabbit.default = plugin.name
    end
    rabbit.plugins[plugin.name] = plugin
    plugin.init(plugin)

    for evt, _ in pairs(plugin.evt) do
        if not set.index(autocmd.attached, evt) then
            table.insert(autocmd.attached, evt)
            vim.api.nvim_create_autocmd(evt, {
                pattern = {"*"},
                callback = rabbit.autocmd
            })
        end
    end
end


---@param name string Plugin name
function rabbit.make_mem(name)
    local parts = vim.split(debug.getinfo(1).source:sub(2), rabbit.compat.path)
    table.remove(parts, #parts)
    table.remove(parts, #parts)
    table.remove(parts, #parts)

    local path = table.concat(parts, rabbit.compat.path) ..
        rabbit.compat.path .. "memory" .. rabbit.compat.path

    vim.uv.fs_mkdir(path, 493) -- 0x755 = u=rwx; g=r-x; o=r-x
    local file = path .. name .. ".rabbit.plugin"
    if io.open(file, "r") == nil then
        set.save(file, {})
    end

    return vim.fn.fnamemodify(file, ":p")
end

autocmd.attach(rabbit)
return rabbit
