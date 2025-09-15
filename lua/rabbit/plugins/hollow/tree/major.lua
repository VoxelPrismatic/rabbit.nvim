--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

local LIST = require("rabbit.plugins.hollow.list")
local TREE
---@param key string
local function from_key(key)
	TREE = TREE or require("rabbit.plugins.hollow.tree")
end
