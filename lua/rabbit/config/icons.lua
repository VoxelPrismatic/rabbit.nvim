--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

-- Icons for various things
---@class Rabbit.Config.Icons
local ICONS = {
	-- Icon for modified buffers
	---@type string
	modified = "•",

	-- Icon for read-only buffers
	---@type string
	readonly = "",

	-- Icon for LSP hints
	---@type string
	lsp_hint = "󱐋",

	-- Icon for LSP info
	---@type string
	lsp_info = "",

	-- Icon for LSP warnings
	---@type string
	lsp_warn = "󰔶",

	-- Icon for LSP errors
	---@type string
	lsp_error = "",

	-- Icon for writing files
	---@type string
	file_write = "",

	-- Icon for deleting files or ignoring changes
	---@type string
	file_delete = "󰆴",

	-- Icons for field selections, eg "◙ ○" (the former is selected)
	---@type string
	select_left = "",
	---@type string
	select_right = "",

	-- Icon for going to the parent collection
	---@type string
	entry_up = "⮭",
}

return ICONS
