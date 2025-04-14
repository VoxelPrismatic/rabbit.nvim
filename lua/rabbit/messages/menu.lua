local UI = require("rabbit.term.listing")
local BOX = require("rabbit.term.border")
local CONFIG = require("rabbit.config")
local STACK = require("rabbit.term.stack")

---@param data Rabbit.Message.Menu
return function(data)
	if #data.options == 0 then
		return
	end

	if #data.options == 1 then
		return UI.handle_callback(data.options[1].callback(data.options[1].args))
	end

	local height = #data.options + 2
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
			border_hl = "rabbit.popup.info",
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
