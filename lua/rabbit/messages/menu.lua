--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

local HL = require("rabbit.term.highlight")
local UI = require("rabbit.term.listing")
local BOX = require("rabbit.term.border")
local CONFIG = require("rabbit.config")
local STACK = require("rabbit.term.stack")
local TERM = require("rabbit.util.term")

---@param data Rabbit.Message.Menu
return function(data)
	if data.options == nil or #data.options == 0 then
		data.options = {
			{
				label = "Ok",
				callback = function()
					return UI._display
				end,
			},
		}
	end

	local msg = data.msg
	if msg ~= nil then
		if type(msg) == "string" then
			msg = { text = msg }
		end
		msg = HL.wrap(msg, UI._fg.win.config.width - 2, " ")
		table.insert(msg, {})
	end

	if #data.options == 1 and data.immediate then
		return UI.handle_callback(data.options[1].callback(data.options[1].args))
	end

	local height = #data.options + 2 + (msg ~= nil and #msg or 0)
	local width = UI._fg.win.config.width or 64
	local row = math.floor((UI._fg.win.config.height - height) / 2)

	local config = CONFIG.boxes.popup
	local lines = BOX.make(width, height, CONFIG.boxes.popup, {
		rise = { config.chars.rise:rep(height / 4), false },
		head = { config.chars.emphasis, false },
		tail = { config.chars.emphasis:rep(width / 2 - 2 - #data.title), false },
		title = { data.title, true },
	})
		:to_hl({
			border_hl = data.color or "rabbit.popup.info",
			title_hl = "rabbit.types.title",
		}).lines

	local win = STACK.ws.scratch({
		config = {
			row = row,
			col = 0,
			width = width,
			height = height,
			relative = "win",
			win = UI._fg.win.id,
			style = "minimal",
			zindex = 60,
		},
		focus = true,
		parent = UI._fg,
		lines = lines,
		many = true,
	})

	local opts = STACK.ws.scratch({
		config = {
			row = 1,
			col = 1,
			width = width - 2,
			height = height - 2,
			relative = "win",
			win = win.win.id,
			style = "minimal",
			zindex = 65,
		},
		---@diagnostic disable-next-line: missing-fields
		wo = {
			cursorline = true,
		},
		focus = true,
		parent = win,
	})

	lines = {}

	for i, option in ipairs(data.options) do
		if option.color == nil then
			option.color = nil
		else
			option.color = "rabbit.paint." .. option.color
		end

		if option.icon == nil then
			option.icon = ""
		end

		lines[i] = {
			{
				text = " " .. tostring(i) .. ". ",
				hl = "rabbit.types.index",
			},
			{
				text = option.icon == "" and "" or option.icon .. " ",
				hl = { option.color },
			},
			{
				text = option.label,
				hl = { option.color },
			},
		}
		if i < 10 then
			vim.keymap.set("n", tostring(i), function()
				win:close()
				UI.handle_callback(option.callback(option.args))
			end, { buffer = opts.buf.id })
		end
	end

	opts.lines:set(lines)
	if msg ~= nil then
		vim.defer_fn(function()
			opts.extmarks:set({
				col = 0,
				line = 0,
				name = "msg",
				ns = "rabbit.prompt.msg",
				opts = {
					end_col = 1,
					virt_lines_above = true,
					strict = false,
					virt_lines = msg,
				},
			})
			-- Move current line to bottom of screen to show message
			TERM.feed("zb<Right><Left>")
		end, 0)
	end

	opts.keys:add({
		label = "select",
		keys = CONFIG.keys.select or "<CR>",
		callback = function()
			local option = data.options[vim.fn.line(".")]
			win:close()
			UI.handle_callback(option.callback(option.args))
		end,
	})

	opts.keys:add({
		label = "close",
		keys = CONFIG.keys.close or { "q", "<Esc>" },
		callback = function()
			win:close()
			UI._fg:focus()
			UI._priority_legend = {}
		end,
	})

	UI._priority_legend = opts.keys:legend()
end
