# Plugins
This describes the currently available plugins and their configuration options

## History
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
    <ol>
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
    </ol>
</details>


## Reopen
Sorts all the buffers this window has closed, in order of most recent close
```lua
-- No options supported
```
<details>
    <summary><h3>Changelog</h3></summary>
    <ol>
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
    </ol>
</details>


## Oxide
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
    <ol>
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
    </ol>
</details>


## Harpoon
Like [ThePrimeagen/Harpoon][harpoon2], as far as I know.
```lua
require("rabbit").setup({
    plugins_opts = { harpoon = { opts = { ---@type Rabbit.Plugin.Harpoon.Options
        ignore_opened = false,       -- Do not display currently open buffers
    }}}
})
```
<details>
    <summary><h3>Changelog</h3></summary>
    <ol>
        <li>
            <b>v1</b>
            <ul>
                <li>Initial verson</li>
            </ul>
        </li>
    </ol>
</details>
[harpoon2]: https://github.com/ThePrimeagen/harpoon/tree/harpoon2
