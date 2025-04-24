local CONFIG = require("rabbit.config")
local SET = require("rabbit.util.set")
local TERM = require("rabbit.util.term")
local HL = {}

-- Will create a new highlight group
---@param color Rabbit.Color The color to use for the highlight group. If a string, it will create a new table with [key] = color
---@param key? "fg" | "bg" The key to use for the color. If [color] is a table, this is ignored.
---@return vim.api.keyset.highlight The highlight group
function HL.gen_group(color, key)
	while type(color) == "function" do
		color = color()
	end

	if type(color) == "string" then
		color = { [key or "fg"] = color }
	end

	if type(color) ~= "table" then
		error("Expected string or table, got " .. type(color))
	end

	for k, v in pairs(color) do
		if type(v) == "string" and v:sub(1, 1) == ":" then
			if v:find("#") ~= nil then
				local real_k = v:gsub("^:.*#(%w+)$", "%1")
				local real_hl = v:gsub("^:(.*)#%w+$", "%1")
				color[k] = vim.fn.synIDattr(vim.fn.hlID(real_hl), real_k)
			else
				color[k] = vim.fn.synIDattr(vim.fn.hlID(v:sub(2)), k)
			end
		end
	end

	return color
end

HL.overwrites = {}

-- Applies config colors
---@param groups? { [string]: Rabbit.Color }
function HL.apply(groups)
	if groups ~= nil then
		HL.overwrites = vim.tbl_deep_extend("force", HL.overwrites, groups)
	else
		groups = {}
	end

	local colors = vim.deepcopy(require("rabbit.config").colors)

	while type(colors) == "function" do
		colors = colors()
	end
	for pre, hl in pairs(colors) do
		while type(hl) == "function" do
			hl = hl()
		end

		for k, v in pairs(hl) do
			local color = "rabbit." .. pre .. "." .. k
			local old = HL.gen_group(v)
			local new = HL.gen_group(HL.overwrites[color] or {})
			local kwargs = vim.tbl_deep_extend("force", old, new)
			vim.api.nvim_set_hl(0, color, kwargs)
			groups[color] = nil
		end
	end

	for k, v in pairs(groups) do
		vim.api.nvim_set_hl(0, k, HL.gen_group(v))
	end
end

-- Copied from nvim_buf_set_lines, but we also handle highlighting here.
---@class (exact) Rabbit.Term.HlLine.Kwargs
---@field bufnr integer Buffer ID.
---@field lineno integer Start line.
---@field strict boolean If true, the lines must be strictly between start and end.
---@field ns integer | string? Namespace
---@field width integer Width
---@field lines Rabbit.Term.HlLine[] List of text.
---@field many? boolean If true, the lines field will be treated as many lines

---@param kwargs Rabbit.Term.HlLine.Kwargs
---@return integer Ending line (only useful with "many" set to true)
function HL.set_lines(kwargs)
	local ret = kwargs.lineno
	if kwargs.many then
		for _, v in ipairs(kwargs.lines) do
			if type(v) == "string" then
				vim.api.nvim_buf_set_lines(kwargs.bufnr, ret, ret + 1, false, { v })
				ret = ret + 1
			else
				ret = HL.set_lines({
					bufnr = kwargs.bufnr,
					lineno = ret,
					lines = v,
					ns = kwargs.ns,
					many = false,
					strict = kwargs.strict,
					width = kwargs.width,
				})
			end
		end
		return ret
	end

	local parts = {
		left = {
			text = "",
			hl = {},
			offset = 0,
			len = 0,
		},
		center = {
			text = "",
			hl = {},
			offset = 0,
			len = 0,
		},
		right = {
			text = "",
			hl = {},
			offset = 0,
			len = 0,
		},
	}

	local lines = { kwargs.lines }
	local width = kwargs.width
	local strict = kwargs.strict
	local lineno = kwargs.lineno
	local buf = kwargs.bufnr
	local ns = kwargs.ns or -1
	if type(ns) == "string" then
		ns = vim.api.nvim_create_namespace(ns)
	end

	while #lines > 0 do
		local v = table.remove(lines, 1)
		if type(v) == "string" then
			v = { text = v } --[[@as Rabbit.Term.HlLine]]
		else
			for i, v2 in ipairs(v) do
				table.insert(lines, i, v2)
			end

			if v.text == nil then
				goto continue
			end
		end

		local target = parts[v.align or "left"] or parts.left
		target.text = target.text .. v.text
		local old_len = target.len
		target.len = target.len + #v.text

		if v.hl == nil then
			goto continue
		end

		local inter = v.hl or {}
		if type(inter) == "string" then
			inter = { inter }
		end
		inter = SET.new(inter)

		for hl, priority in pairs(inter) do
			if type(hl) == "number" then
				-- ignore
			elseif type(priority) == "boolean" then
				if priority == true then
					inter:add(hl, -1)
				end
				inter[hl] = nil
			elseif type(priority) == "number" then
				if priority > 0 then
					inter:put(priority, hl)
				end
				inter[hl] = nil
			else
				error("Invalid highlight priority: " .. vim.inspect({ key = hl, value = priority }))
			end
		end

		table.insert(target.hl, {
			start = old_len,
			end_ = target.len,
			name = inter:compact(),
		})
		::continue::
	end

	local center_pad = (
		width
		- vim.api.nvim_strwidth(parts.left.text)
		- vim.api.nvim_strwidth(parts.right.text)
		- vim.api.nvim_strwidth(parts.center.text)
	) / 2

	local text = parts.left.text
		.. (" "):rep(math.floor(center_pad))
		.. parts.center.text
		.. (" "):rep(math.ceil(center_pad))
		.. parts.right.text

	local put = { text }

	local ok = pcall(vim.api.nvim_buf_set_lines, buf, lineno, lineno + 1, strict, put)
	if not ok then
		local max = #vim.api.nvim_buf_get_lines(buf, lineno, lineno + 1, false)
		for _ = max, lineno do
			table.insert(put, 1, "")
		end

		vim.api.nvim_buf_set_lines(buf, max - 1, lineno + 1, strict, put)
	end

	parts.center.offset = math.floor(center_pad) + parts.left.len
	parts.right.offset = parts.center.offset + math.ceil(center_pad) + parts.center.len

	for _, part in pairs(parts) do
		for _, v in ipairs(part.hl) do
			vim.api.nvim_buf_set_extmark(buf, ns, lineno, v.start + part.offset, {
				hl_group = v.name,
				end_line = lineno,
				end_col = v.end_ + part.offset,
			})
		end
	end

	return ret + 1
end

-- Splits the list of lines so each character is in it's own line
---@param lines Rabbit.Term.HlLine[]
---@return Rabbit.Term.HlLine[]
function HL.split(lines)
	lines = vim.deepcopy(lines)
	local result = {}

	while #lines > 0 do
		local line = table.remove(lines, 1)

		for _, v in ipairs(line) do
			table.insert(lines, v)
		end

		if line.text ~= nil then
			for _, char in ipairs(vim.split(line.text, "")) do
				table.insert(result, {
					text = char,
					hl = line.hl,
					align = line.align,
				})
			end
		end
	end

	return result
end

-- Wraps the lines so they fit to width
---@param lines Rabbit.Term.HlLine[]
---@param width integer
---@param indent? string
---@param indent_override? string[]
---@return ({ [1]: string, [2]: string | string[] })[][] To be passed to extmarks
---@return Rabbit.Term.HlLine[] To be passed to HL.set_lines
function HL.wrap(lines, width, indent, indent_override)
	indent = indent or ""
	indent_override = indent_override or {}
	lines = { lines }

	local syllables = {}
	local max_word_len = CONFIG.system.wrap
	if max_word_len < 1 then
		max_word_len = max_word_len * width
	end

	while #lines > 0 do
		local v = table.remove(lines, 1)
		if type(v) == "string" then
			v = { text = v } --[[@as Rabbit.Term.HlLine]]
		end

		for _, v2 in ipairs(v) do
			table.insert(lines, v2)
		end

		if v.text == nil then
			goto continue
		end

		for word in v.text:gmatch("%S+") do
			if vim.fn.strdisplaywidth(word) < max_word_len then
				table.insert(syllables, { word, v.hl })
			else
				for _, syllable in ipairs(TERM.syllables[word]) do
					table.insert(syllables, { syllable, v.hl })
				end
			end
			table.insert(syllables, { " ", v.hl })
		end
		table.remove(syllables, #syllables)

		::continue::
	end

	---@type ({ [1]: string, [2]: string | string[] })[][]
	local ret = {}
	local line_width = width + 1
	local last_line = {}
	local last_syllable = { " ", "Normal" }
	local last_part = {}
	for _, syllable in ipairs(syllables) do
		local syllable_width = vim.fn.strdisplaywidth(syllable[1])
		if line_width + syllable_width < width - 1 then
			if syllable[2] == last_part[2] then
				last_part[1] = last_part[1] .. syllable[1]
			else
				table.insert(last_line, syllable)
			end
			line_width = line_width + syllable_width
		else
			last_line = {}
			table.insert(ret, last_line)
			local ident = { indent_override[#ret] or indent, syllable[2] }
			table.insert(last_line, ident)
			line_width = vim.fn.strdisplaywidth(ident[1])
			if syllable[1] == " " then
				-- pass
			elseif last_syllable[1] == " " then
				ident[1] = ident[1] .. syllable[1]
				line_width = line_width + syllable_width
			else
				last_part[1] = last_part[1] .. "—"
				ident[1] = ident[1] .. "—" .. syllable[1]
				line_width = line_width + syllable_width + 1
			end
		end
		last_syllable = syllable
		last_part = last_line[#last_line]
	end

	if line_width > 0 then
		local fill = width - line_width
		last_part[1] = last_part[1] .. (" "):rep(fill)
	end

	local hl_ret = {}
	for _, line in ipairs(ret) do
		local hl_line = {}
		for _, part in ipairs(line) do
			table.insert(hl_line, {
				text = part[1],
				hl = part[2],
			})
		end
	end

	return ret, hl_ret
end

---@class Rabbit.Term.HlLine.Loc
---@field start integer Where the highlight starts
---@field end_ integer Where the highlight ends
---@field name string The highlight group

---@class (exact) Rabbit.Term.HlLine: table<Rabbit.Term.HlLine>
---@field text? string The text to display.
---@field hl? : The highlight group to apply to text.
---| string # Single highlight group.
---| string[] # Multiple highlight groups.
---| { [string]: boolean } # { [hl]: enabled } pairs; if enabled, highlight is applied.
---| { [string]: integer } # { [hl]: priority } pairs; 0 = disabled and the highlight won't be applied.
---@field align? "left" | "center" | "right" : The text alignment.
---@field [integer] Rabbit.Term.HlLine Nested lines.

---@class (exact) Rabbit.Term.HlLine.NoAlign: table<Rabbit.Term.HlLine.NoAlign>
---@field text? string The text to display
---@field hl? : The highlight group to apply to text.
---| string # Single highlight group.
---| string[] # Multiple highlight groups.
---| { [string]: boolean } # { [hl]: enabled } pairs; if enabled, highlight is applied.
---| { [string]: integer } # { [hl]: priority } pairs; 0 = disabled and the highlight won't be applied.
---@field [integer] Rabbit.Term.HlLine.NoAlign Nested lines.

return HL
