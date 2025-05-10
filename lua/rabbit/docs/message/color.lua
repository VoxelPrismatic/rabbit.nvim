--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

---@class Rabbit.Message.Color: Rabbit.Message
---@field type "color"
---@field color string Current color
---@field apply fun(entry: Rabbit.Entry, new_color: string) Sets the color of the entry
