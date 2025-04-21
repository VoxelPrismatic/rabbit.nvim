---@class (exact) Rabbit.Entry.Search: Rabbit.Entry
---@field type "search"
---@field label Rabbit.Entry._.Label The entry label.
---@field fields Rabbit.Entry.Search.Fields[]
---@field actions Rabbit.Entry.Collection.Actions

---@class Rabbit.Entry.Search.Fields
---@field name string Name of the field, eg "search" or "filter".
---@field default string Text content to pre-fill when the window is spawned.
---@field icon string Icon to display after the search box,
---@field on_switch (fun(): Rabbit.Response)? A function that is called when the user switches to this field.
---@field status (fun(): Rabbit.Entry.Search.Status)? A function that returns the status of the search box. This field is automatically provided by Rabbit for your convenience.

---@class Rabbit.Entry.Search.Status
---@field content string Text content of the search box
---@field open boolean Whether the search box is currently open
