--- Screen handler for Rabbit
---@class screen
local screen = {
	ctx = {
		title = {}, ---@type Rabbit.Screen.Spec[]
		middle = {}, ---@type Rabbit.Screen.Spec[]
		footer = {}, ---@type Rabbit.Screen.Spec[]
		box = {}, ---@type Rabbit.Box | {}
		height = 0,
		width = 0,
		bufnr = nil,
		winnr = nil,
		fullscreen = false,
		in_input = false,
	}
}

-- Undo possible recursion in screen spec
---@param specs Rabbit.Screen.Spec[]
---@param width number
function screen.helper(specs, width)
	local fulltext = ""
	local highlights = {}
	for _, spec in ipairs(specs) do
		local spectext = ""
		if type(spec[1]) == "table" then
			local ret = screen.helper(spec, width)
			for _, s in ipairs(ret.highlights) do
				table.insert(highlights, {
					name = s.name,
					start = s.start + #fulltext,
					last = s.last + #fulltext,
				})
			end
			fulltext = fulltext .. ret.fulltext
			goto continue
		end

		if type(spec.text) == "table" then
			-- This is handled, as you can see
			---@diagnostic disable-next-line: param-type-mismatch
			for _, part in ipairs(spec.text) do
				spectext = spectext .. part
			end
		else
			spectext = spec.text .. ""
		end

		if spec.expand then
			local char = type(spec.expand) == "string" and tostring(spec.expand) or " "
			spectext = (char):rep(width - vim.fn.strwidth(fulltext .. spectext)) .. spectext
		end

		if spec.color ~= nil and #(spec.color) > 1 then
			table.insert(highlights, {
				name = spec.color,
				start = #fulltext,
				last = #fulltext + #spectext
			})
		end

		fulltext = fulltext .. spectext

		::continue::
	end

	return {
		fulltext = fulltext,
		highlights = highlights
	}
end

-- Renders to the screen
---@param line number
---@param specs Rabbit.Screen.Spec[]
---@return integer integer The next available line
function screen.render(line, specs)
	local win = screen.ctx.winnr or 0
	local buf = screen.ctx.bufnr or 0
	if line == -1 then
		line = vim.api.nvim_buf_line_count(buf)
	else
		line = math.max(0, math.min(line, vim.api.nvim_buf_line_count(buf)))
	end

	local finalspec = screen.helper(specs, vim.api.nvim_win_get_width(win))
	vim.api.nvim_buf_set_lines(buf, line, line + 1, false, { finalspec.fulltext })

	for _, hl in ipairs(finalspec.highlights) do
		vim.api.nvim_buf_add_highlight(buf, -1, hl.name, line, hl.start, hl.last)
	end
	return line + 1
end


-- Places a newline before the specs
---@param spec Rabbit.Screen.Spec[]
---@param line? integer the line to start at
---@return integer integer The next available line
function screen.newline(spec, line)
	if line == nil then
		line = -1
	end
	screen.render(line, { color = "RabbitBorder", text = " " })
	screen.render(line == -1 and -1 or line + 1, spec)
	return line == -1 and -1 or line + 2
end


---@param c string | NvimHlKwargs
---@param key? string The default highlight key, eg `fg` or `bg`
---@return vim.api.keyset.highlight
local function maybe_hl(c, key)
	if type(c) == "string" then
		return { [key or "fg"] = c } ---@type vim.api.keyset.highlight
	end
	---@type vim.api.keyset.highlight
	return c
end


-- Sets the highlight group names
---@param colors Rabbit.Options.Color
---@param border_color NvimHlKwargs | string
function screen.set_hl(colors, border_color)
	vim.api.nvim_set_hl(0, "RabbitBorder", maybe_hl(border_color))
	vim.api.nvim_set_hl(0, "RabbitDir", maybe_hl(colors.dir))
	vim.api.nvim_set_hl(0, "RabbitFile", maybe_hl(colors.file))
	vim.api.nvim_set_hl(0, "RabbitIndex", maybe_hl(colors.index))
	vim.api.nvim_set_hl(0, "RabbitTitle", maybe_hl(colors.title))
	vim.api.nvim_set_hl(0, "RabbitTerm", maybe_hl(colors.term))
	vim.api.nvim_set_hl(0, "RabbitNil", maybe_hl(colors.noname))
	vim.api.nvim_set_hl(0, "RabbitMsg", maybe_hl(colors.message))
end


-- Adds a new border to the screen
---@param win integer
---@param buf integer
---@param kwargs Rabbit.Screen.Border_Kwargs
---@return false | Rabbit.Screen.Spec
function screen.set_border(win, buf, kwargs)
	local fs = kwargs.fullscreen and { text = "", color = "" } or false
	local c = (kwargs.width - 2 - #(kwargs.title)) / 2 - 1
	local emph = math.min(c - 4, kwargs.emph_width)

	screen.set_hl(kwargs.colors, kwargs.border_color)

	screen.ctx.height = kwargs.height
	screen.ctx.width = kwargs.width
	screen.ctx.bufnr = buf
	screen.ctx.winnr = win
	screen.ctx.box = kwargs.box
	screen.fullscreen = fs

	if fs then
		screen.ctx.title = {
			{ text = kwargs.box.emphasis(emph), color = "RabbitBorder" },
			{ text = " " .. kwargs.title .. " ", color = "RabbitTitle" },
			{ text = kwargs.box.emphasis(emph), color = "RabbitBorder" },
		}
		screen.ctx.middle = { fs }
		screen.ctx.footer = { fs }

		screen.draw_top()

		return fs
	end


	screen.ctx.title = {
		{
			color = "RabbitBorder",
			text = {
				kwargs.box.top_left,
				kwargs.box.horizontal:rep(c - emph),
				kwargs.box.emphasis:rep(emph),
			},
		}, {
			color = "RabbitTitle",
			text = " " .. kwargs.title .. " ",
		}, {
			color = "RabbitBorder",
			text = kwargs.box.emphasis:rep(emph),
		}, {
			color = "RabbitBorder",
			text = kwargs.box.top_right,
			expand = kwargs.box.horizontal,
		},
	}

	screen.ctx.middle = {{
		color = "RabbitBorder",
		text = {
			kwargs.box.vertical,
			(" "):rep(kwargs.width - 2),
			kwargs.box.vertical,
		},
	}}

	screen.ctx.footer = {
		{
			color = "RabbitBorder",
			text = kwargs.box.bottom_left,
		}, {
			color = "RabbitBorder",
			text = {
				kwargs.mode,
				kwargs.box.horizontal:rep(3),
				kwargs.box.bottom_right,
			},
			expand = kwargs.box.horizontal,
		}
	}

	screen.draw_top()

	return fs
end

-- Draw the header and first empty line
---@param clear? boolean Whether to clear the screen (default = true)
function screen.draw_top(clear)
	if #screen.ctx.title == 0 then
		return false
	end

	if clear or clear == nil then
		vim.api.nvim_buf_set_lines(screen.ctx.bufnr, 0, -1, false, {})
	end

	screen.render(0, screen.ctx.title)
	screen.render(1, screen.ctx.middle)
end

-- Fill the rest of the screen with empty lines
---@param line? integer Which line to use (default = -1)
---@return integer integer The next empty line
function screen.draw_bottom(line)
	local max = vim.api.nvim_buf_line_count(screen.ctx.bufnr)

	if line == nil then
		line = max
	elseif line > screen.ctx.height - 2 then
		screen.render(-1, screen.ctx.middle)
		return screen.render(-1, screen.ctx.footer)
	else
		line = math.max(0, math.min(max + 1, line))
	end

	for i = line, screen.ctx.height - 2 do
		screen.render(i, screen.ctx.middle)
	end

	return screen.render(screen.ctx.height - 1, screen.ctx.footer)
end


-- Add a buffer entry to the screen.
-- __NOTE:__ Only place the file/term/dir specs. This
-- function handles the border and index for you.
---@param spec Rabbit.Screen.Spec[]
---@param line? integer Which line to use (default = -1)
function screen.add_entry(spec, line)
	if line == nil then
		line = -1
	end
	local i = #vim.api.nvim_buf_get_lines(screen.ctx.bufnr, 0, line, false) - 1

	if i < 10 then
		vim.api.nvim_buf_set_keymap(screen.ctx.bufnr, "n", "" .. i, "", {
			noremap = true,
			silent = true,
			callback = function()
				local r = require("rabbit")
				local cb = r.ctx.plugin.func.select or r.func.select
				cb(i)
			end
		})
	end

	---@type Rabbit.Screen.Spec[]
	local to_render = screen.ctx.fullscreen and {} or {
		{
			color = "RabbitBorder",
			text = screen.ctx.box.vertical .. " "
		}, {
			color = "RabbitIndex",
			text = (screen.ctx.fullscreen and " " or "") .. (i < 10 and " " or "") .. i .. ". "
		},
	}

	for _, v in ipairs(spec) do
		table.insert(to_render, v)
	end

	table.insert(to_render, screen.ctx.fullscreen or {
		color = "RabbitBorder",
		text = screen.ctx.box.vertical,
		expand = true
	})

	screen.render(line, to_render)
end


-- Clear the screen and display a message instead.
-- This also handles wrapping.
---@param msg string
function screen.display_message(msg)
	screen.draw_top()
	local fullscreen = screen.ctx.fullscreen and { text = "", color = "" } or false
	local lines = { "" }

	for word in msg:gmatch("[^ ]+") do
		if (#(lines[#lines]) + #word > screen.ctx.width - 4) and not fullscreen then
			lines[#lines + 1] = ""
		end
		lines[#lines] = lines[#lines] .. word .. " "
	end

	for _, line in ipairs(lines) do
		screen.render(-1, {
			fullscreen or { color = "RabbitBorder", text = screen.ctx.box.vertical .. " " },
			{ color = "RabbitFile", text = line },
			fullscreen or { color = "RabbitBorder", text = screen.ctx.box.vertical, expand = true },
		})
	end

	screen.draw_bottom()
end


return screen
