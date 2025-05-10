--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

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
