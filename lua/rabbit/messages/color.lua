local UI = require("rabbit.term.listing")
local TERM = require("rabbit.util.term")
local STACK = require("rabbit.term.stack")
local SET = require("rabbit.util.set")

local color_ws ---@type Rabbit.Stack.Workspace

local colors = SET.new({
	"rose",
	"love",
	"gold",
	"tree",
	"foam",
	"iris",
	"pine",
})

-- You may only rename the currently highlighted entry
---@param data Rabbit.Message.Color
return function(data)
	local linenr, curpos = unpack(UI._fg.cursor:get())
	local entry = UI._entries[linenr] ---@type Rabbit.Entry

	curpos = (colors:idx(data.color) or 1) - 1

	local old_ws = color_ws
	color_ws = STACK.ws.scratch({
		focus = true,
		config = {
			relative = "win",
			win = UI._fg.win.id,
			row = linenr - 1,
			col = UI._fg.win.config.width - 8,
			height = 1,
			width = 8,
			style = "minimal",
			zindex = 60,
		},
		---@diagnostic disable-next-line: missing-fields
		wo = {
			cursorline = true,
		},
		parent = UI._fg,
		lines = {
			{ text = "", hl = "rabbit.paint.rose" },
			{ text = "", hl = "rabbit.paint.love" },
			{ text = "", hl = "rabbit.paint.gold" },
			{ text = "", hl = "rabbit.paint.tree" },
			{ text = "", hl = "rabbit.paint.foam" },
			{ text = "", hl = "rabbit.paint.iris" },
			{ text = "", hl = "rabbit.paint.pine" },
		},
		cursor = { 1, curpos, true },
		many = false,
		ns = "rabbit:rename",
	})

	if old_ws then
		old_ws:close()
	end

	local function cursor_moved()
		local col = TERM.realcol() + 1
		if col > #colors then
			TERM.feed("<Left>")
			return
		end
		data.apply(entry, colors[col])
		UI.place_entry(entry, entry._env.idx, entry._env.real, #tostring(#UI._entries))
	end

	color_ws.autocmd:add({
		CursorMoved = cursor_moved,
		WinClosed = function()
			UI._priority_legend = {}
		end,
		InsertEnter = function()
			TERM.feed("<Esc>")
		end,
	})

	UI._priority_legend = UI._fg.keys:legend({
		labels = { "select", "close" },
		rename = {
			select = "apply",
			close = "cancel",
		},
	})

	for _, key in ipairs(UI._fg.keys:find("select", "close")) do
		key:set(color_ws.buf.id)
	end
end
