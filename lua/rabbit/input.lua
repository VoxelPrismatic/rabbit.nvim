local screen = require("rabbit.screen")


---@class Rabbit.Input
local M = {}


-- Prompts the user with a question for short-text input
---@param title string The question/input prompt
---@param callback fun(response: string) The callback to be called with the user's input
---@param check? fun(response: string): boolean The callback to check the user's input
---@param default? string The default value
function M.prompt(title, callback, check, default)
	local rabbit = require("rabbit")

	check = check or function() return true end

	if default == nil then
		default = ""
	end

	screen.ctx.in_input = true
	local buf = vim.api.nvim_create_buf(false, true)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "win",
		width = screen.ctx.width - 4,
		height = 1,
		row = (screen.ctx.height - 3) / 2,
		col = 1,

		style = "minimal",
		border = {
			screen.ctx.box.top_left,
			screen.ctx.box.horizontal,
			screen.ctx.box.top_right,
			screen.ctx.box.vertical,
			screen.ctx.box.bottom_right,
			screen.ctx.box.horizontal,
			screen.ctx.box.bottom_left,
			screen.ctx.box.vertical
		},
		title = {{
			screen.ctx.box.horizontal .. " " .. title .. " ",
			"FloatBorder"
		}}
	})

	vim.fn.feedkeys("i", "n")
	vim.fn.feedkeys(default, "n")

	vim.api.nvim_create_autocmd("InsertLeave", {
		buffer = buf,
		callback = function()
			screen.ctx.in_input = false
			vim.api.nvim_win_close(win, true)
			vim.api.nvim_buf_delete(buf, { force = true })
			vim.fn.feed_termcodes("<Esc>", "n")
		end
	})

	vim.api.nvim_create_autocmd("TextChangedI", {
		buffer = buf,
		callback = function()
			vim.api.nvim_buf_clear_namespace(buf, 42, 0, -1)
			if not check(vim.fn.getline(".")) then
				vim.api.nvim_buf_add_highlight(buf, 42, "Error", 0, 0, -1)
			end
		end
	})

	local cb = function()
		local line = vim.fn.getline(".")
		if not check(line) then
			return
		end
		screen.ctx.in_input = false
		vim.api.nvim_win_close(win, true)
		vim.api.nvim_buf_delete(buf, { force = true })
		callback(line)
		vim.fn.feed_termcodes("<Esc>", "n")
	end

	for _, k in ipairs(rabbit.opts.default_keys.select) do
		vim.api.nvim_buf_set_keymap(buf, "i", k, "", { callback = cb })
	end
end


return M
