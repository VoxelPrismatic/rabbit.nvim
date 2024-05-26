# Rabbit.nvim
<img src="/rabbit.png" width="512" alt="logo"/>
Quickly jump between buffers

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
        to = {
            history = "r",      -- Change to 'History' panel
            reopen = "r",       -- Change to 'Reopen' panel
        },
    },

    paths = {
        min_visible = 3,        -- How many folders to display before cutting off
        rollover = 12,          -- How many characters to display in folder name before cutting off
        overflow = ":::",       -- String to display when folders overflow
    },

    colors = {                  -- These should all be highlight group names
        title = "Statement",    -- I don't feel like making a color API for this, just :hi and deal with it
        box = {
            history = "Function",
            reopen = "Macro",
        },
        index = "Comment",
        dir = "NonText",
        file = "",
        noname = "Error",
        shell = "MoreMsg",
    },
})
```

### Preview

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
rabbit.Close()                  -- Close rabbit window
rabbit.Select(n)                -- Select an entry
rabbit.Setup(opts)              -- Setup options
```

### Internals
```lua
rabbit.MakeBuf(mode)            -- Create the buffer and window
rabbit.ShowMessage(msg)         -- Clear and show a message
rabbit.RelPath(src, target)     -- Return the relative path object for highlighting
rabbit.ensure_listing(winid)    -- Ensure that the window has a table for all listings
rabbit.ensure_autocmd(evt)      -- Return winid if it's a valid event. Also calls rabbit.ensure_listing
```

### Create your own Rabbit listing
Calling `require("rabbit")` returns the following structure:
```lua
{
    rab = {
        win = 0,                -- Winnr for the Rabbit window
        buf = 0,                -- Bufnr for the Rabbit buffer
        ns = 0,                 -- Highlight namespace (used for CursorLine)
    },

    usr = {
        win = 0,                -- Winnr for your window
        buf = 0,                -- Bufnr for your buffer
        ns = 0,                 -- Highlight namespace (unused)
    },

    ctx = {
        border_color = "",      -- Border color for this session
        listing = {},           -- Listing for this session
        mode = "",              -- Mode for this session
    },

    opts = {},                  -- Options, as detailed above

    listing = {
        history = {},           -- History listing
        reopen = {},            -- Reopen listing
    },

    messages = {
        history = "",           -- Message displayed when empty
        reopen = "",            -- Message displayed when empty
    },

    autocmd = {
        BufEnter = function(evt) end,
        BufDelete = function(evt) end,
    },
}
```

When adding your own plugin, you should add the following details *before* running `rabbit.setup(...)`,
as setup binds the autocmds globally, which can lead to conflicts if called multiple times.

1. Initialize `rabbit.listing.plugin_name = {}`
   - This is how Rabbit knows your plugin exists and can be opened.
2. Create your message strings in `rabbit.messages.plugin_name`
   - There is a default message just in case.
3. Set up your autocmds. The function name is the autocmd event, eg BufEnter or BufDelete
```lua
-- Default autocmds, so you make your own.
function table.set_subtract(t1, e)
    for i, v in ipairs(t1) do
        if v == e then
            table.remove(t1, i)
            return true
        end
    end
    return false
end

function table.set_insert(t1, e)
    table.set_subtract(t1, e)
    table.insert(t1, 1, e)
end


function rabbit.autocmd.BufEnter(evt)
    -- Grab current winid, and return if it's rabbit
    local winid = rabbit.ensure_autocmd(evt)
    if winid == nil then
        return
    end

    -- Put current buffer ID at top of history
    table.set_insert(rabbit.listing.history[winid], evt.buf)

    -- Remove if reopened
    table.set_subtract(rabbit.listing.reopen[winid], evt.file)
end


function rabbit.autocmd.BufDelete(evt)
    -- Grab current winid, and return if it's rabbit
    local winid = rabbit.ensure_autocmd(evt)
    if winid == nil then
        return
    end

    -- Remove current buffer ID from history
    local exists = table.set_subtract(rabbit.listing.history[winid], evt.buf)

    -- Only add to reopen if it's not blank and not a plugin (oil, shell, etc)
    if exists and #evt.file > 0 and evt.file:sub(1, 1) ~= "/" then
        table.set_insert(rabbit.listing.reopen[winid], evt.file)
    end
end
```

**NOTE:** You can use buffer IDs or file names in your listing table. The first listing will only
be removed if the filename or buffer ID matches. Do NOT store buffer IDs on BufDelete, as the
buffer ID no longer exist and an error will be thrown.

Buffers without a filename will be shown as `#nil ID`, where ID is the buffer ID.

Shell buffers, like Term will be shown like `#bash ID` or `#zsh ID`
