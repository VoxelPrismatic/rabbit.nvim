---@class (exact) Rabbit.Entry.Collection: Rabbit.Entry
---@field type "collection"
---@field label Rabbit.Entry._.Label The path to the file.
---@field tail? Rabbit.Entry._.Label Any right-aligned context you want to show
---@field actions Rabbit.Entry.Collection.Actions The actions to perform on the file.

---@class Rabbit.Entry.Collection.Actions
---@field select Rabbit.Action.Callback<Rabbit.Action.Select>
---@field delete Rabbit.Action.Callback<Rabbit.Action.Delete>
---@field children Rabbit.Action.Callback<Rabbit.Action.Children>
