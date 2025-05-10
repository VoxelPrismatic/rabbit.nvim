--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

---@class Rabbit.Message.Menu: Rabbit.Message
---@field type "menu"
---@field title string Menu title
---@field color? string Border color highlight group
---@field msg? string | Rabbit.Term.HlLine Message
---@field options Rabbit.Message.Menu.Option[]
---@field immediate? boolean If only one option, process immediately. Default: false

---@class (exact) Rabbit.Message.Menu.Option
---@field label string Label
---@field callback fun(...): Rabbit.Response
---@field args? any[] Arguments to pass to the callback
---@field icon? string Icon
---@field color? string Color of the label
