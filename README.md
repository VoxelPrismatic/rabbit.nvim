# Rabbit.nvim
<img src="/rabbit.png" width="512" alt="logo"/>
Quickly jump between buffers

> It's like Teej's Telescope, but awful, yet so easy to extend

- [Rabbit.nvim](#rabbitnvim)
  - [Why](#why)
  - [Install](#install)
  - [Usage](#usage)
  - [Configuration](#configuration)
  - [Preview](#preview)
- [API](#api)
  - [Using Rabbit](#using-rabbit)
  - [Internals](#internals)
  - [Create your own Rabbit listing](#create-your-own-rabbit-listing)


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
        require("rabbit").setup({{opts}})     -- Detailed below
    end,
}
```

### Usage
Just run your keybind! (or `:Rabbit {{mode}}`)

Currently available modes:
- `history` - Current window's buffer history
- `reopen` - Current window's recently closed buffers

With Rabbit open, you can hit a number 1-9 to jump to that buffer. You can
also move your cursor down to a specific line and hit enter to jump to that buffer.

If you hit `<CR>` immediately after launching Rabbit, it'll open your previous buffer.
You can hop back and forth between buffers very quickly, almost like a rabbit...

By default, you can switch to the opposite mode mode by pressing `r`



### Configuration
```lua
-- Use all the below defaults, but set a custom keybind
require("rabbit").setup("any keybind")

-- Defaults
require("rabbit").setup({
    colors = {
        title = {               -- Title text
            fg = "#000000",     -- Grabs from Normal
            bold = true,
        },
        index = {               -- Index numbers
            fg = "#000000",     -- Grabs from Comment
            italic = true,
        },
        dir = {                 -- Folders
            fg = "#000000",     -- Grabs from NonText
        },
        file = {                -- File name
            fg = "#000000",     -- Grabs from Normal
        },
        term = {                -- Addons, eg :term or :Oil
            fg = "#000000",     -- Grabs from Constant
            italic = true,
        },
        noname = {              -- No buffer name set
            fg = "#000000",     -- Grabs from Function
            italic = true,
        },
    },

    window = {
        box = {
            top_left = "╭",     -- Top left corner of box
            top_right = "╮",    -- Top right corner of box
            bottom_left = "╰",  -- Bottom left corner of box
            bottom_right = "╯", -- Bottom right corner of box
            vertical = "│",     -- Vertical wall
            horizontal = "─",   -- Horizontal ceiling
            emphasis = "═",     -- Emphasis around title, like `──══ Rabbit ══──`
        },

        box_style = "round",    -- One of "round", "square", "thick", "double"


        -- Where the plugin name should be displayed.
        -- - "bottom" means in the bottom left corner, but not displayed in full screen
        -- - "title" means next to rabbit, eg `──══ Rabbit History ══──`
        -- - "hide" means to not display it at all
        plugin_name_position = "bottom",

        title = "Rabbit",       -- Title text, eg: `──══ Rabbit ══──` or `──══ NotHarpoon ══──`

        emphasis_width = 8,     -- Eg: `──────══ Rabbit ══──────` or `──══════ Rabbit ══════──`


        float = true,           -- Plain `true` means use bottom right corner

        float = {
            top = 10000,        -- Top offset in lines
            left = 10000,       -- Left offset in columns
        },

        float = {
            "bottom",           -- "top" or "bottom;" MUST BE FIRST
            "right",            -- "left" or "right;" MUST BE LAST
        },


        -- When using split screen, it will try to use the width and height provided earlier.
        -- Eg, if splitting left or right, it will use the width provided, but current window height
        -- Eg, if splitting above or below, it will use the height provided, but the current window width
        -- NOTE: `float` must be explicitly set to false in order to split
        -- NOTE: If both `float` and `split` are unset, the Rabbit window will be full screen
        split = true,           -- Plain `true` means use the right side

        split = "right",        -- One of "left", "right", "above", "below"

        overflow = ":::",       -- String to display when folders overflow

        path_len = 12,          -- How many characters to display in folder name before cutting off
    },

    default_keys = {
        close = {               -- Default bindings to close Rabbit
            "<Esc>",
            "q",
            "<leader>",
        },

        select = {              -- Default bindings to select a buffer
            "<CR>",
        },

        open = {                -- Default bindings to open Rabbit
            "<leader>r",
        },

        file_add = {            -- Default bindings to add current buffer to persistent history
            "a",                -- This would act like Prime's Harpoon, but it isn't implemented yet
        },

        file_del = {            -- Default bindings to remove current buffer from persistent history
            "d",                -- This would act like Prime's Harpoon, but it isn't implemented yet
        },
    },

    plugin_opts = {             -- Plugin specific options you'd like to set
        history = {
            color = "#d7827e",  -- Border color
            switch = "r",       -- Keybind to switch to the history window from within Rabbit
            keys = {},          -- See the API for more details
            opts = {},          -- See the API for more details
        },
        reopen = {
            color = "#907aa9",  -- Border color
            switch = "o",       -- Keybind to switch to the reopen window from within Rabbit
            keys = {},          -- See the API for more details
            opts = {},          -- See the API for more details
        },
    },

    enable = {                  -- Builtin plugins to enable immediately
        "history",              -- The plugin shown when opening Rabbit
        "reopen",
        "oxide",
    },
})
```

### (old) Preview

https://github.com/VoxelPrismatic/rabbit.nvim/assets/45671764/da149bd5-4f6d-4c83-b6cb-67f1be762e2a

---

# API
```lua
local rabbit = require("rabbit")
```

### Using Rabbit

`mode` is any of the available modes. `history` and `reopen` are included.
```lua
rabbit.Window(mode)             -- Close rabbit window, or open with mode
rabbit.Switch(mode)             -- Open with mode
rabbit.func.close()             -- Default func to close rabbit window
rabbit.func.select(n)           -- Default func to select an entry
rabbit.setup(opts)              -- Setup options
rabbit.attach(plugin)           -- Attach a custom plugin
```

### Internals
```lua
rabbit.MakeBuf(mode)            -- Create the buffer and window
rabbit.ShowMessage(msg)         -- Clear and show a message
rabbit.RelPath(src, target)     -- Return the relative path object for highlighting
rabbit.ensure_listing(winid)    -- Ensure that the window has a table for all listings
```

### Create your own Rabbit listing
All luadoc information is included in [doc.lua](/lua/rabbit/doc.lua)

Just remember to call `rabbit.setup()` before calling `rabbit.attach(plugin)`.

Here's what your `plugin.lua` should look like:
```lua
local set = require("rabbit.plugins.util")
-- This module provides basic set-like functionality, including:
-- - Find the index of an element
-- - Remove all instances of an element
-- - Insert an element at the top of the table, while deleting all other instances
-- - Save a table to a file
-- - Recover a table from a file

---@type RabbitPlugin
local M = {
    color = "#d7827e",  -- Border color

    name = "history",   -- UNIQUE name of the plugin. This will be overwritten in the case of duplicate names.

    func = {
        -- Any other functions you may need. In the case of Oxide, it defines `file_del`. All functions here are
        -- called with one paramter: The highlighted position. Be careful, as this may not be a valid cursor position,
        -- eg out of bounds.
    },

    switch = "r",       -- Keybind to switch to this plugin from within Rabbit

    listing = {
        -- This is where all the listings are stored. Normally, Rabbit calls `M.listing[winid]`, but you can
        -- set `M.listing[0]` for a global listing, no matter the winid. Since the first winid is ALWAYS 1000,
        -- you can store a many other details for internal purposes. In the case of Oxide, it stores the file
        -- name, current working directory, and how often you visit this file from that directory.
        --
        -- Rabbit automatically creates empty tables for each new window, and deletes them when closing the window.
        -- No need to manage that in your plugin.
        --
        -- Each listing can contain either Buffer IDs or file names. Either will work well. Rabbit also automatically
        -- refreshes when a buffer is unloaded or deleted. Invalid Buffer IDs are automatically removed, so be sure to
        -- use `require("rabbit").ctx.listing` to get the listing displayed to the user
    },

    empty_msg = "There's nowhere to jump to! Get started by opening another buffer",

    skip_same = true,   -- Whether or not to skip the first entry if it's the same as the current buffer


    keys = {
        -- This table should be in func_name:string[] format. If you have an entry in `M.func` called 'clear', and
        -- the default keybind should be `c`, then the following should be in the table:
        clear = { 'c' },

        -- Keep in mind that if the user also has a keybind set for `clear`, it will take priority over this one.
    },


    evt = {
        -- Event handlers. Key names should be the Autocmd name, like `BufEnter` or `BufDelete`. Only these two
        -- events are automatically registered by Rabbit.
        --
        -- There is also a `RabbitEnter` event which is called right before Rabbit is displayed. This is useful when
        -- you need to set up your global listing. In the case of Oxide, it filters and sorts internal listings before
        -- producing M.listing[0]. RabbitEnter takes zero parameters.
    },

    opts = {},          -- Plugin specific options you'd like to set

    -- Initializer, if you need it. The first parameter is the plugin object so Ldoc doesn't scream at you.
    -- In the case of Oxide, it reads the memory file and sets `M.listing[0]`
    init = function(_) end,


    -- If not nil, this will be replaced with the file used for persistent memory. By the time `M.init`
    -- is called, the file already exists and is set to an empty table. Use `nil` or do not set at all if you
    -- do not plan on using persistent memory.
    memory = nil,

}

---@param evt NvimEvent
---@param winid integer
function M.evt.BufEnter(evt, winid)
    -- Add the current buffer to the top of the listing
    set.add(M.listing[winid], evt.buf)
end


---@param evt NvimEvent
---@param winid integer
function M.evt.BufDelete(evt, winid)
    -- Remove the current buffer altogether
    set.sub(M.listing[winid], evt.buf)
end

return M
```
