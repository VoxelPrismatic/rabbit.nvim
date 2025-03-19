---@class Rabbit.Message.Rename: Rabbit.Message
---@field type "rename"
---@field apply fun(entry: Rabbit.Entry, new_name: string): string Returns the corrected name, but also immediately applies the change to the entry object.
---@field name string Existing name of the entry.
---@field color boolean Whether to display a color selector at the end.
