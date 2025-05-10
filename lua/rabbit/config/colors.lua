--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

local rose_ok = pcall(require, "rose-pine.palette")

---@alias Rabbit.Colors.Paint
---| "rose" # Pink
---| "love" # Red
---| "gold" # Yellow
---| "tree" # Green
---| "foam" # Light Blue
---| "iris" # Deep Blue
---| "pine" # Navy

---@alias Rabbit.Color Rabbit.Recursive<string | NvimHlKwargs>
---@alias Rabbit.Recursive<T>
---| T # Not recursive
---| fun(): Rabbit.Recursive<T> # Calls until resolution

-- All the colors for Rabbit. Any value can be a function that returns its own class.
---@class Rabbit.Config.Colors
---@field types Rabbit.Recursive<Rabbit.Config.Colors.Types>
---@field files Rabbit.Recursive<Rabbit.Config.Colors.Files>
---@field paint Rabbit.Recursive<Rabbit.Config.Colors.Paint>
---@field marks Rabbit.Recursive<Rabbit.Config.Colors.Marks>
---@field popup Rabbit.Recursive<Rabbit.Config.Colors.Popup>
---@field lsp Rabbit.Recursive<Rabbit.Config.Colors.Lsp>
local COLORS = {
	-- Various highlight groups
	---@class Rabbit.Config.Colors.Types
	types = {
		-- Title text around the border.
		-- Highlight group: `rabbit.types.title`
		---@type Rabbit.Color
		title = { fg = ":Normal", bold = true },
		-- Notice the `:` in `:Normal`, that means "inherit." In this example,
		-- the title will inherit the foreground color of the Normal highlight group.
		-- This is dynamically updated whenever Rabbit is spawned,

		-- Entry index, eg "1. "
		-- Highlight group: `rabbit.types.index`
		---@type Rabbit.Color
		index = { fg = ":Comment", italic = true },

		-- Default tail color, eg buffer number or terminal PID
		-- Highlight group: `rabbit.types.tail`
		---@type Rabbit.Color
		tail = { fg = ":Comment", italic = true },

		-- Default head color, whatever prefixes the entry label
		-- Highlight group: `rabbit.types.head`
		---@type Rabbit.Color
		head = { fg = ":NonText", bold = true },

		-- Default collection color
		-- Highlight group: `rabbit.types.collection`
		---@type Rabbit.Color
		collection = { fg = ":Constant", bold = true, italic = true },

		-- Color of the preview border
		-- Highlight group: `rabbit.types.preview`
		-- @type Color.Nvim
		preview = { fg = ":rabbit.types.plugin", bg = ":Folded" },
		-- Notice bg is ":Folded", that inherits the background color from the
		-- Folded highlight group. By default, all inherited colors use inherit
		-- the key from the highlight group they inherit from.

		-- Synopsis text for each plugin
		-- Highlight group: `rabbit.types.synopsis`
		---@type Rabbit.Color
		synopsis = { fg = ":Comment", italic = true },

		-- This is just here for transparency. It is updated with the plugin's color.
		-- Highlight group: `rabbit.types.plugin`
		---@type Rabbit.Color
		plugin = { fg = "#000000" },

		-- This is just here for transparency. It is updated with the plugin's color.
		-- Highlight group: `rabbit.types.reverse`
		---@type Rabbit.Color
		reverse = { fg = ":NormalFloat#bg", bg = ":rabbit.types.plugin#fg" },

		-- This is just here for transparency. I do not recommend you change it.
		inverse = { reverse = true },
	},

	-- How file entries are highlighted
	---@class Rabbit.Config.Colors.Files
	files = {
		-- File part color, eg "init.lua"
		-- Highlight group: `rabbit.files.file`
		---@type Rabbit.Color
		file = { fg = ":Normal" },

		-- Directory part color, eg "/home/user/Desktop/"
		-- Highlight group: `rabbit.files.path`
		---@type Rabbit.Color
		path = { fg = ":NonText" },

		-- Color for the $ in "$ (term title)"
		-- Highlight group: `rabbit.files.term`
		---@type Rabbit.Color
		term = { fg = ":Constant", bold = true },

		-- Color for buffers with no name. Displayed as "#nil"
		-- Highlight group: `rabbit.files.void`
		---@type Rabbit.Color
		void = { fg = ":Function", italic = true },

		-- Color for buffers that have been closed
		-- Highlight group: `rabbit.files.closed`
		---@type Rabbit.Color
		closed = { fg = ":DiagnosticVirtualTextError" },

		-- Color for the little modified dot
		-- Highlight group: `rabbit.files.modified`
		---@type Rabbit.Color
		modified = { fg = ":WarningMsg" },
	},

	-- Line colors for marks (not implemented yet)
	---@class Rabbit.Config.Colors.Marks
	marks = {
		-- Highlight group: `rabbit.marks.rose`
		---@type Rabbit.Color
		rose = { bg = ":rabbit.paint.rose#fg", blend = 10 },
		-- Notice the `#` in `:rabbit.paint.love#fg`, that means "key." Here, we
		-- are inheriting rabbit.paint.rose's foreground color for the background

		-- Highlight group: `rabbit.marks.love`
		---@type Rabbit.Color
		love = { bg = ":rabbit.paint.love#fg", blend = 10 },

		-- Highlight group: `rabbit.marks.gold`
		---@type Rabbit.Color
		gold = { bg = ":rabbit.paint.gold#fg", blend = 10 },

		-- Highlight group: `rabbit.marks.tree`
		---@type Rabbit.Color
		tree = { bg = ":rabbit.paint.tree#fg", blend = 10 },

		-- Highlight group: `rabbit.marks.foam`
		---@type Rabbit.Color
		foam = { bg = ":rabbit.paint.foam#fg", blend = 10 },

		-- Highlight group: `rabbit.marks.iris`
		---@type Rabbit.Color
		iris = { bg = ":rabbit.paint.iris#fg", blend = 10 },

		-- Highlight group: `rabbit.marks.pine`
		---@type Rabbit.Color
		pine = { bg = ":rabbit.paint.pine#fg", blend = 10 },
	},

	-- Border colors for various popup messages
	---@class Rabbit.Config.Colors.Popup
	popup = {
		-- Shown when there is an error or conflict
		-- Highlight group: `rabbit.popup.error`
		---@type Rabbit.Color
		error = { fg = ":ErrorMsg", bg = ":FloatBorder" },

		-- Shown when there is a warning
		-- Highlight group: `rabbit.popup.warning`
		---@type Rabbit.Color
		warning = { fg = ":Question", bg = ":FloatBorder" },

		-- Any other message box or menu
		-- Highlight group: `rabbit.popup.info`
		---@type Rabbit.Color
		info = { fg = ":MoreMsg", bg = ":FloatBorder" },
	},

	-- For each part of the legend
	---@class Rabbit.Config.Colors.Legend
	legend = {
		-- Legend label, eg "close" or "select"
		-- Highlight group: `rabbit.legend.action`
		---@type Rabbit.Color
		action = { fg = ":rabbit.types.plugin", bold = true },

		-- Legend separator, eg ":"
		-- Highlight group: `rabbit.legend.separator`
		---@type Rabbit.Color
		separator = { fg = ":Comment" },

		-- Legend key, eg "a"
		-- Highlight group: `rabbit.legend.key`
		---@type Rabbit.Color
		key = { fg = ":Normal" },
	},

	-- Different LSP levels
	---@class Rabbit.Config.Colors.Lsp
	lsp = {
		-- Level 'ERROR;' eg syntax errors
		-- Highlight group: `rabbit.lsp.error`
		---@type Rabbit.Color
		error = { fg = ":DiagnosticError", bold = true },

		-- Level 'WARN;' eg bad casting
		-- Highlight group: `rabbit.lsp.warn`
		---@type Rabbit.Color
		warn = { fg = ":DiagnosticWarn", bold = true },

		-- Level 'INFO;' eg lines too long
		-- Highlight group: `rabbit.lsp.info`
		---@type Rabbit.Color
		info = { fg = ":DiagnosticInfo", bold = true },

		-- Level 'HINT;'
		-- Highlight group: `rabbit.lsp.hint`
		---@type Rabbit.Color
		hint = { fg = ":DiagnosticHint", bold = true },
	},

	-- Colors to use for your collections. If you use rose-pine or sakura-pine, colors
	-- are automatically pulled from them. If neither are installed, then the colors are
	-- the closest Neovim named colors
	---@type Rabbit.Recursive<Rabbit.Config.Colors.Paint>
	paint = rose_ok
			and function()
				local rosepine = require("rose-pine.palette")
				-- Compatibility with main-line rose-pine instead of my fork, sakura-pine,
				-- which introduced the green color earlier
				---@diagnostic disable-next-line: undefined-field
				rosepine.tree = rosepine.tree or rosepine.leaf

				---@class Rabbit.Config.Colors.Paint
				local color = {
					-- A lovely pink
					-- Highlight group: `rabbit.paint.rose`
					---@type Rabbit.Color
					rose = { fg = rose_ok and rosepine.rose or "HotPink" },

					-- A deep red
					-- Highlight group: `rabbit.paint.love`
					---@type Rabbit.Color
					love = { fg = rose_ok and rosepine.love or "IndianRed" },

					-- A warm yellow
					-- Highlight group: `rabbit.paint.gold`
					---@type Rabbit.Color
					gold = { fg = rose_ok and rosepine.gold or "Gold2" },

					-- A calm green
					-- Highlight group: `rabbit.paint.tree`
					---@type Rabbit.Color
					tree = { fg = rose_ok and rosepine.tree or "ForestGreen" },

					-- A light blue
					---@type Rabbit.Color
					foam = { fg = rose_ok and rosepine.foam or "SkyBlue" },

					-- A deep purple
					-- Highlight group: `rabbit.paint.iris`
					---@type Rabbit.Color
					iris = { fg = rose_ok and rosepine.iris or "SlateBlue" },

					-- A dark navy
					-- Highlight group: `rabbit.paint.pine`
					---@type Rabbit.Color
					pine = { fg = rose_ok and rosepine.pine or "Navy" },
				}
				return color
			end
		or {
			rose = { fg = "HotPink" },
			love = { fg = "IndianRed" },
			gold = { fg = "Gold2" },
			tree = { fg = "ForestGreen" },
			foam = { fg = "SkyBlue" },
			iris = { fg = "SlateBlue" },
			pine = { fg = "Navy" },
		} --[[@as Rabbit.Config.Colors.Paint]],
}

return COLORS
