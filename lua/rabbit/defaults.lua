---@type DefaultRabbitBox
local box = {
    round = {
        top_left = "╭",
        top_right = "╮",
        bottom_left = "╰",
        bottom_right = "╯",
        vertical = "│",
        horizontal = "─",
        emphasis = "═",
    },
    square = {
        top_left = "┌",
        top_right = "┐",
        bottom_left = "└",
        bottom_right = "┘",
        vertical = "│",
        horizontal = "─",
        emphasis = "═",
    },
    thick = {
        top_left = "┏",
        top_right = "┓",
        bottom_left = "┗",
        bottom_right = "┛",
        vertical = "┃",
        horizontal = "━",
        emphasis = "═",
    },
    double = {
        top_left = "╔",
        top_right = "╗",
        bottom_left = "╚",
        bottom_right = "╝",
        vertical = "║",
        horizontal = "═",
        emphasis = "━",
    }
}


local function grab_color(name)
    local details = vim.api.nvim_get_hl(0, { name = name })
    return string.format("#%06x", details.fg)
end

---@type RabbitOptions
local options = {
    colors = {
        title = { fg = grab_color("Normal"), bold = true },
        index = { fg = grab_color("Comment"), italic = true },
        dir = { fg = grab_color("NonText") },
        file = { fg = grab_color("Normal") },
        term = { fg = grab_color("Constant"), italic = true },
        noname = { fg = grab_color("Function"), italic = true },
    },
    window = {
        box = box.round,
        title = "Rabbit",
        emphasis_width = 8,
        width = 64,
        height = 24,
        float = {
            "bottom",
            "right",
        },
        split = "right",
        overflow = ":::",
        path_len = 12,
    },
    default_keys = {
        close = { "<Esc>", "q", "<leader>" },
        select = { "<CR>" },
        open = { "<leader>r" },
        file_add = { "a" },
        file_del = { "x" },
    },
    plugin_opts = {},
    enable = {
        "history",
        "reopen",
    },
}

return {
    options = options,
    box = box
}
