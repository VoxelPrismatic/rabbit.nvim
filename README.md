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
- [API](https://github.com/voxelprismatic/rabbit.nvim/wiki/API-Documentation)
- [Custom Plugin](https://github.com/voxelprismatic/rabbit.nvim/wiki/Custom-Plugin)

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
