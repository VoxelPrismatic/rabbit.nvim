# Carrot
### Place carrots next to your favorite files for quick access

Rabbit Carrot lists your favorite buffers in any order you like, including in
sub-collections. This aims to mirror functionality of ThePrimeagen's Harpoon.
You may also select the color of each collection, further organizing your
workspace. By default, Carrot tries to find your git directory so that your
workspace remains consistent across different parts of your project.

## Configuration

```lua
---@class (exact) Rabbit*Carrot.Options: Rabbit.Plugin.Options
local PLUGIN_CONFIG = {
    -- Default border color
    ---@type string
    color = '#696ac2",

    keys = {
        -- Keybind to open the Carrot plugin from within Rabbit
        ---@type string
        switch = "h",
    },

    -- How your last collection should be remembered
    ---@type
    ---| "global" # All buffers and windows share the same list.
    ---| "buffer" # Each buffer will remember its last collection.
    ---| "window" # Each window will remember its last collection.
    ---| "never" # Always return the root collection. Recommended for building muscle memory.
    separate = "never",

    -- Default color for new collections
    ---@type Rabbit.Colors.Paint
    default_color = "iris",

    -- Scope project directory
    cwd = require("rabbit.util.paths").git,
}
```

## Change log
- `r0.0a3`: Apr 14, 2025
  - Fixed Bugs
    - *none*
  - Known Issues
    - Visual doesn't work
  - New Features
    - You may now change the collection color
    - You may now cancel rename with `<Esc>`
    - You may now never separate, choosing to always return the root collection
- `r0.0a2`: Mar 29, 2025
  - Fixed Bugs
    - Erroneously adding a file or collection to below the current selection
  - Known Issues
    - You may not change the collection color
  - New Features
    - You may now delete files and collections
    - Removed: Unnecessary conflicts options; You may not have duplicate collections
    - Removed: Unnecessary 'ignore opened' option; This breaks muscle memory. Rabbit now displays if a buffer is closed anyway
- `r0.0a1`: Mar 21, 2025
  - Fixed Bugs
    - *none*
  - Known Issues
    - *none*
  - New Features
    - Initial release
