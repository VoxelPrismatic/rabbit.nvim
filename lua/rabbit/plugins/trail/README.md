# Trail
### Navigate the trail of previously visited buffers

Rabbit Trail lists the buffers you've visited in the order of most recent, and
split by window. This way, a simple keybind, `‣r↵`, will take you to the
previous buffer. You may also choose *which* window to open. A preview is shown
for the target window, displaying the target buffer precisely how you'd see it.
Now, you don't have to mentally switch contexts when opening buffers!

## Configuration

```lua
---@class (exact) Rabbit*Trail.Options: Rabbit.Plugin.Options
local PLUGIN_CONFIG = {
    -- Default border color
    ---@type string
	color = "#d875a7",

	keys = {
        -- Keybind to open the Trail plugin from within Rabbit
        ---@type string
		switch = "t",
	},

    -- Ignore unlisted buffers, like Oil and Lazy
    ---@type boolean
	ignore_unlisted = true,

    -- Sort windows by name
    ---@type boolean
	sort_wins = true,
}
```

## Change Log
- `r00b1`: Apr 04, 2025
  - Fixed Bugs
    - Deleting a closed buffer will soft-crash Rabbit and close the current window
  - Known Issues
    - *none*
  - New Features
    - When navigating from the window selection screen, the window's most recent
    buffer will be selected by default, instead of the second-most recent buffer
    - You may now sort windows by display name
- `r00a5`: Apr 02, 2025
  - Fixed Bugs
    - Attempting to copy a closed window will crash
  - Known Issues
    - *none*
  - New Features
    - You may now copy specific parts of history to new windows
    - Visual selection
- `r00a4`: Mar 29, 2025
  - Fixed Bugs
    - *none*
  - Known Issues
    - Attempting to copy a closed window will crash
  - New Features
    - You are now prompted when trying to close a modified buffer
- `r00a3`: Mar 25, 2025
  - Fixed Bugs
    - *none*
  - Known Issues
    - Attempting to copy a closed window will crash
  - New Features
    - You may now delete closed buffers
    - You may now delete closed windows
    - You may now close saved buffers
- `r00a2`: Mar 19, 2025
  - Fixed Bugs
    - Trail now ignores all events when Rabbit is open
    - Previewing buffers no longer breaks the buffer order
  - Known Issues
    - *none*
  - New Features
    - Implemented the Rename action, imitating Oil's insert behavior
    - Implemented the Parent action; quickly jump to the parent collection
- `r00a1`: Mar 15, 2025
  - Fixed Bugs
    - *none*
  - Known Issues
    - *none*
  - New Features
    - Initial release
    - Legacy:History and Legacy:Reopen have been merged into Rewrite:Trail
    - Trail allows you to select which window to open
    - Trail displays a preview of what you're about to open and where
