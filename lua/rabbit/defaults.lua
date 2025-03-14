local DEFAULT_MSG = "There's nothing to display, and the dev forgot to add a message"

---@type Rabbit.Box.Default
local box = {
	round = {
		top_left = "╭",
		top_right = "╮",
		bottom_left = "╰",
		bottom_right = "╯",
		vertical = "│",
		horizontal = "─",
		emphasis = "═",
	},
	square = {
		top_left = "┌",
		top_right = "┐",
		bottom_left = "└",
		bottom_right = "┘",
		vertical = "│",
		horizontal = "─",
		emphasis = "═",
	},
	thick = {
		top_left = "┏",
		top_right = "┓",
		bottom_left = "┗",
		bottom_right = "┛",
		vertical = "┃",
		horizontal = "━",
		emphasis = "═",
	},
	double = {
		top_left = "╔",
		top_right = "╗",
		bottom_left = "╚",
		bottom_right = "╝",
		vertical = "║",
		horizontal = "═",
		emphasis = "━",
	}
}


---@param name string Highlight group name
---@param key? string Key, eg `fg` or `bg`
---@return string | nil
local function grab_color(name, key)
	local details = vim.api.nvim_get_hl(0, { name = name })
	key = key or "fg"
	if details == nil or details[key] == nil then
		return nil
	end
	return string.format("#%06x", details[key])
end

---@type Rabbit.Options
local options = {
	colors = {
		title = { fg = grab_color("Normal"), bold = true },
		index = { fg = grab_color("Comment"), italic = true },
		dir = { fg = grab_color("NonText") },
		file = { fg = grab_color("Normal") },
		term = { fg = grab_color("Constant"), italic = true },
		noname = { fg = grab_color("Function"), italic = true },
		message = { fg = grab_color("Identifier"), italic = true, bold = true },
		popup = {
			error = { fg = grab_color("ErrorMsg"), bg = grab_color("FloatBorder", "bg"), bold = true },
			warning = { fg = grab_color("Question"), bg = grab_color("FloatBorder", "bg"), bold = true },
			info = { fg = grab_color("MoreMsg"), bg = grab_color("FloatBorder", "bg"), bold = true },
		},
	},
	window = {
		box = box.round,
		title = "Rabbit",
		plugin_name_position = "bottom",
		emphasis_width = 8,
		width = 64,
		height = 24,
		float = {
			"bottom",
			"right",
		},
		split = "right",
		overflow = ":::",
		path_len = 12,
	},
	default_keys = {
		close = { "<Esc>", "q", "<leader>" },
		select = { "<CR>" },
		open = { "<leader>r" },
		file_add = { "a" },
		file_del = { "<Del>" },
		group = { "A" },
		group_up = { "-" },
	},
	plugin_opts = {},
	enable = {
		"history",
		"reopen",
		"oxide",
		"harpoon",
	},
	path_key = nil,
}

return {
	options = options,
	box = box,
	msg = DEFAULT_MSG
}
