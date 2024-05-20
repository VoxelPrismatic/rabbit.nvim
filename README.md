# Rabbit.nvim
![logo](/rabbit.png)
Quickly jump between buffers

---

This tool tracks the history of buffers opened in an individual window. With a quick
motion, you can be in any one of your last twenty buffers without remembering any
details.

Unlike other tools, this remembers history *per window*, so you can really jump
quickly.

### Why
1. [theprimeagen/harpoon](https://github.com/theprimeagen/harpoon) requires explicit
adding of files, which is too much effort
2. Telescope:buffers doesn't remember history. You still have to remember what your
last file was
3. Same applies with `:ls` and `:b`


### Install
Lazy:
```lua
return {
    "voxelprismatic/rabbit.nvim",
    config = function()
        require("rabbit").setup("<leader>r")  -- Any keybind you like
    end,
}
```

### Usage
Just run your keybind!

With Rabbit open, you can hit a number 1-0 (1-10) to jump to that buffer. You can
also move your cursor down to a specific line and hit enter to jump to that buffer.

If you hit `<CR>` immediately after launching Rabbit, it'll open your previous buffer.
You can hop back and forth between buffers very quickly, almost like a rabbit...

If you click away from the Rabbit window, it'll close.

If you try to modify the Rabbit buffer, it'll close.

### Configuration
```lua
-- Use all the below defaults, but set a custom keybind
require("rabbit").setup("any keybind")

-- Defaults
require("rabbit").setup({
    box = {
        top_left = "╭",         -- Top left corner of box
        top_right = "╮",        -- Top right corner of box
        bottom_left = "╰",      -- Bottom left corner of box
        bottom_right = "╯",     -- Bottom right corner of box
        vertical = "│",         -- Vertical wall
        horizontal = "─",       -- Horizontal ceiling
        emphasis = "═",         -- Emphasis around title, like `──══ Rabbit ══──`
    },

    box = "rounded",            -- One of "rounded", "square", "thick", "double"

    window = {
        title = "Rabbit",       -- Window title
        emphasis_width = 8,     -- How many emphasis characters to put around the title
        width = 64,             -- How wide the Rabbit window should be
        height = 24,            -- How tall the Rabbit window should be

        -- When floating, Rabbit will always use the bounds of the current window.
        -- That means, in split screen, if you open Rabbit in the left window,
        -- it will (with default options) stick to the bottom right corner.
        float = {
            "bottom", "right",  -- Placement of the Rabbit window, "bottom", "top", "left", "right"
        },
        float = {
            top = 10000,        -- Top offset in lines
            left = 10000,       -- Left offset in columns
        },
        float = true,           -- Plain `true` means use bottom right corner

        -- When using split screen, it will try to use the width and height provided earlier.
        -- Eg, if splitting left or right, it will use the width provided, but current window height
        -- Eg, if splitting above or below, it will use the height provided, but the current window width
        -- NOTE: `float` must be explicitly set to false in order to split
        -- NOTE: If both `float` and `split` are unset, the Rabbit window will be full screen
        split = "right",        -- Which side to split the Rabbit window on. "left", "right", "above", "below"
        split = true,           -- Plain `true` means use the right side
    },

    keys = {
        quit = {                -- Close Rabbit; don't jump
            "<Esc>",
            "<leader>",
            "q",
        },
        confirm = {             -- Jump to selected buffer
            "<CR>"
        },
        open = {                -- Open Rabbit
            "<leader>r",
        },
    },

    paths = {
        min_visible = 3,        -- How many folders to display before cutting off
        rollover = 12,          -- How many characters to display in folder name before cutting off
        overflow = ":::",       -- String to display when folders overflow
    },

    colors = {                  -- These should all be highlight group names
        title = "Statement",    -- I don't feel like making a color API for this, just :hi and deal with it
        box = "Function",
        index = "Comment",
        dir = "NonText",
        file = "",
        noname = "Error",
    },
})
```


### API
```lua
local rabbit = require("rabbit")

rabbit.Window()                 -- Toggle Rabbit window
rabbit.Close()                  -- Force close window; will NOT throw error
rabbit.Select(n)                -- Select an entry
rabbit.RelPath(src, target)     -- Return the relative path object for highlighting
```


### Preview

https://github.com/VoxelPrismatic/rabbit.nvim/assets/45671764/da149bd5-4f6d-4c83-b6cb-67f1be762e2a

### DISCLAIMER
This is my first project in Lua, and my first plugin for Neovim.
Instead of shaming me for bad choices, let me know how I can
improve instead. I greatly appreciate it.
