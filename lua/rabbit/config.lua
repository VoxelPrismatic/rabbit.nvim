---@class Rabbit.Config
local C = {}

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
C.colors = {
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
		error = { fg = ":ErrorMsg", bg = ":FloatBorder", bold = true },

		-- Shown when there is a warning
		-- Highlight group: `rabbit.popup.warning`
		---@type Rabbit.Color
		warning = { fg = ":Question", bg = ":FloatBorder", bold = true },

		-- Any other message box or menu
		-- Highlight group: `rabbit.popup.info`
		---@type Rabbit.Color
		info = { fg = ":MoreMsg", bg = ":FloatBorder", bold = true },
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
C.window = {
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
		distance_char = ":::",

		-- Maximum distance before trimming
		---@type integer
		distance_trim = 3,

		-- String to use when a folder name is too long
		-- Ex. "someobsurdlylongfoldername"
		-- becomes "someobsurdly…"
		---@type string
		dirname_char = "…",

		-- Maximum folder name length before trimming
		---@type integer
		dirname_trim = 12,
	},

	-- Icons for various things
	---@class Rabbit.Config.Window.Icons
	icons = {
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

---@class (exact) Rabbit.Cls.Box
---@field top_left string Top left corner character.
---@field top_side string | Rabbit.Cls.Box.Side Top side text.
---@field top_right string Top right corner character.
---@field right_side string | Rabbit.Cls.Box.Side Right side text.
---@field bot_left string Bottom left corner character.
---@field bot_side string | Rabbit.Cls.Box.Side Bottom side text.
---@field bot_right string Bottom right corner character.
---@field left_side string | Rabbit.Cls.Box.Side Left side text.
---@field chars? Rabbit.Cls.Box.Chars Extra characters
---@field parts? { [string]: Rabbit.Cls.Box.Part } Custom parts used to complete the parts on each side.

---@class (exact) Rabbit.Cls.Box.Chars
---@field rise string Left-side rise character.
---@field emphasis string Emphasis character.
---@field scroll string Scrollbar position character.

---@alias Rabbit.Cls.Box.Part
---| string # String literal
---| fun(): (string, boolean) # Function to call to produce text. Boolean:True = highlight as title. Boolean:False = highlight as border.
---| { [1]: string, [2]: boolean } # Unpacked to produce the same result as the function call.

---@class (exact) Rabbit.Cls.Box.Side
---@field base string Base character
---@field left? Rabbit.Cls.Box.Align Left/top aligned text.
---@field right? Rabbit.Cls.Box.Align Right/bottom aligned text.
---@field center? Rabbit.Cls.Box.Align Center aligned text.
-- WARNING: Parts are processed in order from left to right. If a part is too long, it will be overwritten by the next.

---@class (exact) Rabbit.Cls.Box.Align
---@field parts string | string[] Parts to print.
---@field join? string Join text between multiple parts.
---@field case? Rabbit.Enum.Case Apply case to the text
---@field prefix? string Prefix. This will be treated as part of the border text.
---@field suffix? string Suffix. This will be treated as part of the border text.
---@field build? fun(self: Rabbit.Cls.Box.Align, size: integer, text: string) Update the prefix and suffix based on the built text and size of the side

---@alias Rabbit.Enum.Case
---| "unchanged" # No change.
---| "lower" # lower case.
---| "upper" # UPPER CASE.
---| "title" # Title Case.

---@class Rabbit.Config.Boxes
C.boxes = {
	---@type Rabbit.Cls.Box
	rabbit = {
		top_left = "┏",
		top_right = "┓",
		bot_left = "╚",
		bot_right = "┛",
		top_side = "━",
		right_side = {
			base = "┃",
			left = { parts = "scroll" },
			-- "scroll" is The scroll bar
		},
		left_side = {
			base = "┃",
			right = { parts = "rise" },
			-- "rise" is vertical part to mirror the horizontal emphasis
		},
		bot_side = {
			base = "━",
			left = {
				parts = {
					-- Emphasis prefix: "=" in "= trail"
					"head",

					-- Rabbit title; disabled by default because it's ugly
					---@see Rabbit.Config.System.name
					-- "rabbit",

					-- Plugin name: "trail"
					"plugin",

					-- Emphasis suffix that fills the rest of the half of the width
					-- "═ trail ═════════─────────────────"
					-- "═ carrot ════════─────────────────"
					"tail",
				},
				case = "lower",
			},
		},
		chars = {
			rise = "║",
			scroll = "║",
			emphasis = "═",
		},
		parts = {
			-- Apply custom parts here. The built-in ones may be overwritten.
			-- - "scroll"
			-- - "rise"
			-- - "head"
			-- - "rabbit"
			-- - "plugin"
			-- - "tail"
			---@see Rabbit.Cls.Box.parts

			-- These are used in search listings, like fzf, rg, or find
			search_left = "┣",
			search_mid = "━",
			search_right = "┫",
		},
	},

	---@type Rabbit.Cls.Box
	preview = {
		top_left = "┏",
		top_right = "┓",
		bot_left = "╚",
		bot_right = "┛",
		top_side = "━",
		right_side = "┃",
		left_side = {
			base = "┃",
			right = { parts = "rise" },
			---@see Rabbit.Config.Boxes.rabbit
		},
		bot_side = {
			base = "━",
			left = {
				parts = {
					---@see Rabbit.Config.Boxes.rabbit
					"head",

					-- Folder path, eg ":::/git/rabbit.nvim/lua/"
					"dirname",

					-- File name, eg "init.lua"
					"basename",

					---@see Rabbit.Config.Boxes.rabbit
					"tail",
				},
				join = "",
			},
		},
		chars = {
			rise = "║",
			scroll = "║",
			emphasis = "═",
		},
		parts = {
			-- Apply custom parts here. The built-in ones may be overwritten.
			-- - "scroll"
			-- - "rise"
			-- - "head"
			-- - "dirname"
			-- - "basename"
			-- - "tail"
			---@see Rabbit.Cls.Box.parts
		},
	},

	---@type Rabbit.Cls.Box
	popup = {
		top_left = "╔",
		top_right = "┓",
		bot_right = "┛",
		bot_left = "┗",
		bot_side = "━",
		right_side = "┃",
		left_side = {
			base = "┃",
			left = { parts = "rise" },
			---@see Rabbit.Config.Boxes.rabbit
		},
		top_side = {
			base = "━",
			left = {
				parts = {
					---@see Rabbit.Config.Boxes.rabbit
					"head",

					-- Message box title, eg "Error" or "Unsaved changes"
					"title",

					---@see Rabbit.Config.Boxes.rabbit
					"tail",
				},
			},
		},
		chars = {
			rise = "║",
			scroll = "║",
			emphasis = "═",
		},
		parts = {
			-- Apply custom parts here. The built-in ones may be overwritten.
			-- - "scroll"
			-- - "rise"
			-- - "head"
			-- - "title"
			-- - "tail"
			---@see Rabbit.Cls.Box.parts
		},
	},
}

-- Keymap settings
---@class Rabbit.Plugin.Keymap
C.keys = {
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

-- Plugin settings
---@class Rabbit.Config.Plugin
C.plugins = {
	-- Disable a plugin with 'false'

	---@type Rabbit*Trail.Options | false
	---@diagnostic disable-next-line: missing-fields
	trail = {},

	---@type Rabbit*Carrot.Options | false
	---@diagnostic disable-next-line: missing-fields
	carrot = {},

	---@type Rabbit*Index.Options | false
	---@diagnostic disable-next-line: missing-fields
	index = {
		default = true,
	},

	---@type Rabbit*Forage.Options | false
	---@diagnostic disable-next-line: missing-fields
	forage = {},
}

-- Other rabbit system settings
---@class Rabbit.Config.System
C.system = {
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
	wrap = 0.9,

	-- Default delay in ms when calling vim.defer_fn. If your system
	-- is slow, you may want to increase this
	defer = 5,
}

-- Default scoping function
---@return string
function C.cwd()
	-- By default, we want to use the git directory.
	-- This function automatically falls back to cwd if there is no git repo
	return require("rabbit.util.paths").git()
end

-- Set up Rabbit
---@param opts Rabbit.Config
function C.setup(opts)
	for k, v in pairs(C) do
		if type(v) == "table" then
			C[k] = vim.tbl_deep_extend("force", v, opts[k] or {})
		end
	end

	for k, v in pairs(C.keys) do
		if type(v) == "string" then
			C.keys[k] = { v }
		end
	end

	for _, p in ipairs(C.plugins) do
		p = p ---@type Rabbit.Plugin.Options
		if p ~= nil and p.keys ~= nil then
			for k, v in pairs(p.keys) do
				if type(v) == "string" then
					p.keys[k] = { v }
				end
			end
		end
	end

	if C.system.data:sub(-1) ~= "/" then
		C.system.data = C.system.data .. "/"
	end
end

return C
