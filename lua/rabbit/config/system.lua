--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

-- Other rabbit system settings
---@class Rabbit.Config.System
local SYS = {
	---@type string
	-- The path to the data directory
	data = vim.fn.stdpath("data") .. "/rabbit",

	---@type string
	-- Rename Rabbit to a custom name
	name = "Rabbit",

	-- When wrapping words, specify the maximum length of the word
	-- before breaking into syllables. To disable, set to something
	-- obscenely large like 10000. If <1, it is treated as a percentage
	-- of the window width
	---@type number
	wrap = 0.1,

	-- Default delay in ms when calling vim.defer_fn. If your system
	-- is slow, you may want to increase this
	defer = 5,

	-- Maximum number of search results to display before quitting.
	-- Set to an obscenely large number to disable the limit.
	-- For slower systems, use a lower number.
	-- NOTE: Due to limitations, you may not receive the maximum set here,
	-- however, only the first `max_results` will be processed.
	---@type number
	max_results = 150,

	-- Display relpaths relative to the current buffer
	---@type boolean
	relative_to_buffer = false,
}

-- Default scoping function
---@return string
function SYS.cwd()
	-- By default, we want to use the git directory.
	-- This function automatically falls back to cwd if there is no git repo
	return require("rabbit.util.paths").git()
end

return SYS
