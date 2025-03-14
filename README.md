[rabbit.history]: https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FVoxelPrismatic%2Frabbit.nvim%2Fmain%2Flua%2Frabbit%2Fplugins%2FVERSION.json&query=%24.history&label=History&labelColor=white&color=yellow
[rabbit.oxide]: https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FVoxelPrismatic%2Frabbit.nvim%2Fmain%2Flua%2Frabbit%2Fplugins%2FVERSION.json&query=%24.oxide&label=Oxide&labelColor=white&color=yellow
[rabbit.harpoon]: https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FVoxelPrismatic%2Frabbit.nvim%2Fmain%2Flua%2Frabbit%2Fplugins%2FVERSION.json&query=%24.harpoon&label=Harpoon&labelColor=white&color=yellow
[rabbit.reopen]: https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FVoxelPrismatic%2Frabbit.nvim%2Fmain%2Flua%2Frabbit%2Fplugins%2FVERSION.json&query=%24.reopen&label=Reopen&labelColor=white&color=yellow
[wiki.harpoon]: https://github.com/VoxelPrismatic/rabbit.nvim/wiki/Plugin:-Harpoon
[wiki.history]: https://github.com/VoxelPrismatic/rabbit.nvim/wiki/Plugin:-History
[wiki.reopen]: https://github.com/VoxelPrismatic/rabbit.nvim/wiki/Plugin:-Reopen
[wiki.oxide]: https://github.com/VoxelPrismatic/rabbit.nvim/wiki/Plugin:-Oxide

<div align="center">
    <img src="/rabbit.png" width="368" alt="logo"/>
    <h2 id="rabbitnvim">Jump between buffers faster than ever before</h2>
    <a href="https://github.com/VoxelPrismatic/rabbit.nvim/releases/latest"><img
        src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fapi.github.com%2Frepos%2FVoxelPrismatic%2Frabbit.nvim%2Freleases%2Flatest&query=%24.tag_name&style=flat&label=Rabbit&labelColor=white&logo=vowpalwabbit&logoColor=black"
    /></a>
    <a href="https://neovim.io/" target="_blank"><img
        src="https://img.shields.io/badge/Neovim-v0.10.4-brightgreen?style=flat&labelColor=white&logo=neovim&logoColor=black"
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
        src="https://img.shields.io/badge/Support-white?style=flat&logo=patreon&logoColor=white&labelColor=red"
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
  - [![history][rabbit.history]][wiki.history]
  - [![reopen][rabbit.reopen]][wiki.reopen]
  - [![oxide][rabbit.oxide]][wiki.oxide]
  - [![harpoon][rabbit.harpoon]][wiki.harpoon]
- [API](https://github.com/voxelprismatic/rabbit.nvim/wiki/API-Documentation)
- [Custom Plugin](https://github.com/voxelprismatic/rabbit.nvim/wiki/Custom-Plugin)

---

This tool tracks the history of buffers opened in an individual window. With a quick
motion, you can be in any one of your last twenty buffers without remembering any
details.

Unlike other tools, this remembers history *per window*, so you can really jump
quickly.

<br><br>
## Why

<ul>
    <li>

### [Harpoon][harpoon2]
- Harpoon requires explicit adding of files; too much effort
  - Rabbit:Oxide remembers your most frequently accessed files in your current directory

</li>
<li>

### [Telescope][tj_tele]
- Telescope:Buffers doesn't order by last BufEnter
  - Rabbit:History lists in order of most recent BufEnter
  - Rabbit:History does NOT list the file you're currently in, meaning a lightning-quick motion,
    `<leader>r` `<CR>` returns you to whence you came.

</li>
<li>

### `:ls` and `:b`
- Too much typing and looking and processing
  - That's what this plugin is designed to solve

</li>
<li>

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

</li></ul>

<br><br>

## Active Development
I know this project looks stalled, but that's because I think it's about perfect as-is! Feel free
to open an issue.

<br><br>

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
> Rabbit is only tested on the latest version of Neovim, which is detailed at the top of the readme.
> If your version of Neovim is significantly older, bite the bullet and upgrade.

<br><br>

## Usage
Just run your keybind! (or `:Rabbit {{mode}}`)

With Rabbit open, you can hit a number 1-9 to jump to that buffer. You can
also move your cursor down to a specific line and hit enter to jump to that buffer.

If you hit `<CR>` immediately after launching Rabbit, it'll open your previous buffer.
You can hop back and forth between buffers very quickly, almost like a rabbit...

If you scroll down on the Rabbit window, you'll see all the keybinds available.

<br><br>

## Preview

[2024-05-30 15-36-13.webm](https://github.com/VoxelPrismatic/rabbit.nvim/assets/45671764/eee4a60c-1302-469b-a329-471bfc59cddf)

<br><br>

## Configuration
> [!NOTE]
> Be sure to use an LSP, like `lua_ls`. I have all the types created for your convenience.

<details>
    <summary><h3>Rabbit.Options</h3></summary>

| key | type | description | default |
|-|-|-|-|
| colors | [Rabbit.Options.Colors](#rabbitoptionscolors) | Colors used by Rabbit | `{ ... }` |
| window | [Rabbit.Options.Window](#rabbitoptionswindow) | Window options | `{ ... }` |
| default_keys | [Rabbit.Keymap](#rabbitkeymap) | Keys and things | `{ ... }` |
| plugin_opts | [Rabbit.Options.Plugin_Options](#rabbitoptionsplugin_options) | Plugin options | `{ ... }` |
| enable | `string[]` | Which **builtin** plugins to enable immediately<br>*\*first plugin is considered default* | history,<br/>reopen,<br/>oxide,<br/>harpoon |
| path_key | `str` \| `func():str` | Scope directory, [wiki][path_key] | `vim.fn.getcwd` |

<br><br>
</details>

[path_key]: https://github.com/VoxelPrismatic/rabbit.nvim/wiki/Custom-Path-Key

<details>
    <summary><h3>Rabbit.Options.Colors</h3></summary>

| rabbit | popup |
|-|-|
| ![image](https://github.com/VoxelPrismatic/rabbit.nvim/assets/45671764/5b441d5c-b6a9-4173-a762-f5361d984ee8) | ![image](https://github.com/user-attachments/assets/c87b4d63-7c2e-4d54-87bb-6b156d933b8b) |


| key | type | description | default |
|-|-|-|-|
| title | `string` \| `NvimHlKwargs` | Title text | `#526091`,<br>**bold** |
| index | `string` \| `NvimHlKwargs` | Index | `#7581ab`,<br>*italic* |
| dir | `string` \| `NvimHlKwargs` | Directory | `#9396bd` |
| file | `string` \| `NvimHlKwargs` | File | `#526091` |
| term | `string` \| `NvimHlKwargs` | Terminal | `#40c9a2`,<br>*italic* |
| noname | `string` \| `NvimHlKwargs` | No Name | `#d08e95`,<br>*italic* |
| message | `string` \| `NvimHlKwargs` | Message | `#8aaacd`,<br>***bold ital*** |
| <i>popup</i>.error | `string` \| `NvimHlKwargs` | Border color of popup message | `#d87576`,<br>**bold** |
| <i>popup</i>.warning | `string` \| `NvimHlKwargs` | Border color of popup message | `#b4b433`,<br>**bold** |
| <i>popup</i>.info | `string` \| `NvimHlKwargs` | Border color of popup message | `#696ac2`,<br>**bold** |

note: default colors listed here are from my color theme. rabbit will automatically
pull your color theme using several highlight groups, eg `Normal` or `Comment`

<br><br>
</details>

<details>
    <summary><h3>Rabbit.Options.Window</h3></summary>

![image](https://github.com/VoxelPrismatic/rabbit.nvim/assets/45671764/0783b721-47bc-4779-b129-55225b7455ba)

| key | type | description | default |
|-|-|-|-|
| box | [Rabbit.Box](#rabbitbox) | Border box | Round |
| box_style | `"round"` \| `"thick"` \| <br>`"square"` \| `"double"` | Border box style | `round` |
| title | `string` | The plugin title, if you don't like Rabbit | `Rabbit` |
| width | `integer` | Window width | 64 |
| height | `integer` | Window height | 24 |
| overflow | `string` | Characters to display when the dir path is too long | `:::` |
| path_len | `integer` | Maximum length of a path segment | 12 |
| float | { `"bottom"` \| `"top"`,<br>`"left"`, `"right"` }<br>\| `"center"`<br>\| `false` | Floating position. If set to `false`, will try to split<br>*note: bottom or top **must** precede left or right* | `{ "bottom", "right" }` |
| split | `"left"` \| `"right"` \|<br>`"above"` \| `"below"` \|<br>`false` | Split window position. If set to `false`, will occupy full screen. Only available if `float` is set to `false` | `right` |
| plugin_name_position | `"bottom"` \| `"title"` \| `"hide"` | Where to place the plugin name | `bottom` |

<br><br>
</details>

<details>
    <summary><h3>Rabbit.Box</h3></summary>

| key | type | description |
|-|-|-|
| top_left | `string` | Top left corner of the box |
| top_right | `string` | Top right corner of the box |
| horizontal | `string` | Horizontal ceiling |
| vertical | `string` | Vertical wall |
| bottom_left | `string` | Bottom left corner of the box |
| bottom_right | `string` | Bottom right corner of the box |
| emphasis | `string` | Title emphasis character |

<br><br>
</details>

<details>
    <summary><h3>Rabbit.Keymap</h3></summary>

| key | type | description | default |
|-|-|-|-|
| close | `string[]` | Keys to close Rabbit | `<Esc>`, `q`, `<leader>` |
| select | `string[]` | Keys to select an entry | `<Enter>` |
| open | `string[]` | Keys to open Rabbit<br>*this is how Rabbit will open* | `<leader>r` |
| file_add | `string[]` | Keys to add the current file to a collection | `a` |
| file_del | `string[]` | Keys to delete the current file from a collection | `<Del>` |
| group | `string[]` | Keys to create a new collection | `A` |
| group_up | `string[]` | Keys to move to the parent collection | `-` |

<br><br>
</details>

<details>
    <summary><h3>Rabbit.Options.Plugin_Options</h3></summary>

**Note:** The key should be the plugin name, with the value being the table described below

| key | type | description | example |
|-|-|-|-|
| color | `string` | Border color | `#00ffff` |
| switch | `string` | Key to switch to this plugin from within Rabbit | `o` |
| opts | `table` | Any plugin-specific options. | `{}` |

See the [wiki](https://github.com/VoxelPrismatic/rabbit.nvim/wiki) for the various plugins' options.

<br><br>
</details>

<details>
    <summary><h3>Default config</h3></summary>

**Please do not copy this config**, it is the default.

```lua
-- Use all the below defaults, but set a custom keybind
require("rabbit").setup("any keybind")

-- Defaults
require("rabbit").setup({
    colors = {
        title = { fg = grab_color("Normal"), bold = true },
        index = { fg = grab_color("Comment"), italic = true },
        dir = { fg = grab_color("NonText") },
        file = { fg = grab_color("Normal") },
        term = { fg = grab_color("Constant"), italic = true },
        noname = { fg = grab_color("Function"), italic = true },
        message = { fg = grab_color("Identifier"), italic = true, bold = true },
    },
    window = {
        box = box.round,
        title = "Rabbit",
        plugin_name_position = "bottom",
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
        file_del = { "<Del>" },
        group = { "A" },
        group_up = { "-" },
    },
    plugin_opts = {},
    enable = {
        "history",
        "reopen",
        "oxide",
        "harpoon",
    },
})
```
</details>
