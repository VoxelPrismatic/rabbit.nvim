--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

---@class Rabbit*Trail.Environment: Rabbit.Plugin.Environment
local ENV = {
	---@type boolean
	-- Indicates if the user has navigated from the Major window
	from_major = false,
}
return ENV
