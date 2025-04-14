# Index
### List all the plugins you have installed

This is the default listing shown if you don't have a default plugin selected

## Configuration

```lua
---@class (exact) Rabbit*Trail.Options: Rabbit.Plugin.Options
local PLUGIN_CONFIG = {
    -- Default border color
    ---@type string
	color = "#8983ad",

	keys = {
        -- Keybind to open the Index plugin from within Rabbit
        ---@type string
		switch = "?",
	},
}
```

## Change Log
- `r1.0`: Mar 15, 2025
  - Initial release
