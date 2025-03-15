---@class Rabbit.Config
C = {}

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
	},

	files = {
		file = { fg = ":Normal" },
		path = { fg = ":NonText" },
		term = { fg = ":Constant", bold = true },
		void = { fg = ":Function", italic = true },
		closed = { fg = ":DiagnosticVirtualTextError" },
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
		{
			align = "sw",
			make = function(sz, _)
				local name = require("rabbit.term.listing")._plugin.name:lower()
				local suf = " " .. ("═"):rep(math.floor(sz / 2) - #name - 2)
				return "═ ", name, suf
			end,
		},
		{
			align = "ws",
			make = function(sz, _)
				return "", "", ("║"):rep(math.floor(sz / 4))
			end,
		},
	},

	overflow = {
		distance_char = ":::",
		dirname_trim = 12,
		dirname_char = "…",
		distance_trim = 3,
	},

	legend = true,
	nrs = true,
	preview = true,
}

-- Keymap settings
---@type Rabbit.Plugin.Keymap
C.keys = {
	switch = { "<leader>r" },
	select = { "<CR>", "g" },
	close = { "q", "<Esc>", "<leader>" },
	delete = { "x", "d", "<Del>" },
	collect = { "A", "c" },
	parent = { "-", "<BS>" },
	insert = { "a", "i" },
	help = { "?", "h" },
	rename = { "i" },
	["debug"] = { "D" },
}

-- Plugin settings
---@class Rabbit.Config.Plugin
C.plugins = {
	---@diagnostic disable-next-line: missing-fields
	trail = {}, ---@type Rabbit*Trail.Options
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
end

return C
