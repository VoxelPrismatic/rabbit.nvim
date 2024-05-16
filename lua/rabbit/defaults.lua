local box = {
    ---@type RabbitBox
    rounded = {
        top_left = "╭",
        top_right = "╮",
        bottom_left = "╰",
        bottom_right = "╯",
        vertical = "│",
        horizontal = "─",
        emphasis = "═",
    },
    ---@type RabbitBox
    square = {
        top_left = "┌",
        top_right = "┐",
        bottom_left = "└",
        bottom_right = "┘",
        vertical = "│",
        horizontal = "─",
        emphasis = "═",
    },
    ---@type RabbitBox
    thick = {
        top_left = "┏",
        top_right = "┓",
        bottom_left = "┗",
        bottom_right = "┛",
        vertical = "┃",
        horizontal = "━",
        emphasis = "═",
    },
    ---@type RabbitBox
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


---@type RabbitOptions
local options = {
    color = {
        title = "Statement",
        box = "Function",
        index = "Comment",
        dir = "NonText",
        file = "",
        noname = "Error",
    },
    box = box.rounded,
    window = {
        title = "Rabbit",
        emphasis_width = 8,
        width = 64,
        height = 24,
    },
    keys = {
        quit = { "<Esc>", "q", "<leader>" },
        confirm = { "<CR>" },
        open = { "<leader>r" },
    },
    paths = {
        min_visible = 3,
        rollover = 12,
        overflow = ":::",
    },
}

return {
    options = options,
    box = box
}
