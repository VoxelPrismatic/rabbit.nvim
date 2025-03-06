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
		tail = { fg = ":Comment", italic = true },
		collection = { fg = ":Constant", bold = true, italic = true },
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

	legend = {
		action = { fg = ":rabbit.plugin", bold = true },
		separator = { fg = ":Comment" },
		key = { fg = ":Normal" },
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
		distance_char = ":::",
		dirname_trim = 12,
		dirname_char = "…",
		distance_trim = 3,
	},

	legend = true,
}

-- Keymap settings
---@type Rabbit.Config.Keymap
C.keys = {
	select = { "<CR>", "g" },
	close = { "q", "<Esc>", "<leader>" },
	delete = { "x", "d", "<Del>" },
	collect = { "A", "c" },
	parent = { "-", "<BS>" },
	insert = { "a", "i" },
	help = { "?", "h" },
	["debug"] = { "D" },
	open = { "<leader>r" },
}

-- Plugin settings
---@class Rabbit.Config.Plugin
C.plugins = {
	---@diagnostic disable-next-line: missing-fields
	history = {}, ---@type Rabbit._.History.Options
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
end

return C
