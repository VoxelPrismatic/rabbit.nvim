---@class Rabbit.Config
C = {}

local rose_ok, rosepine = pcall(require, "rose-pine.palette")

-- All the colors for Rabbit
---@type Rabbit.Config.Colors
C.colors = {
	types = {
		title = { fg = ":Normal", bold = true },
		index = { fg = ":Comment", italic = true },
		dir = { fg = ":NonText" },
		file = { fg = ":Normal" },
		term = { fg = ":Constant", italic = true },
		noname = { fg = ":Function", italic = true },
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

	popup = {
		error = { fg = ":ErrorMsg", bg = ":FloatBorder", bold = true },
		warning = { fg = ":Question", bg = ":FloatBorder", bold = true },
		info = { fg = ":MoreMsg", bg = ":FloatBorder", bold = true },
	},
}

-- Window settings
---@type Rabbit.Config.Window
C.window = {
	box = "┏┓╚┛━┃║",

	spawn = {
		mode = "float",
		width = 64,
		height = 24,
		side = "se",
	},

	titles = {
		title_text = "",
		title_pos = "ws",
		plugin_pos = "sw",
		title_case = "lower",
		plugin_case = "lower",
		title_emphasis = {
			left = "║║",
			right = "",
		},
		plugin_emphasis = {
			left = "═ ",
			right = " ════════════",
		},
	},

	overflow = {
		char = ":::",
		path_len = 12,
	},

	legend = true,
}

-- Keymap settings
---@type Rabbit.Config.Keymap
C.keys = {
	select = { "g", "<CR>" },
	close = { "q", "<Esc>", "<leader>" },
	delete = { "x", "d", "<Del>" },
	collect = { "A", "c" },
	parent = { "-", "<BS>" },
	insert = { "a", "i" },
	help = { "?", "h" },
	["debug"] = { "D" },
	open = { "<leader>r" },
}

function C.cwd()
	return vim.fn.getcwd()
end

-- Set up Rabbit
---@param opts Rabbit.Config
function C.setup(opts) end

return C
