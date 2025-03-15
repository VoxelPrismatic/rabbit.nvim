local BOX = {}

local border_flags = {
	[tonumber("000000", 2)] = "┌┐└┘─│", -- Thin, Solid, Square
	[tonumber("000001", 2)] = "┏┓┗┛━┃", -- Bold, Solid, Square
	[tonumber("000010", 2)] = "╔╗╚╝═╦", -- Double, Solid, Square
	[tonumber("000100", 2)] = "┌┐└┘┄┆", -- Thin, Dash, Square
	[tonumber("000101", 2)] = "┏┓┗┛┅┇", -- Bold, Dash, Square
	[tonumber("001000", 2)] = "┌┐└┘┈┊", -- Thin, Dot, Square
	[tonumber("001001", 2)] = "┏┓┗┛┉┋", -- Bold, Dot, Square
	[tonumber("010000", 2)] = "┌┐└┘╌╎", -- Thin, Double, Square
	[tonumber("010001", 2)] = "┏┓┗┛╍╏", -- Bold, Double, Square
	[tonumber("100000", 2)] = "╭╮╰╯─│", -- Thin, Solid, Round
	[tonumber("100100", 2)] = "╭╮╰╯┄┆", -- Thin, Dash, Round
	[tonumber("101000", 2)] = "╭╮╰╯┈┊", -- Thin, Dot, Round
	[tonumber("110000", 2)] = "╭╮╰╯╌╎", -- Thin, Double, Round
}

-- Returns the corresponding border based on a few parameters
---@see Rabbit.Term.Border.Custom.Kwargs
---@param kwargs Rabbit.Term.Border.Custom.Kwargs
---@return string The corresponding border string
function BOX.flag(kwargs)
	local f = 0
	if kwargs.weight == "thin" then
		-- Pass
	elseif kwargs.weight == "bold" then
		f = f + tonumber("000001", 2)
		kwargs.corner = "square"
	elseif kwargs.weight == "double" then
		f = f + tonumber("000010", 2)
		kwargs.corner = "square"
		kwargs.stroke = "solid"
	end

	if kwargs.stroke == "solid" then
		-- Pass
	elseif kwargs.stroke == "dash" then
		f = f + tonumber("000100", 2)
	elseif kwargs.stroke == "dot" then
		f = f + tonumber("001000", 2)
	elseif kwargs.stroke == "double" then
		f = f + tonumber("010000", 2)
	end

	if kwargs.corner == "square" then
		-- Pass
	elseif kwargs.corner == "round" then
		f = f + tonumber("100000", 2)
	end

	local s = border_flags[f]
	if s == nil then
		error("Invalid border parameters")
	end
	return s
end

-- Expands a border string to a border table
---@see Rabbit.Term.Border.Box
---@param border Rabbit.Term.Border.String The border string; Format: ╭╮╰╯─│┃
---@return Rabbit.Term.Border.Box
function BOX.expand(border)
	return { ---@type Rabbit.Term.Border.Box
		nw = vim.fn.strcharpart(border, 0, 1),
		ne = vim.fn.strcharpart(border, 1, 1),
		sw = vim.fn.strcharpart(border, 2, 1),
		se = vim.fn.strcharpart(border, 3, 1),
		h = vim.fn.strcharpart(border, 4, 1),
		v = vim.fn.strcharpart(border, 5, 1),
		scroll = vim.fn.strcharpart(border, 6, 1),
	}
end

-- Creates a border box with the specified parameters
---@see Rabbit.Term.Border.Custom
---@param kwargs Rabbit.Term.Border.Custom
---@return Rabbit.Term.Border.Box
function BOX.custom(kwargs)
	if type(kwargs) ~= "table" then
		error("Expected table, got " .. type(kwargs))
	end

	---@type Rabbit.Term.Border.Custom.Kwargs
	kwargs = {
		weight = kwargs.weight or kwargs[2] or "thin",
		stroke = kwargs.stroke or kwargs[3] or "solid",
		corner = kwargs.corner or kwargs[1] or "square",
		scrollbar = kwargs.scrollbar or kwargs[5] or { "bold", "solid" },
	}

	if type(kwargs.scrollbar) == "string" then
		return BOX.expand(BOX.flag(kwargs) .. kwargs.scrollbar)
	end

	kwargs.scrollbar = {
		weight = kwargs.scrollbar.weight or kwargs.scrollbar[1] or "double",
		stroke = kwargs.scrollbar.stroke or kwargs.scrollbar[2] or "solid",
	}

	---@diagnostic disable-next-line: param-type-mismatch
	return BOX.expand(BOX.flag(kwargs) .. vim.fn.strcharpart(BOX.flag(kwargs.scrollbar), 6, 1))
end

-- Normalizes a border input
---@see Rabbit.Term.Border
---@param border Rabbit.Term.Border
---@return Rabbit.Term.Border.Box
function BOX.normalize(border)
	if type(border) == "string" then
		return BOX.expand(border)
	end

	if type(border) ~= "table" then
		error("Expected string or table, got " .. type(border))
	end

	if border.nw ~= nil then
		return border ---@type Rabbit.Term.Border.Box
	end

	---@diagnostic disable-next-line: param-type-mismatch
	return BOX.custom(border)
end

-- Makes sides for a border
---@param w integer Border width
---@param h integer Border height
---@param box Rabbit.Term.Border.Box
---@param ... Rabbit.Term.Border.Side
---@return Rabbit.Term.Border.Applied
function BOX.make_sides(w, h, box, ...)
	local sides = {
		t = { txt = {}, hl = {} },
		b = { txt = {}, hl = {} },
		r = { txt = {}, hl = {} },
		l = { txt = {}, hl = {} },
	}

	local targets = {
		nw = { sides.t, "left" },
		n = { sides.t, "center" },
		ne = { sides.t, "right" },
		en = { sides.r, "left" },
		e = { sides.r, "center" },
		es = { sides.r, "right" },
		se = { sides.b, "right" },
		s = { sides.b, "center" },
		sw = { sides.b, "left" },
		ws = { sides.l, "right" },
		w = { sides.l, "center" },
		wn = { sides.l, "left" },
	}

	box = BOX.normalize(box)

	for i = 1, w - 2 do
		sides.t.txt[i] = box.h
		sides.b.txt[i] = box.h
	end

	for i = 1, h - 2 do
		sides.l.txt[i] = box.v
		sides.r.txt[i] = box.v
	end

	for _, side in ipairs({ ... }) do
		vim.print(side)
		if type(side) ~= "table" then
			error("Expected table, got " .. type(side))
		elseif side.align == "nil" then
			goto continue
		end

		local target, align = unpack(targets[side.align])
		if target == nil then
			error("Invalid alignment: " .. side.align)
		elseif type(side.make) == "function" then
			side.pre, side.text, side.suf = side.make(#target.txt, side.text)
		end

		side.pre = tostring(side.pre or "")
		side.text = tostring(side.text or "")
		side.suf = tostring(side.suf or "")

		local strls = {}
		for _, v in ipairs(vim.fn.str2list(side.pre .. side.text .. side.suf)) do
			table.insert(strls, vim.fn.list2str({ v }))
		end

		local pre_end = vim.fn.strdisplaywidth(side.pre)
		local text_end = vim.fn.strdisplaywidth(side.pre .. side.text)
		local start, end_ = 0, 0

		if align == "left" then
			start, end_ = 1, #strls
		elseif align == "center" then
			start = math.max(1, math.ceil((#target.txt - #strls + 1) / 2))
			end_ = math.min(#target.txt, start + #strls - 1)
		else
			start = #target.txt - #strls + 1
			end_ = #target.txt
		end

		for i = start, end_ do
			local j = i - start + 1
			target.txt[i] = strls[j]
			if pre_end < j and j <= text_end then
				table.insert(target.hl, #table.concat(target.txt, "", 1, i))
			end
		end

		::continue::
	end

	return sides
end

return BOX
