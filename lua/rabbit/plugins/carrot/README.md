[rabbit.carrot]: https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FVoxelPrismatic%2Frabbit.nvim%2Frefs%2Fheads%2Frewrite%2Flua%2Frabbit%2Fplugins%2Fcarrot%2FVERSION.json&query=%24.latest&style=flat&label=carrot&labelColor=white&color=yellow

# Carrot ![version][rabbit.carrot]
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

> [!NOTE]
> This plugin requires the `trail` plugin, and it will be loaded automatically.

## Migrating from Harpoon

If you want similar keybinds, like `harpoon.ui:nav_file(n)`, you may set up the following:

```lua
local carrot = require("rabbit.plugins.carrot.script")

-- Any series of selections can be passed to select_fn
vim.keymap.set("n", "<C-h>", carrot.select_fn(1))
vim.keymap.set("n", "<C-t>", carrot.select_fn(2, 2))

-- The first parameter may a custom scope fn like `cwd` above
-- If not, it will evaluate the existing `cwd` fn
vim.keymap.set("n", "<C-n>", carrot.select_fn("custom_env", 3, 3, 3))
vim.keymap.set("n", "<C-s>", carrot.select_fn(vim.fn.getcwd, 4, 4, 4, 4))
```

> [!NOTE]
> 1. `select_fn(...)` does not dynamically update if you move entries around.
> 2. If the target selection is not a file, Rabbit will spawn, showing the last valid location
> 3. If the target selection is a file, then the file is opened in the current window, no questions asked


## Change log
- `r0.0b1`: Apr 16, 2025
	- Fixed Bugs
		- No longer hangs on cyclical collections
		- Actually scope properly
		- Now renames the first collection when hovering over the 'up' entry
	- Known Issues
		- *none*
	- New Features
		- Visual has been implemented; All pasted collections are deep-copied
		- Creating a collection no longer moves you up to the top
		- Reduce chances of ID collisions
		- Scripting to help migrate from Harpoon
- `r0.0a4`: Apr 15, 2025
	- Fixed Bugs
		- *none*
	- Known Issues
		- *none*
	- New Features
		- You may rename files
		- Renamed files show a little filetype icon
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
