-- Keymap settings
---@class Rabbit.Plugin.Keymap
local KEYS = {
	-- Open Rabbit and spawn the default plugin
	-- Map mode: normal
	---@type string | string[]
	switch = { "<leader>r" },

	-- Select the current entry
	-- Map mode: normal
	---@type string | string[]
	select = { "<CR>", "g" },

	-- Close Rabbit and focus the previous buffer/window
	-- Map mode: normal
	---@type string | string[]
	close = { "q", "<Esc>", "<leader>" },

	-- Delete the current entry
	-- Map mode: normal
	---@type string | string[]
	delete = { "x", "d", "<Del>" },

	-- Create a collection
	-- Map mode: normal
	---@type string | string[]
	collect = { "A" },

	-- Move to the parent collection
	-- Map mode: normal
	---@type string | string[]
	parent = { "-", "<BS>" },

	-- Insert the current file or previously deleted file
	-- Map mode: normal
	---@type string | string[]
	insert = { "a" },

	-- Rename the current entry
	-- Map mode: normal
	---@type string | string[]
	rename = { "i" },

	-- Enter visual-line mode, so you can yank/paste entries
	-- Map mode: normal
	---@type string | string[]
	visual = { "v", "V", "<C-v>" },

	-- Paste entries from visual-line mode
	-- Map mode: normal
	---@type string | string[]
	paste = { "p", "P" },

	-- Yank entries from visual-line mode
	-- Map mode: visual
	---@type string | string[]
	yank = { "y", "Y" },

	-- Cut entries from visual-line mode
	-- Map mode: visual
	---@type string | string[]
	cut = { "x", "X", "<Del>", "d" },
}

return KEYS
