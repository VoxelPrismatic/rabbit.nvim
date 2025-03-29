local HL = {}

-- Will create a new highlight group
---@param color Color | NvimHlKwargs The color to use for the highlight group. If a string, it will create a new table with [key] = color
---@param key? "fg" | "bg" The key to use for the color. If [color] is a table, this is ignored.
---@return vim.api.keyset.highlight The highlight group
function HL.gen_group(color, key)
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
---@param groups? { [string]: string | NvimHlKwargs }
function HL.apply(groups)
	if groups ~= nil then
		HL.overwrites = vim.tbl_deep_extend("force", HL.overwrites, groups)
	else
		groups = {}
	end

	local colors = vim.deepcopy(require("rabbit.config").colors)
	for pre, hl in pairs(colors) do
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
---@field ns integer? Namespace
---@field width integer Width
---@field lines Rabbit.Term.HlLine[] List of text.
---@field many? boolean If true, the lines field will be treated as many lines

---@param kwargs Rabbit.Term.HlLine.Kwargs
function HL.set_lines(kwargs)
	if kwargs.many then
		for i, v in ipairs(kwargs.lines) do
			if type(v) == "string" then
				vim.api.nvim_buf_set_lines(kwargs.bufnr, kwargs.lineno + i - 1, kwargs.lineno + i, false, { v })
			else
				HL.set_lines({
					bufnr = kwargs.bufnr,
					lineno = kwargs.lineno + i - 1,
					lines = v,
					ns = kwargs.ns,
					many = false,
					strict = kwargs.strict,
					width = kwargs.width,
				})
			end
		end
		return
	end

	local parts = {
		left = {
			text = "",
			hl = {},
		},
		center = {
			text = "",
			hl = {},
		},
		right = {
			text = "",
			hl = {},
		},
	}

	local lines = { kwargs.lines }
	local width = kwargs.width
	local strict = kwargs.strict
	local lineno = kwargs.lineno
	local buf = kwargs.bufnr
	local ns = kwargs.ns

	while #lines > 0 do
		local v = table.remove(lines, 1)

		for i, v2 in ipairs(v) do
			table.insert(lines, i, v2)
		end

		if v.text == nil then
			goto continue
		end

		local target = parts[v.align or "left"]
		target.text = target.text .. v.text
		if v.hl ~= nil then
			---@type string[]
			---@diagnostic disable-next-line: assign-type-mismatch
			local hls = type(v.hl) == "string" and { v.hl } or v.hl
			for k, enable in pairs(hls) do
				if type(k) == "string" and enable then
					table.insert(hls, k)
				end
			end

			for _, hl in ipairs(hls) do
				table.insert(target.hl, {
					start = #target.text - #v.text,
					end_ = #target.text,
					name = hl,
				})
			end
		end
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

	local ok = pcall(vim.api.nvim_buf_set_lines, buf, lineno, lineno + 1, strict, { text })
	if not ok then
		local max = #vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		local empty = {}
		for _ = max, lineno + 1 do
			table.insert(empty, "")
		end
		vim.api.nvim_buf_set_lines(buf, max - 1, lineno, false, empty)
		vim.api.nvim_buf_set_lines(buf, lineno, lineno + 1, strict, { text })
	end

	for _, v in ipairs(parts.left.hl) do
		vim.api.nvim_buf_set_extmark(buf, ns or 0, lineno, v.start, {
			hl_group = v.name,
			end_line = lineno,
			end_col = v.end_,
		})
	end

	local offset = #parts.left.text + math.floor(center_pad)
	for _, v in ipairs(parts.center.hl) do
		vim.api.nvim_buf_set_extmark(buf, ns or 0, lineno, v.start + offset, {
			hl_group = v.name,
			end_line = lineno,
			end_col = v.end_ + offset,
		})
	end

	offset = #parts.left.text + math.floor(center_pad) + #parts.center.text + math.ceil(center_pad)
	for _, v in ipairs(parts.right.hl) do
		vim.api.nvim_buf_set_extmark(buf, ns or 0, lineno, v.start + offset, {
			hl_group = v.name,
			end_line = lineno,
			end_col = v.end_ + offset,
		})
	end
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

---@class Rabbit.Term.HlLine.Loc
---@field start integer Where the highlight starts
---@field end_ integer Where the highlight ends
---@field name string The highlight group

---@class Rabbit.Term.HlLine
---@field text string The text to display
---@field hl? string | string[] | { [string]: boolean } The highlight group
---@field align? "left" | "right" | "center" The alignment of the text
return HL
