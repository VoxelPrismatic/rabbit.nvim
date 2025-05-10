--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

local UI = require("rabbit.term.listing")
local TERM = require("rabbit.util.term")
local STACK = require("rabbit.term.stack")
local SET = require("rabbit.util.set")
local CONFIG = require("rabbit.config")

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
			{ text = "" },
			{
				{ text = "", hl = "rabbit.paint.rose" },
				{ text = "", hl = "rabbit.paint.love" },
				{ text = "", hl = "rabbit.paint.gold" },
				{ text = "", hl = "rabbit.paint.tree" },
				{ text = "", hl = "rabbit.paint.foam" },
				{ text = "", hl = "rabbit.paint.iris" },
				{ text = "", hl = "rabbit.paint.pine" },
			},
			{ text = "" },
		},
		cursor = { 2, curpos, true },
		many = true,
		ns = "rabbit:rename",
		on_close = function()
			UI._priority_legend = {}
		end,
	})

	if old_ws then
		old_ws:close()
	end

	local function apply(color)
		data.apply(entry, color)
		UI.redraw_entry(entry)
	end

	local function cursor_moved()
		local idx = entry._env.idx or 0
		local dx = vim.fn.line(".") - 2

		if dx == 0 or vim.fn.line("$") < 3 then
			local col = TERM.realcol() + 1
			if col > #colors then
				TERM.feed("<Left>")
				return
			end
			apply(colors[col])
			return
		end

		local continue_key, opposite_key = unpack(dx == -1 and { "<Up>", "<Down>" } or { "<Down>", "<Up>" })

		local new_entry = entry._env.siblings[idx + dx]
		if new_entry == nil then
			TERM.feed(opposite_key)
			return
		end

		vim.cmd("stopinsert")
		UI._bg:focus()
		vim.defer_fn(function()
			color_ws:close()
			UI._fg:focus()
			TERM.feed(continue_key)
		end, CONFIG.system.defer or 5)
	end

	color_ws.autocmd:add({
		CursorMoved = cursor_moved,
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

	UI._fg.keys:rebind(color_ws.buf.id, {
		select = function()
			color_ws:close()
		end,
		close = function()
			apply(data.color)
			color_ws:close()
		end,
	})
end
