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
local BOXES = {
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

return BOXES
