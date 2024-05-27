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
        },
        reopen = {
            color = "#907aa9",  -- Border color
            switch = "o",       -- Keybind to switch to the reopen window from within Rabbit
            keys = {},          -- See the API for more details
        },
    },

    enable = {                  -- Builtin plugins to enable immediately
        "history",              -- The first plugin loaded will be the default in the event an invalid plugin is requested
        "reopen",
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

Here's what your `plugin.lua` should look like:
```lua
local set = require("rabbit.plugins.util")

---@type RabbitPlugin
local M = {
    color = "#d7827e",  -- Border color
    name = "history",   -- UNIQUE name of the plugin
    func = {},          -- Any extra functions you need
    switch = "r",       -- Keybind to switch to this plugin from within Rabbit
    listing = {},       -- Empty table for now
    empty_msg = "There's nowhere to jump to! Get started by opening another buffer",
    skip_same = true,   -- Whether or not to skip the first entry if it's the same as the current buffer
    keys = {
        -- This table should be in func_name:string[] format.
        -- If you have an entry in `M.func` called 'clear', and
        -- the default keybind should be `c`, then the following
        -- should be in the table:
        clear = { 'c' },
    },
    evt = {},           -- Event handlers. Key names should be the Autocmd name
    init = function(_) end,  -- Init function, if you need it
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
Important notes:
1. If `M.listing[0]` is not `nil`, then Rabbit treats this as a 'global' plugin instead of local per window.
   Even if you store information in `M.listing[winid]`, Rabbit will only present `M.listing[0]` to the end user.
2. Plugin names MUST be unique. If you have two plugins with the same name, the most recent call will override it.
3. You **MUST** run `rabbit.setup()` before calling `rabbit.attach(plugin)`.
4. The user's keybinds have priority, but your funcs have priority over Rabbit's defaults. Please try to use the same
   names so the user's keybinds work as expected.
5. You may have noticed the little `require("rabbit.plugins.util")` at the top. That's there to provide extremely basic
   set-like functionality, streamlining the plugin creation process.
6. Your listing can hold both Buffer IDs and file paths. It's best practice to use the same type throughout the table.
   - Invalid Buffer IDs are automatically ignored
   - BufUnload and BufDelete events will refresh the rabbit window automatically
7. When a new window is opened or closed, `M.listing[winid]` is automatically initialized for you, and winid is provided
   to your `evt` functions.
8. `func` functions have one parameter: the current selection index.
   - You should use `require("rabbit").ctx.listing` to get the listing displayed to the user
9. Only `BufEnter` and `BufDelete` events are supported out of the box. Should you want your own autocmd, just set the
   callback to `require("rabbit").autocmd` This should be set up in your `init` function, which is called whenever the
   plugin is attached to Rabbit
10. The default `file_add` and `file_del` functions are not implemented yet. Stay tuned.
