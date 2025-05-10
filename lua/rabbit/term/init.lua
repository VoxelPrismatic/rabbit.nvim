--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

return {
	STACK = require("rabbit.term.stack"),
	BOX = require("rabbit.term.border"),
	HL = require("rabbit.term.highlight"),
	RECT = require("rabbit.term.rect"),
	UI = require("rabbit.term.listing"),
}
