---@class (exact) Rabbit*Harpoon.Options: Rabbit.Plugin.Options
---@field default_color Rabbit.Colors.Paint Color to use for new collections
---@field ignore_opened boolean Do not list opened buffers
---@field conflict Rabbit*Harpoon.Options.Conflicts How to handle conflicts
---@field by_buffer boolean Separate Harpoon listings by buffer

---@class (exact) Rabbit*Harpoon.Options.Conflicts
---@field parent Rabbit*Harpoon.Options.Conflicts.Enum Default action to perform when you move a collection into itself.
---@field copy Rabbit*Harpoon.Options.Conflicts.Enum Default action to perform when you copy an existing collection.

---@alias Rabbit*Harpoon.Options.Conflicts.Enum
---| "copy" # Copy the collection and rename it
---| "move" # Move the old collection to the new spot
---| "prompt" # Display a message box and let the user choose

---@type Rabbit*Harpoon.Options
local PLUGIN_CONFIG = {
	color = "#696ac2",
	default_color = "iris",
	ignore_opened = false,
	by_buffer = false,
	conflict = {
		parent = "move",
		copy = "move",
	},
	keys = {
		switch = "h",
	},
	cwd = require("rabbit.util.paths").git,
}

return PLUGIN_CONFIG
