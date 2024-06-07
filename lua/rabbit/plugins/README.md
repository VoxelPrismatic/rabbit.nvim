[history]: https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FVoxelPrismatic%2Frabbit.nvim%2Fmain%2Flua%2Frabbit%2Fplugins%2FVERSION.json&query=%24.history&label=History&labelColor=white&color=yellow
[oxide]: https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FVoxelPrismatic%2Frabbit.nvim%2Fmain%2Flua%2Frabbit%2Fplugins%2FVERSION.json&query=%24.oxide&label=Oxide&labelColor=white&color=yellow
[harpoon]: https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FVoxelPrismatic%2Frabbit.nvim%2Fmain%2Flua%2Frabbit%2Fplugins%2FVERSION.json&query=%24.harpoon&label=Harpoon&labelColor=white&color=yellow
[reopen]: https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FVoxelPrismatic%2Frabbit.nvim%2Fmain%2Flua%2Frabbit%2Fplugins%2FVERSION.json&query=%24.reopen&label=Reopen&labelColor=white&color=yellow

# Plugins
This describes the currently available plugins and their configuration options

## History ![history][history]
Sorts all the buffers this window has visited, in order of most recent visit
```lua
require("rabbit").setup({
    plugins_opts = { history = { opts = { ---@type Rabbit.Plugin.History.Options
        ignore_unlisted = true,     -- Ignore buffers that are unlisted, eg :Oil
    }}}
})
```
<details>
    <summary><h3>Changelog</h3></summary>
    <ul>
        <li>
            <b>v2</b>
            <ul>
                <li>You can now recover the history of the most recently closed window</li>
                <li>Added the <code>ignore_unlisted</code> option</li>
            </ul>
        </li>
        <li>
            <b>v1</b>
            <ul>
                <li>Initial verson</li>
            </ul>
        </li>
    </ul>
</details>
<hr/>


## Reopen ![reopen][reopen]
Sorts all the buffers this window has closed, in order of most recent close
```lua
-- No options supported
```
<details>
    <summary><h3>Changelog</h3></summary>
    <ul>
        <li>
            <b>v2</b>
            <ul>
                <li>You can now reopen all the files of your last session in the current directory</li>
            </ul>
        </li>
        <li>
            <b>v1</b>
            <ul>
                <li>Initial verson</li>
            </ul>
        </li>
    </ul>
</details>
<hr/>

## Oxide ![oxide][oxide]
Like zoxide, but saves how often you open a particular file from your current directory
```lua
require("rabbit").setup({
    plugins_opts = { oxide = { opts = { ---@type Rabbit.Plugin.Oxide.Options
        maxage = 1000,              -- Like zoxide's AGING algorithm
        ignore_opened = true,       -- Do not display currently open buffers
    }}}
})
```
<details>
    <summary><h3>Changelog</h3></summary>
    <ul>
        <li>
            <b>v3</b>
            <ul>
                <li>Added <code>ignore_opened</code> option</li>
                <li>No longer redraws the entire window upon delete</li>
                <li>Switched storage to dir:file instead of file:dir</li>
            </ul>
        </li>
        <li>
            <b>v2</b>
            <ul>
                <li>Separates by current working directory</li>
            </ul>
        </li>
        <li>
            <b>v1</b>
            <ul>
                <li>Initial verson</li>
            </ul>
        </li>
    </ul>
</details>
<hr/>


## Harpoon ![harpoon][harpoon]
Like [ThePrimeagen/Harpoon](https://github.com/ThePrimeagen/harpoon/tree/harpoon2), as far as I know.
```lua
require("rabbit").setup({
    plugins_opts = { harpoon = { opts = { ---@type Rabbit.Plugin.Harpoon.Options
        ignore_opened = false,       -- Do not display currently open buffers
    }}}
})
```
<details>
    <summary><h3>Changelog</h3></summary>
    <ul>
        <li>
            <b>v1.1</b>
            <ul>
                <li>
                    Fixed a bug where you could duplicate entries out of bounds
                    <br><sub><i>I had the right code, just in the wrong spot :facepalm:</i></sub>
                </li>
            </ul>
        </li>
        <li>
            <b>v1</b>
            <ul>
                <li>Initial verson</li>
            </ul>
        </li>
    </ul>
</details>
<hr/>
