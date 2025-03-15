---@alias Rabbit.Action.Delete: Rabbit.Action
---| Rabbit.Action.Delete.InPlace.Cb # Deletes the entry in-place
---| Rabbit.Action.Delete.Refresh.Cb # Deletes the entry and refreshes the list
---| Rabbit.Action.Delete.Cls

---@class Rabbit.Action.Delete.Cls: Rabbit.Action
---@field action "delete"

---@class Rabbit.Action.Delete.InPlace.Cls: Rabbit.Action.Delete.Cls
---@field in_place true
---@field callback Rabbit.Action.Delete.InPlace.Cb

---@alias Rabbit.Action.Delete.InPlace.Cb fun(entry: Rabbit.Entry): nil # Deletes the entry in-place. This operation is assumed to be successful. If the operation cannot be performed, the action should be disabled beforehand.

---@class Rabbit.Action.Delete.Refresh.Cls: Rabbit.Action.Delete.Cls
---@field in_place false
---@field callback Rabbit.Action.Delete.Refresh.Cb

---@alias Rabbit.Action.Delete.Refresh.Cb fun(entry: Rabbit.Entry): Rabbit.Entry.Collection # Deletes the entry and refreshes the list
