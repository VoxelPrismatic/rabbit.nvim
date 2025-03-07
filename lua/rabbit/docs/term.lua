---@class Rabbit.Listing.Entry
---@field type? "file" | "action" The type of listing entry.
---@field color? Color.Term If action, set text color
---@field label? string What the entry is called. If a file, supply the FULL filename.
---@field tail? string | Rabbit.Term.HlLine Right-aligned text after the label.
---@field head? string | Rabbit.Term.HlLine Left-aligned text before the label.
---@field actions? Rabbit.Listing.Actions What to do when a key is pressed. If unset, all actions will be available.
---@field system? boolean Useful for user input so you can distinguish between user entries and plugin-provided entries
---@field ctx? table Any other details you need.
---@field idx? boolean Whether or not to count this towards the index

---@class Rabbit.Listing.Actions
---@field [Rabbit.Actions.Preset] Rabbit.Actions.Entry | boolean Actions applicable to this Listing entry

---@alias Rabbit.Actions.Preset # It is highly recommended to use these keys so the user can set up keybinds in their config.
---| "select" # Select an entry; Open a file or open a collection.
---| "close" # Close Rabbit.
---| "delete" # Delete an entry; Remove a file or cut a collection.
---| "collect" # Create a collection.
---| "parent" # Move to the parent collection.
---| "insert" # Insert the current file or previously deleted file.
---| "help" # Open the keymap legend.
---| "debug" # Open the debug dialog.

---@class Rabbit.Actions.Entry
---@field keys? string | string[] Activate callback when one of these keys are pressed
---@field callback? Rabbit.Action Callback
---@field shown? boolean Whether to show this key in the quick legend at the bottom
---@field title? string Human readable name
---@field priority? integer Priority of this action. This signifies the order in which they are shown

---@alias _Str string | string[]

---@class Rabbit.Config.Keymap
---@field select _Str Select an entry; Open a file or open a collection.
---@field close _Str Close Rabbit.
---@field delete _Str Delete an entry; Remove a file or cut a collection.
---@field collect _Str Create a collection.
---@field parent _Str Move to the parent collection.
---@field insert _Str Insert the current file or previously deleted file.
---@field help _Str Open the keymap legend.
---@field debug _Str Open the debug dialog.
---@field open _Str Open Rabbit.
---@field [string] _Str Keybindings

---@alias Rabbit.Action fun(idx: integer, entry: Rabbit.Listing.Entry, listing: Rabbit.Listing.Entry[])

---@class Rabbit.Plugin.Actions
---@field [string] Rabbit.Action
