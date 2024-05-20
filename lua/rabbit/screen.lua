--- Screen handler for Rabbit
-- @module screen
-- @alias screen

local screen = {}

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

return screen
