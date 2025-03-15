---@class Rabbit.Action.Rename: Rabbit.Action
---@field action "rename"
---@field validate fun(entry: Rabbit.Entry, new_name: string): string Validates the name and applies any corrections immediately. If the returned string is not the same as the input string, the name will be highlighted in red.<br>A different return value will NOT prevent the user from submitting.

---@class Rabbit.Action.Rename.InPlace: Rabbit.Action.Rename
---@field in_place true
---@field callback fun(entry: Rabbit.Entry, new_name: string): Rabbit.Entry Renames the entry in-place. Only this entry will be refreshed.

---@class Rabbit.Action.Rename.Refresh: Rabbit.Action.Rename
---@field in_place false
---@field callback fun(entry: Rabbit.Entry, new_name: string): Rabbit.Entry.Collection Renames the entry and refreshes the list. This is useful if you sort the list in any particular manner
