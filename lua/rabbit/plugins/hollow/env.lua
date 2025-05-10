--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

---@class Rabbit*Hollow.Environment: Rabbit.Plugin.Environment
local ENV = {
	-- Last seen cwd
	---@type string
	last_cwd = "",
}
return ENV
