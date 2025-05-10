--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

local UI = require("rabbit.term.listing")

---@param data Rabbit.Message.Redraw
return function(data)
	UI.redraw_entry(data.entry)
end
