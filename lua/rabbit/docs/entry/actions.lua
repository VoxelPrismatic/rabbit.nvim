---@alias Rabbit.Action fun(entry: Rabbit.Entry): nil | Rabbit.Entry | Rabbit.Entry[]

---@alias Rabbit.Action.Callback<T>
---| T # Custom action callback
---| true # Use the default action
---| false # Disable the action altogether

---@alias Rabbit.Response
---| Rabbit.Entry # Display an entry
---| Rabbit.Message # Display a message
---| nil # Close rabbit
---| false # Do absolutely nothing
