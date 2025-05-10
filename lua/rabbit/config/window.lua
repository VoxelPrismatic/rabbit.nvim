--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

---@class Rabbit.Cls.Spawn.Float
_ = {
	-- Window spawn mode
	---@type "float"
	mode = "float",

	-- Window width
	-- If <1, it is a percentage of the current window
	-- If >1, it is automatically shrunk to fit
	---@type number
	width = 64,

	-- Window height
	-- If <1, it is a percentage of the current window
	-- If >1, it is automatically shrunk to fit
	---@type number
	height = 24,

	-- Where to spawn the floating window
	---@type Rabbit.Enum.Side.Spawn
	side = "se",
	---@alias Rabbit.Enum.Side.Spawn
	---| "nw" # Top left
	---| "n" # Top center
	---| "ne" # Top right
	---| "e" # Right middle
	---| "se" # Bottom right
	---| "s" # Bottom center
	---| "sw" # Bottom left
	---| "w" # Left middle
	---| "c" # Center middle
}

---@class Rabbit.Cls.Spawn.VSplit
_ = {
	-- Window spawn mode
	---@type "split"
	mode = "split",

	-- Where to split the window
	---@type "left" | "right"
	side = "left",

	-- Window width
	-- If <1, it is a percentage of the current window
	-- If >1, it is automatically shrunk to fit
	---@type number
	width = 64,
}

---@class Rabbit.Cls.Spawn.HSplit
_ = {
	-- Window spawn mode
	---@type "split"
	mode = "split",

	-- Where to split the window
	---@type "above" | "below"
	side = "above",

	-- Window height
	-- If <1, it is a percentage of the current window
	-- If >1, it is automatically shrunk to fit
	---@type number
	height = 24,
}

---@class Rabbit.Cls.Spawn.Fullscreen
_ = {
	-- Window spawn mode
	---@type "fullscreen"
	mode = "fullscreen",
}

---@alias Rabbit.Config.Window.Spawn
---| Rabbit.Cls.Spawn.Float # Floating window
---| Rabbit.Cls.Spawn.VSplit # Vertical split
---| Rabbit.Cls.Spawn.HSplit # Horizontal split
---| Rabbit.Cls.Spawn.Fullscreen # Fullscreen

-- Window settings
---@class Rabbit.Config.Window
---@field legend boolean | Rabbit.Config.Window.Legend
local WINDOW = {
	-- Rabbit window spawn position
	---@type Rabbit.Config.Window.Spawn
	---@see Rabbit.Cls.Spawn.Float
	---@see Rabbit.Cls.Spawn.VSplit
	---@see Rabbit.Cls.Spawn.HSplit
	---@see Rabbit.Cls.Spawn.Fullscreen
	spawn = {
		mode = "float",
		width = 64,
		height = 24,
		side = "se",
	},

	-- How to handle overflows and name trimming
	---@class Rabbit.Config.Window.Overflow
	overflow = {
		-- String to use when a line overflows
		-- Ex. "/home/priz/Desktop/git/rabbit.nvim/lua/rabbit/config.lua"
		-- becomes ":::/lua/rabbit/config.lua"
		---@type string
		travel_trunc = ":::",

		-- Maximum distance before trimming
		---@type integer
		travel_max_dist = 5,

		-- String to use when a folder name is too long
		-- Ex. "some-absurdly-long-folder-name"
		-- becomes "some-absurdly…"
		---@type string
		folder_trunc = "…",

		-- What to start truncating when a folder path is too long
		-- Eg "../../some-absurdly/long-folder-name/dest.lua"
		-- --> ".../some…/long…/dest.lua"
		---@type boolean
		folder_fit = true,

		-- Only used when folder_fit=true
		-- When folder names get too short, start truncating the travel path
		---@type integer
		folder_min_len = 4,

		-- Only used when folder_fit=false
		-- Truncate the folder name before checking if the path string is too long
		---@type integer
		folder_max_len = 12,
	},

	-- Extra file info
	---@class Rabbit.Config.Window.Beacon
	---@field lsp Rabbit.Config.Window.Beacon.Lsp | Rabbit.Enum.Diagnostic
	beacon = {
		-- Whether or not to show Buffer IDs, Window IDs, Terminal Process IDs, etc
		---@type boolean
		nrs = false,

		-- Whether or not to indicate if the buffer is read-only
		---@type boolean
		readonly = true,

		-- Whether or not to indicate if the buffer has been modified
		---@type boolean
		modified = true,

		-- How to process LSP diagnostics
		---@class Rabbit.Config.Window.Beacon.Lsp
		lsp = {
			---@type Rabbit.Enum.Diagnostic
			hint = function(data)
				-- I do not consider grammar errors in comments to be worthy of attention. Hell,
				-- Harper doesn't even know "etc"
				if data.source == "Harper" and vim.bo[data.bufnr].filetype ~= "markdown" then
					return false
				end

				return true
			end,

			---@type Rabbit.Enum.Diagnostic
			error = true,

			---@type Rabbit.Enum.Diagnostic
			warn = true,

			---@type Rabbit.Enum.Diagnostic
			info = true,
		},
		---@alias Rabbit.Enum.Diagnostic
		---| true # Show all LSP diagnostics
		---| false # Do not show any LSP diagnostics
		---| fun(data: vim.Diagnostic): boolean # Determine whether to count this specific warning; true = count
	},

	-- Which keys to display. Also
	---@class Rabbit.Config.Window.Legend
	legend = {
		-- Display the close key
		---@type boolean
		close = false,

		-- Display the selection key
		---@type boolean
		select = false,

		-- Display the rename key
		---@type boolean
		rename = true,

		-- Display the delete key
		---@type boolean
		delete = true,

		-- Display the parent key
		---@type boolean
		parent = true,

		-- Display the collect key
		---@type boolean
		collect = true,

		-- Display the insert key
		---@type boolean
		insert = true,

		-- Display the visual key
		---@type boolean
		visual = true,
	},

	-- Whether or not to display a preview of the buffer about to be opened
	---@type boolean
	preview = true,

	-- Synopsis details
	---@class Rabbit.Config.Window.Synopsis
	synopsis = {
		-- When to display synopsis for an entry. Always virtual lines
		---@type
		---| "never" # Never shows synopsis for any entry
		---| "always" # Always shows synopsis for all entries
		---| "hover" # Only show synopsis for the currently hovered entry
		mode = "hover",

		-- Append a newline after synopsis?
		---@type boolean
		newline = false,

		-- Indentation symbol. The last one will be repeated as many times as needed
		---@type string
		tree = "└─",
	},
}

return WINDOW
