local BOX = require("rabbit.term.border")

---@class Rabbit.Config
local C = {}

local rose_ok, rosepine = pcall(require, "rose-pine.palette")

-- All the colors for Rabbit
---@type Rabbit.Config.Colors
C.colors = {
	types = {
		title = { fg = ":Normal", bold = true },
		index = { fg = ":Comment", italic = true },
		tail = { fg = ":Comment", italic = true },
		head = { fg = ":NonText", bold = true },
		collection = { fg = ":Constant", bold = true, italic = true },
		preview = { fg = ":rabbit.types.plugin", bg = ":Folded" },
		plugin = { fg = "#000000" },
	},

	files = {
		file = { fg = ":Normal" },
		path = { fg = ":NonText" },
		term = { fg = ":Constant", bold = true },
		void = { fg = ":Function", italic = true },
		closed = { fg = ":DiagnosticVirtualTextError" },
		modified = { fg = ":WarningMsg" },
	},

	paint = {
		rose = { fg = rose_ok and rosepine.rose or "HotPink" },
		love = { fg = rose_ok and rosepine.love or "IndianRed" },
		gold = { fg = rose_ok and rosepine.gold or "Gold2" },
		tree = { fg = rose_ok and rosepine.tree or "ForestGreen" },
		foam = { fg = rose_ok and rosepine.foam or "SkyBlue" },
		iris = { fg = rose_ok and rosepine.iris or "SlateBlue" },
		pine = { fg = rose_ok and rosepine.pine or "Navy" },
	},

	marks = {
		rose = { bg = ":rabbit.paint.rose#fg", blend = 10 },
		love = { bg = ":rabbit.paint.love#fg", blend = 10 },
		gold = { bg = ":rabbit.paint.gold#fg", blend = 10 },
		tree = { bg = ":rabbit.paint.tree#fg", blend = 10 },
		foam = { bg = ":rabbit.paint.foam#fg", blend = 10 },
		iris = { bg = ":rabbit.paint.iris#fg", blend = 10 },
		pine = { bg = ":rabbit.paint.pine#fg", blend = 10 },
	},

	popup = {
		error = { fg = ":ErrorMsg", bg = ":FloatBorder", bold = true },
		warning = { fg = ":Question", bg = ":FloatBorder", bold = true },
		info = { fg = ":MoreMsg", bg = ":FloatBorder", bold = true },
	},

	legend = {
		action = { fg = ":rabbit.types.plugin", bold = true },
		separator = { fg = ":Comment" },
		key = { fg = ":Normal" },
	},

	lsp = {
		error = { fg = ":DiagnosticError", bold = true },
		warn = { fg = ":DiagnosticWarn", bold = true },
		info = { fg = ":DiagnosticInfo", bold = true },
		hint = { fg = ":DiagnosticHint", bold = true },
	},
}

-- Window settings
---@type Rabbit.Config.Window
C.window = {
	spawn = {
		mode = "float",
		width = 64,
		height = 24,
		side = "se",
	},

	overflow = {
		distance_char = ":::",
		dirname_trim = 12,
		dirname_char = "…",
		distance_trim = 3,
	},

	---@class Rabbit.Config.Window.Icons
	icons = {
		-- Icon for modified buffers
		modified = "•",

		-- Icon for read-only buffers
		readonly = "",

		-- Icon for LSP hints
		lsp_hint = "󱐋",

		-- Icon for LSP info
		lsp_info = "",

		-- Icon for LSP warnings
		lsp_warn = "󰔶",

		-- Icon for LSP errors
		lsp_error = "",

		-- Icon for writing files
		file_write = "",

		-- Icon for deleting files or ignoring changes
		file_delete = "󰆴",
	},

	beacon = {
		nrs = false,
		readonly = true,
		modified = true,
		lsp = {
			hint = function(data)
				if data.source == "Harper" and vim.bo[data.bufnr].filetype ~= "markdown" then
					return false
				end

				return true
			end,
			error = true,
			warn = true,
			info = true,
		},
	},

	legend = true,
	preview = true,
}

---@type Rabbit.Config.Boxes
C.boxes = {
	rabbit = {
		top_left = "┏",
		top_right = "┓",
		bot_left = "╚",
		bot_right = "┛",
		top_side = "━",
		right_side = {
			base = "┃",
			left = { parts = "scroll" },
		},
		left_side = {
			base = "┃",
			right = { parts = "rise" },
		},
		bot_side = {
			base = "━",
			left = {
				parts = { "head", "rabbit", "plugin", "tail" },
				case = "lower",
			},
		},
		chars = {
			rise = "║",
			scroll = "║",
			emphasis = "═",
		},
	},

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
		},
		bot_side = {
			base = "━",
			left = {
				parts = { "head", "dirname", "basename", "tail" },
				join = "",
			},
		},
		chars = {
			rise = "║",
			scroll = "║",
			emphasis = "═",
		},
	},

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
		},
		top_side = {
			base = "━",
			left = {
				parts = { "head", "title", "tail" },
			},
		},
		chars = {
			rise = "║",
			scroll = "║",
			emphasis = "═",
		},
	},
}

-- Keymap settings
---@type Rabbit.Plugin.Keymap
C.keys = {
	switch = { "<leader>r" },
	select = { "<CR>", "g" },
	close = { "q", "<Esc>", "<leader>" },
	delete = { "x", "d", "<Del>" },
	collect = { "A" },
	parent = { "-", "<BS>" },
	insert = { "a" },
	help = { "?", "h" },
	rename = { "i" },
	["debug"] = { "D" },
}

-- Plugin settings
---@class Rabbit.Config.Plugin
C.plugins = {
	---@type Rabbit*Trail.Options
	---@diagnostic disable-next-line: missing-fields
	trail = {
		default = true,
	},

	---@diagnostic disable-next-line: missing-fields
	harpoon = {}, ---@type Rabbit*Harpoon.Options
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
}

function C.cwd()
	return vim.fn.getcwd()
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
