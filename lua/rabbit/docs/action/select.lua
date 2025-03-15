---@alias Rabbit.Action.Select
---| Rabbit.Action.Select.Cb # Shorthand for the class definition
---| Rabbit.Action.Select.Cls

---@alias Rabbit.Action.Select.Cb fun(entry: Rabbit.Entry): nil

---@class Rabbit.Action.Select.Cls: Rabbit.Action
---@field action "select"
---@field callback Rabbit.Action.Select.Cb
