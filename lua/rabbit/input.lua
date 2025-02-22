local screen = require("rabbit.screen")


---@class Rabbit.Input
---@field _buf integer Buffer ID
---@field _win integer Window ID
---@field _ns integer Namespace ID
---@field _listing Rabbit.Input.Prompt.Entry[] List of lines to be rendered
---@field _description table<string> List of description lines
local M = {}

M._ns = vim.api.nvim_create_namespace("rabbit_input")

function M.BufHighlight()
	vim.api.nvim_buf_clear_namespace(M._buf, M._ns, 0, -1)
	local len = #M._listing
	local line = vim.fn.line(".") - #M._description

	local pos = vim.api.nvim_win_get_cursor(M._win)
	if line <= 0 then
		vim.api.nvim_win_set_cursor(M._win, { #M._description + 1, pos[2] })
		line = line + 1
	elseif line > len then
		vim.api.nvim_win_set_cursor(M._win, { #M._listing + #M._description, pos[2] })
		line = line - 1
	end

	vim.api.nvim_buf_add_highlight(
		M._buf, M._ns, "CursorLine",
		line + #M._description - 1, 0, #(vim.api.nvim_get_current_line())
	)
end

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

-- Prompts the user with a list of options (up to nine)
---@param title string The question/input prompt
---@param description string Clarifies the question
---@param default? string The default value (will immediately call callback if match is found)
---@param finally? fun() The callback to call after the user has made their choice (or quit)
---@param entries Rabbit.Input.Prompt.Entry[] List of entries
function M.menu(title, description, default, finally, entries)
	local rabbit = require("rabbit")

	if entries == nil or #entries == 0 then
		return
	end

	if finally == nil then
		finally = function() end
	end

	local desc_lines = {}
	local height = #entries
	local width = screen.ctx.width - 4

	for _, e in ipairs(entries) do
		if e.text == nil then
			e.text = e[1]
		end

		if e.callback == nil then
			e.callback = e[2] or function() end
		end

		if e.color == nil then
			e.color = e[3]
		end

		if e.hidden == nil then
			e.hidden = e[4] or false
		end

		if e.hidden then
			height = height - 1
		end

		if e.text == default then
			e.callback()
			return finally()
		end
	end

	if #entries == 1 then
		entries[1].callback()
		return finally()
	end

	if #entries > 9 then
		error("Too many entries")
	end



	for line in description:gmatch("[^\n]+") do
		desc_lines[#desc_lines + 1] = " "
		for word in line:gmatch("[^ ]+") do
			local l = desc_lines[#desc_lines]
			l = l .. word .. " "
			if #l > width - 2 then
				desc_lines[#desc_lines + 1] = " " .. word .. " "
			else
				desc_lines[#desc_lines] = l
			end
		end
	end

	if #desc_lines > 0 then
		desc_lines[#desc_lines + 1] = (" "):rep(width)
		height = height + #desc_lines
	end

	M._description = desc_lines
	M._listing = entries

	screen.ctx.in_input = true
	local buf = vim.api.nvim_create_buf(false, true)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "win",
		width = width,
		height = height,
		row = (screen.ctx.height - height) / 2,
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

	M._buf = buf
	M._win = win

	local kill = function()
		screen.ctx.in_input = false
		pcall(vim.api.nvim_win_close, win, true)
		pcall(vim.api.nvim_buf_delete, buf, { force = true })
		finally()
	end

	vim.api.nvim_create_autocmd("InsertEnter", {
		buffer = buf,
		callback = function()
			vim.fn.feed_termcodes("<Esc>", "n")
		end
	})

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, desc_lines)

	local hidden = 0

	for i, e in ipairs(entries) do
		local j = i + #desc_lines - 1
		if e.hidden then
			hidden = hidden + 1
			goto continue
		end
		local line = " " .. (i - hidden) .. ". "
		local off = #line
		line = line .. e.text .. (" "):rep(width - #line - #e.text)
		vim.api.nvim_buf_set_lines(buf, j, j, false, { line })
		vim.api.nvim_buf_add_highlight(buf, -1, "RabbitIndex", j, 0, off)
		vim.api.nvim_buf_add_highlight(buf, -1, e.color or "RabbitFile", j, off, #line)
		vim.api.nvim_buf_set_keymap(buf, "n", "" .. (i - hidden), "", { callback = function()
			e.callback()
			kill()
		end})
		::continue::
	end

	local cb = function()
		local line = vim.api.nvim_win_get_cursor(win)[1] - #desc_lines
		entries[line].callback()
		kill()
	end

	for _, k in ipairs(rabbit.ctx.plugin.keys.select or rabbit.opts.default_keys.select) do
		vim.api.nvim_buf_set_keymap(buf, "n", k, "", { callback = cb })
	end

	for _, k in ipairs(rabbit.ctx.plugin.keys.close or rabbit.opts.default_keys.close) do
		vim.api.nvim_buf_set_keymap(buf, "n", k, "", { callback = kill })
	end

	vim.api.nvim_win_set_cursor(win, { #desc_lines + 1, 0 })


	vim.api.nvim_create_autocmd("CursorMoved", {
		buffer = buf,
		callback = M.BufHighlight
	})
end


function M.warn(title, msg, color)
	screen.ctx.in_input = true

	if color == nil then
		color = "RabbitPopupErr"
	end

	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "win",
		width = screen.ctx.width - 4,
		height = 1,
		row = screen.ctx.height - 3,
		col = 1,
		style = "minimal",
		border = {
			{screen.ctx.box.top_left, color},
			{screen.ctx.box.horizontal, color},
			{screen.ctx.box.top_right, color},
			{screen.ctx.box.vertical, color},
			{screen.ctx.box.bottom_right, color},
			{screen.ctx.box.horizontal, color},
			{screen.ctx.box.bottom_left, color},
			{screen.ctx.box.vertical, color}
		},
		title = {{
			screen.ctx.box.horizontal .. " " .. title .. " ",
			color
		}}
	})

	msg = " " .. msg .. (" "):rep(screen.ctx.width)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "", msg, "" })

	vim.api.nvim_win_set_cursor(win, { 2, screen.ctx.width - 5 })

	local args = {
		buffer = buf,
		callback = function()
			vim.api.nvim_win_close(win, true)
			vim.api.nvim_buf_delete(buf, { force = true })
			require("rabbit").BufHighlight()
		end
	}

	vim.api.nvim_create_autocmd({
		"BufLeave",
		"WinLeave",
		"InsertEnter",
	}, args)


	vim.api.nvim_create_autocmd("CursorMoved", {
		buffer = buf,
		callback = function()
			vim.api.nvim_clear_autocmds({ event = "CursorMoved", buffer = buf })
			vim.api.nvim_create_autocmd("CursorMoved", args)
		end
	})

	screen.ctx.in_input = false
end

return M
