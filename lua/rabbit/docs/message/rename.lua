--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

---@class Rabbit.Message.Rename: Rabbit.Message
---@field type "rename"
---@field apply fun(entry: Rabbit.Entry, new_name: string): string Returns the corrected name, but also immediately applies the change to the entry object.
---@field check fun(entry: Rabbit.Entry, new_name: string): string Returns the corrected name. Does not apply the change yet
---@field name string Existing name of the entry.
---@field color Rabbit.Message.Color | false Immediately handles this callback after the entry is done being renamed
---@field entry? Rabbit.Entry The entry being renamed. This is optional.
