local UI = require("rabbit.term.listing")
local CTX = require("rabbit.term.ctx")
local BOX = require("rabbit.term.border")
local MEM = require("rabbit.util.mem")
local CONFIG = require("rabbit.config")
local HL = require("rabbit.term.highlight")

---@param data Rabbit.Message.Menu
return function(data)
	if #data.options == 0 then
		return
	end

	if #data.options == 1 then
		return UI.handle_callback(data.options[1].callback(data.options[1].args))
	end

	local height = #data.options + 2
	local width = UI._fg.conf.width or 64
	local row = math.floor((UI._fg.conf.height - height) / 2)

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

	local win = CTX.scratch({
		config = {
			row = row,
			col = 0,
			width = width,
			height = height,
			relative = "win",
			win = UI._fg.win,
			style = "minimal",
			zindex = 60,
		},
		focus = true,
		parent = UI._fg,
		lines = lines,
		many = true,
	})

	local opts = CTX.scratch({
		config = {
			row = 1,
			col = 1,
			width = width - 2,
			height = height - 2,
			relative = "win",
			win = win.win,
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
			end, { buffer = opts.buf })
		end
	end

	opts:set_lines(lines)

	opts:bind("select", CONFIG.keys.select or "<CR>", function()
		local option = data.options[vim.fn.line(".")]
		win:close()
		UI.handle_callback(option.callback(option.args))
	end)

	opts:bind("close", CONFIG.keys.close or { "q", "<Esc>" }, function()
		win:close()
		UI._fg:focus()
		UI._priority_legend = {}
	end)

	UI._priority_legend = opts:legend()
end
