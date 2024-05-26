--- Screen handler for Rabbit
-- @module screen
-- @alias screen

local screen = {
    ctx = {
        title = {},
        middle = {},
        footer = {},
        box = {},
        colors = {},
        border_color = "Function",
        height = 0,
        width = 0,
        bufnr = nil,
        winnr = nil,
        fullscreen = false,
    }
}

--- Undo possible recursion in screen spec
---@param specs ScreenSpec[]
---@param width number
function screen.helper(specs, width)
    local fulltext = ""
    local highlights = {}
    for _, spec in ipairs(specs) do
        local spectext = ""
        if type(spec[1]) == "table" then
            local ret = screen.helper(spec, width)
            for _, s in ipairs(ret.highlights) do
                table.insert(highlights, {
                    name = s.name,
                    start = s.start + #fulltext,
                    last = s.last + #fulltext,
                })
            end
            fulltext = fulltext .. ret.fulltext
            goto continue
        end

        if type(spec.text) == "table" then
            -- This is handled, as you can see
            ---@diagnostic disable-next-line: param-type-mismatch
            for _, part in ipairs(spec.text) do
                spectext = spectext .. part
            end
        else
            -- This is handled, as you can see
            ---@diagnostic disable-next-line: cast-local-type
            spectext = spec.text
        end

        if spec.expand then
            local char = type(spec.expand) == "string" and spec.expand or " "
            spectext = ("" .. char):rep(width - vim.fn.strwidth(fulltext .. spectext)) .. spectext
        end

        if spec.color ~= nil and #(spec.color) > 1 then
            table.insert(highlights, {
                name = spec.color,
                start = #fulltext,
                last = #fulltext + #spectext
            })
        end

        fulltext = fulltext .. spectext

        ::continue::
    end

    return {
        fulltext = fulltext,
        highlights = highlights
    }
end

--- Renders to the screen
---@param win winnr
---@param buf bufnr
---@param line number
---@param specs ScreenSpec[]
function screen.render(win, buf, line, specs)
    if line == -1 then
        line = vim.api.nvim_buf_line_count(buf)
    end

    local finalspec = screen.helper(specs, vim.api.nvim_win_get_width(win))
    vim.api.nvim_buf_set_lines(buf, line, line + 1, false, { finalspec.fulltext })

    for _, hl in ipairs(finalspec.highlights) do
        vim.api.nvim_buf_add_highlight(buf, -1, hl.name, line, hl.start, hl.last)
    end
end


--- Adds a new border to the screen
---@param win winnr
---@param buf bufnr
---@param kwargs ScreenSetBorderKwargs
---@return false | ScreenSpec
function screen.set_border(win, buf, kwargs)
    local fs = kwargs.fullscreen and { text = "", color = "" } or false
    local c = (kwargs.width - 2 - #(kwargs.title)) / 2 - 1
    local emph = math.min(c - 4, kwargs.emph_width)

    screen.ctx.height = kwargs.height
    screen.ctx.width = kwargs.width
    screen.ctx.bufnr = buf
    screen.ctx.winnr = win
    screen.ctx.box = kwargs.box
    screen.ctx.colors = kwargs.colors
    screen.fullscreen = fs

    if fs then
        screen.ctx.title = {
            { text = kwargs.box.emphasis(emph), color = kwargs.border_color },
            { text = " " .. kwargs.title .. " ", color = kwargs.colors.title },
            { text = kwargs.box.emphasis(emph), color = kwargs.border_color },
        }
        screen.ctx.middle = { fs }
        screen.ctx.footer = { fs }

        screen.draw_top()

        return fs

    end


    screen.ctx.title = {
        {
            color = kwargs.border_color,
            text = {
                kwargs.box.top_left,
                kwargs.box.horizontal:rep(c - emph),
                kwargs.box.emphasis:rep(emph),
            },
        }, {
            color = kwargs.colors.title,
            text = " " .. kwargs.title .. " ",
        }, {
            color = kwargs.border_color,
            text = kwargs.box.emphasis:rep(emph),
        }, {
            color = kwargs.border_color,
            text = kwargs.box.top_right,
            expand = kwargs.box.horizontal,
        },
    }

    screen.ctx.middle = {{
        color = kwargs.border_color,
        text = {
            kwargs.box.vertical,
            (" "):rep(kwargs.width - 2),
            kwargs.box.vertical,
        },
    }}

    screen.ctx.footer = {
        {
            color = kwargs.border_color,
            text = kwargs.box.bottom_left,
        }, {
            color = kwargs.border_color,
            text = {
                " " .. kwargs.mode .. " ",
                kwargs.box.horizontal:rep(3),
                kwargs.box.bottom_right,
            },
            expand = kwargs.box.horizontal,
        }
    }

    screen.draw_top()

    return fs
end


function screen.draw_top()
    if #screen.ctx.title == 0 then
        return false
    end

    vim.api.nvim_buf_set_lines(screen.ctx.bufnr, 0, -1, false, {})

    screen.render(screen.ctx.winnr, screen.ctx.bufnr, 0, screen.ctx.title)
    screen.render(screen.ctx.winnr, screen.ctx.bufnr, 1, screen.ctx.middle)
end

function screen.draw_bottom()
    local h = #vim.api.nvim_buf_get_lines(screen.ctx.bufnr, 0, -1, false)

    for i = 1, math.max(1, screen.ctx.height - h - 1) do
        screen.render(screen.ctx.winnr, screen.ctx.bufnr, -1, screen.ctx.middle)
    end

    screen.render(screen.ctx.winnr, screen.ctx.bufnr, -1, screen.ctx.footer)
end

function screen.add_entry(spec)
    local i = #vim.api.nvim_buf_get_lines(screen.ctx.bufnr, 0, -1, false) - 1

    if i < 10 then
        vim.api.nvim_buf_set_keymap(
            screen.ctx.bufnr, "n", ("" .. i):sub(-1), "<cmd>lua require('rabbit').Select(" .. i .. ")<CR>",
            { noremap = true, silent = true }
        )
    end

    local to_render = screen.ctx.fullscreen and {} or {
        {
            color = screen.ctx.border_color,
            text = screen.ctx.box.vertical .. " "
        }, {
            color = screen.ctx.colors.index,
            text = (screen.ctx.fullscreen and " " or "") .. (i < 10 and " " or "") .. i .. ". "
        },
    }

    for _, v in ipairs(spec) do
        table.insert(to_render, v)
    end

    table.insert(to_render, screen.ctx.fullscreen or {
        color = screen.ctx.border_color,
        text = screen.ctx.box.vertical,
        expand = true
    })

    screen.render(screen.ctx.winnr, screen.ctx.bufnr, -1, to_render)
end


function screen.display_message(msg)
    screen.draw_top()
    local fullscreen = screen.ctx.fullscreen and { text = "", color = "" } or false
    local lines = { "" }

    for word in msg:gmatch("[^ ]+") do
        if (#(lines[#lines]) + #word > screen.ctx.width - 4) and not fullscreen then
            lines[#lines + 1] = ""
        end
        lines[#lines] = lines[#lines] .. word .. " "
    end

    for _, line in ipairs(lines) do
        screen.render(screen.ctx.winnr, screen.ctx.bufnr, -1, {
            fullscreen or { color = screen.ctx.border_color, text = screen.ctx.box.vertical .. " " },
            { color = screen.ctx.colors.file, text = line },
            fullscreen or { color = screen.ctx.border_color, text = screen.ctx.box.vertical, expand = true },
        })
    end

    screen.draw_bottom()
end

---@class ScreenSetBorderKwargs
---@field colors RabbitColor
---@field border_color VimHighlight
---@field width integer
---@field height integer
---@field emph_width integer
---@field box RabbitBox
---@field fullscreen boolean
---@field title string
---@field mode string
--.

return screen
