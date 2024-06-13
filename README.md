[rabbit.history]: https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FVoxelPrismatic%2Frabbit.nvim%2Fmain%2Flua%2Frabbit%2Fplugins%2FVERSION.json&query=%24.history&label=History&labelColor=white&color=yellow
[rabbit.oxide]: https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FVoxelPrismatic%2Frabbit.nvim%2Fmain%2Flua%2Frabbit%2Fplugins%2FVERSION.json&query=%24.oxide&label=Oxide&labelColor=white&color=yellow
[rabbit.harpoon]: https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FVoxelPrismatic%2Frabbit.nvim%2Fmain%2Flua%2Frabbit%2Fplugins%2FVERSION.json&query=%24.harpoon&label=Harpoon&labelColor=white&color=yellow
[rabbit.reopen]: https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FVoxelPrismatic%2Frabbit.nvim%2Fmain%2Flua%2Frabbit%2Fplugins%2FVERSION.json&query=%24.reopen&label=Reopen&labelColor=white&color=yellow

<div align="center">
    <img src="/rabbit.png" width="368" alt="logo"/>
    <h2 id="rabbitnvim">Jump between buffers faster than ever before</h2>
    <a href="https://github.com/VoxelPrismatic/rabbit.nvim/releases/latest"><img
        src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fapi.github.com%2Frepos%2FVoxelPrismatic%2Frabbit.nvim%2Freleases%2Flatest&query=%24.tag_name&style=flat&label=Rabbit&labelColor=white&logo=vowpalwabbit&logoColor=black"
    /></a>
    <a href="https://neovim.io/" target="_blank"><img
        src="https://img.shields.io/badge/Neovim-v0.10.0-brightgreen?style=flat&labelColor=white&logo=neovim&logoColor=black"
    /></a>
    <a href="https://github.com/VoxelPrismatic/rabbit.nvim/releases/latest"><img
        src="https://img.shields.io/github/downloads/voxelprismatic/rabbit.nvim/total?style=flat&logo=github&logoColor=black&label=Downloads&labelColor=white"
    /></a>
    <br/>
    <a href="https://x.com/voxelprismatic" target="_blank"><img
        src="https://img.shields.io/badge/VoxelPrismatic-white?style=flat&logo=x&logoColor=white&labelColor=black"
    /></a>
    <a href="https://discord.com/" target="_blank"><img
        src="https://img.shields.io/badge/VoxelPrismatic-white?style=flat&logo=discord&logoColor=white&labelColor=blue"
    /></a>
    <a href="https://patreon.com/voxelprismatic" target="_blank"><img
        src="https://img.shields.io/badge/Donate-white?style=flat&logo=patreon&logoColor=white&labelColor=red"
    /></a>
    <br>
    <span title="i wish i could customize this, dotfyles">
        <a href="https://dotfyle.com/plugins/VoxelPrismatic/rabbit.nvim"><img
            src="https://dotfyle.com/plugins/VoxelPrismatic/rabbit.nvim/shield?style=social"
        /></a>
    </span>
    <hr/>
</div>

- [Rabbit.nvim](#rabbitnvim)
  - [Why](#why)
  - [Install](#install)
  - [Usage](#usage)
  - [Configuration](#configuration)
  - [Preview](#preview)
- [Plugins](/lua/rabbit/plugins)
  - ![history][rabbit.history]
  - ![reopen][rabbit.reopen]
  - ![oxide][rabbit.oxide]
  - ![harpoon][rabbit.harpoon]
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

## Why
### [Harpoon][harpoon2]
- Harpoon requires explicit adding of files; too much effort
  - Rabbit:Oxide remembers your most frequently accessed files in your current directory

### [Telescope][tj_tele]
- Telescope:Buffers doesn't order by last BufEnter
  - Rabbit:History lists in order of most recent BufEnter
  - Rabbit:History does NOT list the file you're currently in, meaning a lightning-quick motion,
    `<leader>r` `<CR>` returns you to whence you came.

### `:ls` and `:b`
- Too much typing and looking and processing
  - That's what this plugin is designed to solve

### And this too...
None of these solutions actually support split screen. You must remember all the details
yourself.

- Did you use [Lspsaga] to open a type, func, or variable declaration?
  - One quick `‣r↵` later, you're back! Only three key presses!
- Are you referencing documentation but you don't like split screen?
  - Three key presses is still better than `:b #`
  - What happens when you frequently switch between more than two buffers? `:b #` doesn't cut it

[harpoon2]: https://github.com/theprimeagen/harpoon/tree/harpoon2
[tj_tele]: https://github.com/nvim-telescope/telescope.nvim
[lspsaga]: https://nvimdev.github.io/lspsaga/

## Install
Lazy:
```lua
return {
    "voxelprismatic/rabbit.nvim",
    config = function()
        require("rabbit").setup({{opts}})     -- Detailed below
    end,
}
```

> [!WARNING]
> Rabbit is only tested on Linux, although probably works as well on macOS.
> Please help with any compatibility issues by raising an [issue](https://github.com/voxelprismatic/rabbit.nvim/issues)

> [!NOTE]
> Rabbit is only tested on the latest version of Neovim, which is detailed at the top of the ReadMe.
> If your version of Neovim is significantly older, bite the bullet and upgrade.

## Usage
Just run your keybind! (or `:Rabbit {{mode}}`)

With Rabbit open, you can hit a number 1-9 to jump to that buffer. You can
also move your cursor down to a specific line and hit enter to jump to that buffer.

If you hit `<CR>` immediately after launching Rabbit, it'll open your previous buffer.
You can hop back and forth between buffers very quickly, almost like a rabbit...

If you scroll down on the Rabbit window, you'll see all the keybinds available.

## Configuration
**Please do not copy this config**, it is just an example detailing all the options available. 
There are lots of duplicate keys, but all LSP info is available simply by adding `---@type Rabbit.Options` 
to your config table
```lua
-- Use all the below defaults, but set a custom keybind
require("rabbit").setup("any keybind")

-- Defaults
require("rabbit").setup({ ---@type Rabbit.Options
    colors = {
        title = {               -- Title text
            fg = "#000000",     -- Grabs from :hi Normal
            bold = true,
        },
        index = {               -- Index numbers
            fg = "#000000",     -- Grabs from :hi Comment
            italic = true,
        },
        dir = "#000000",        -- Folders; Grabs from :hi NonText

        file = "#000000",       -- File name; Grabs from :hi Normal

        term = {                -- Addons, eg :term or :Oil
            fg = "#000000",     -- Grabs from :hi Constant
            italic = true,
        },
        noname = {              -- No buffer name set
            fg = "#000000",     -- Grabs from :hi Function
            italic = true,
        },
        message = {             -- Message text, eg "Open all files" in Reopen
            fg = "#000000",     -- Grabs from :hi Identifier
            italic = true,
        },
    },

    window = {
        -- If `box_style` is specified, it will overwrite anything set in `box`
        box_style = "round",    -- One of "round", "square", "thick", "double"
        box = {
            top_left = "╭",     -- Top left corner of box
            top_right = "╮",    -- Top right corner of box
            bottom_left = "╰",  -- Bottom left corner of box
            bottom_right = "╯", -- Bottom right corner of box
            vertical = "│",     -- Vertical wall
            horizontal = "─",   -- Horizontal ceiling
            emphasis = "═",     -- Emphasis around title, like `──══ Rabbit ══──`
        },

        width = 64,             -- Width, in columns
        height = 24,            -- Height, in rows

        -- Where the plugin name should be displayed.
        -- * "bottom" means in the bottom left corner, but not displayed in full screen
        -- * "title" means next to rabbit, eg `──══ Rabbit History ══──`
        -- * "hide" means to not display it at all
        plugin_name_position = "bottom",

        title = "Rabbit",       -- Title text, eg: `──══ Rabbit ══──` or `──══ NotHarpoon ══──`

        emphasis_width = 8,     -- Eg: `──────══ Rabbit ══──────` or `──══════ Rabbit ══════──`


        float = true,           -- Plain `true` means use bottom right corner
        float = "center",       -- Aligns to center
        float = {
            top = 10000,        -- Top offset in lines
            left = 10000,       -- Left offset in columns
        },
        float = {
            "bottom",           -- "top" or "bottom;" MUST BE FIRST
            "right",            -- "left" or "right;" MUST BE LAST
        },


        -- When using split screen, it will try to use the width and height provided earlier.
        -- Eg, when splitting left or right: height = 100%; width = `width`
        -- Eg, when splitting above or below: height = `height`; width = 100%
        -- NOTE: `float` must be explicitly set to false in order to split
        -- NOTE: If both `float` and `split` are false, a new buffer will open, "fullscreen"
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

## Preview

[2024-05-30 15-36-13.webm](https://github.com/VoxelPrismatic/rabbit.nvim/assets/45671764/eee4a60c-1302-469b-a329-471bfc59cddf)

---

# Plugins
Moved to [./lua/rabbit/plugins](/lua/rabbit/plugins)

---

# API
```lua
local rabbit = require("rabbit")
```

### Using Rabbit

`mode` is any of the available modes.
```lua
rabbit.Window(mode)             -- Close rabbit window, or open with mode
rabbit.Switch(mode)             -- Open with mode
rabbit.func.close()             -- Default func to close rabbit window
rabbit.func.select(n)           -- Default func to select an entry
rabbit.setup(opts)              -- Setup options
rabbit.Redraw()                 -- Actually draws the window
```


### Attaching your plugin
```lua
rabbit.attach(plugin)
```
`plugin` can be a string **only** if it is a default plugin. For example, `history` is a default plugin.
Custom plugins must be attached by passing the plugin table, not the name.


### Internals
```lua
rabbit.MakeBuf(mode)            -- Create the buffer and window
rabbit.ShowMessage(msg)         -- Clear and show a message
rabbit.RelPath(src, target)     -- Return the relative path object for highlighting
rabbit.ensure_listing(winid)    -- Ensure that the window has a table for all listings
rabbit.Legend()                 -- Appends the keymap legened, and sets keymaps]
rabbit.autocmd(evt)             -- Calls ensure_listing, and runs all relevant plugin events
```

### Create your own Rabbit listing
All luadoc information is included in [luadoc](/lua/rabbit/luadoc)
> Whatever flavor luals uses. It isn't ldoc.

Just remember to call `rabbit.setup()` before calling `rabbit.attach(plugin)`.

Here's what your `plugin.lua` should look like:
```lua
local set = require("rabbit.plugins.util")
-- This module provides basic set-like functionality, including:
-- * Find the index of an element
-- * Remove all instances of an element
-- * Insert an element at the top of the table, while deleting all other instances
-- * Save a table to a file
-- * Recover a table from a file

---@type Rabbit.Plugin
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


-- There is also a `RabbitEnter` event which is called right before Rabbit is displayed. This is useful when
-- you need to set up your global listing. In the case of Oxide, it filters and sorts internal listings before
-- producing M.listing[0]. RabbitEnter takes zero parameters.
---@param winid integer
function M.evt.RabbitEnter(winid)
    -- Called before the listing is copied. Do whatever you like here.
    -- Just remember that M.listing[0] is the global listing.
end


-- Example of a plugin with custom functions
---@param ln integer
function M.func.select(ln)
    vim.cmd("b " .. M.listing[0][ln])
    require("rabbit").func.close()
end


return M
```

