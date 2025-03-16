---@alias Rabbit.Action fun(entry: Rabbit.Entry): nil | Rabbit.Entry | Rabbit.Entry[]

---@alias Rabbit.Action.Callback<T>
---| T # Custom action callback
---| true # Use the default action
---| false # Disable the action altogether

---@alias Rabbit.Response
---| Rabbit.Entry
---| Rabbit.Message
---| nil

---@alias Rabbit.Action.Children fun(entry: Rabbit.Entry.Collection): Rabbit.Entry[]
---@alias Rabbit.Action.Close fun(entry: Rabbit.Entry.Collection): nil
---@alias Rabbit.Action.Rename fun(entry: Rabbit.Entry, new_name: string): string, Rabbit.Entry # Returns the corrected name and the updated entry. When the cursor is moved away from this line, the old entry is automatically replaced with the new one.
---@alias Rabbit.Action.Select fun(entry: Rabbit.Entry): Rabbit.Response
---@alias Rabbit.Action.Delete fun(entry: Rabbit.Entry): Rabbit.Response
---@alias Rabbit.Action.Hover fun(entry: Rabbit.Entry): Rabbit.Response
---@alias Rabbit.Action.Parent fun(entry: Rabbit.Entry): Rabbit.Entry.Collection
