---@class Rabbit.Entry
---@field class "entry"
---@field ctx? table Any context you like. Rabbit will not touch this.
---@field type string
---@field idx? boolean Whether or not to show the index
---@field _env? Rabbit.Entry._.Environment The environment this entry lives in
---@field actions table
---@field default? boolean Automatically hover over this entry by default

---@class Rabbit.Entry._.Environment
---@field cwd string The current working directory
---@field idx? integer The index of the file in the list
---@field parent? Rabbit.Entry.Collection The parent collection
---@field siblings? Rabbit.Entry[] The siblings
---@field entry? Rabbit.Entry The current entry

---@alias Rabbit.Entry._.Label
---| string # Generic text
---| Rabbit.Term.HlLine # Highlighted text
---| Rabbit.Term.HlLine[] # Highlighted text
