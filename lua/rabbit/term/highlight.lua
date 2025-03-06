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
			color[k] = vim.fn.synIDattr(vim.fn.hlID(v:sub(2)), k)
		end
	end

	return color
end

function HL.apply()
	local colors = require("rabbit.config").colors
	for pre, hl in pairs(colors) do
		for k, v in pairs(hl) do
			vim.api.nvim_set_hl(0, "rabbit." .. pre .. "." .. k, HL.gen_group(v))
		end
	end
end

-- Copied from nvim_buf_set_lines, but we also handle highlighting here.
---@param buf integer Buffer ID.
---@param line integer Start line.
---@param strict boolean If true, the lines must be strictly between start and end.
---@param ns integer? Namespace
---@param width integer? Width
---@param lines Rabbit.Term.HlLine[] List of text.
function HL.nvim_buf_set_line(buf, line, strict, ns, width, lines)
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
	for _, v in ipairs(lines) do
		if v.text == nil then
			goto continue
		end

		local target = parts[v.align or "left"]
		target.text = target.text .. v.text
		if v.hl ~= nil then
			---@type string[]
			---@diagnostic disable-next-line: assign-type-mismatch
			local hls = type(v.hl) == "string" and { v.hl } or v.hl

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
		- vim.fn.strdisplaywidth(parts.left.text)
		- vim.fn.strdisplaywidth(parts.right.text)
		- vim.fn.strdisplaywidth(parts.center.text)
	) / 2
	local text = parts.left.text
		.. (" "):rep(math.floor(center_pad))
		.. parts.center.text
		.. (" "):rep(math.ceil(center_pad))
		.. parts.right.text

	vim.api.nvim_buf_set_lines(buf, line, line + 1, strict, { text })

	for _, v in ipairs(parts.left.hl) do
		vim.api.nvim_buf_add_highlight(buf, ns or -1, v.name, line, v.start, v.end_)
	end

	local offset = #parts.left.text + math.floor(center_pad)
	for _, v in ipairs(parts.center.hl) do
		vim.api.nvim_buf_add_highlight(buf, ns or -1, v.name, line, v.start + offset, v.end_ + offset)
	end

	offset = #parts.left.text + math.floor(center_pad) + #parts.center.text + math.ceil(center_pad)
	for _, v in ipairs(parts.right.hl) do
		vim.api.nvim_buf_add_highlight(buf, ns or -1, v.name, line, v.start + offset, v.end_ + offset)
	end
end

---@class Rabbit.Term.HlLine.Loc
---@field start integer Where the highlight starts
---@field end_ integer Where the highlight ends
---@field name string The highlight group

---@class Rabbit.Term.HlLine
---@field text string The text to display
---@field hl? string | string[] The highlight group
---@field align? "left" | "right" | "center" The alignment of the text
return HL
