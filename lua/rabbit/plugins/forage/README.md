[rabbit.forage]: https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FVoxelPrismatic%2Frabbit.nvim%2Frefs%2Fheads%2Frewrite%2Flua%2Frabbit%2Fplugins%2Fforage%2FVERSION.json&query=%24.latest&style=flat&label=forage&labelColor=white&color=yellow

# Forage ![version][rabbit.forage]
### Forage through the filesystem until you find what you're looking for

Rabbit Forage is a plugin that allows you to search the filesystem for files
using various tools like ripgrep, fzf, and find. It also features a list of
your frequently accessed files, sorted using Zoxide's algorithm.

> [!NOTE]
> fzf, rg, and find are not implemented yet. It is only the Zoxide algorithm
> for now.

## Configuration
```lua
---@class (exact) Rabbit*Forage.Options: Rabbit.Plugin.Options
local PLUGIN_CONFIG = {
    -- Default border color
    ---@type string
    color = "#33b473",

    keys = {
        -- Keybind to open the Forage plugin from within Rabbit
        ---@type string
        switch = "f",
    },

    -- Enable fuzzy find with `fzf`
    -- NOTE: fzf is not implemented yet
    ---@type boolean
    fuzzy = true,

    -- Enable grep-based search with `rg`
    -- NOTE: rg is not implemented yet
    ---@type boolean
    grep = true,

    -- Enable classic-find with `find`
    -- NOTE: find is not implemented yet
    ---@type boolean
    find = true,

    -- Length of search history. Set to 0 to disable history
    -- NOTE: Search algorithms are not implemented yet
    ---@type integer
    history = 128,

    ---@class (exact) Rabbit*Forage.Options.Oxide
    oxide = {
        -- Maximum age of a frequently accessed file, similar to Zoxide's AGING algorithm
        ---@type integer
        max_age = 1000,

        -- Do not display files outside of the current working directory
        -- NOTE: This only works if the `cwd` function returns a directory.
        --       If not, then this option is ignored.
        ---@type boolean
        children_only = true,
    },

    -- Scope directory, eg use the git project folder, if it exists
    ---@type string | fun(): string
    cwd = require("rabbit.util.paths").git,
}
```

## Change log
- `r0.0a2`: Apr 27, 2025
    - Fixed Bugs
        - Oxide move to top upon delete
        - Oxide not saving
        - Oxide erroneous sort
        - Oxide crashing if deleted file during session
    - Known Issues
        - *none*
    - New Features
        - Ripgrep search!
        - Ripgrep warns if `rg` is not available
- `r0.0a1`: Apr 15, 2025
    - Fixed Bugs
        - *none*
    - Known Issues
        - *none*
    - New Features
        - Initial release
        - Implemented oxide

