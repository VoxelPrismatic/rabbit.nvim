M = {}

local border_flags = {
	[0b000000] = "┌┐└┘─│", -- Thin, Solid, Square
	[0b000001] = "┏┓┗┛━┃", -- Bold, Solid, Square
	[0b000010] = "╔╗╚╝═╦", -- Double, Solid, Square
	[0b000100] = "┌┐└┘┄┆", -- Thin, Dash, Square
	[0b000101] = "┏┓┗┛┅┇", -- Bold, Dash, Square
	[0b001000] = "┌┐└┘┈┊", -- Thin, Dot, Square
	[0b001001] = "┏┓┗┛┉┋", -- Bold, Dot, Square
	[0b010000] = "┌┐└┘╌╎", -- Thin, Double, Square
	[0b010001] = "┏┓┗┛╍╏", -- Bold, Double, Square
	[0b100000] = "╭╮╰╯─│", -- Thin, Solid, Round
	[0b100100] = "╭╮╰╯┄┆", -- Thin, Dash, Round
	[0b101000] = "╭╮╰╯┈┊", -- Thin, Dot, Round
	[0b110000] = "╭╮╰╯╌╎", -- Thin, Double, Round
}

-- Creates a border style flag for quick lookup
---@see Rabbit.Term.Border.Custom.Kwargs
---@param kwargs Rabbit.Term.Border.Custom.Kwargs
---@return string The corresponding border string
function M.flag(kwargs)
	local f = 0
	if kwargs.weight == "thin" then
		-- Pass
	elseif kwargs.weight == "bold" then
		f = f + 0b000001
		kwargs.corner = "square"
	elseif kwargs.weight == "double" then
		f = f + 0b000010
		kwargs.corner = "square"
		kwargs.stroke = "solid"
	end

	if kwargs.stroke == "solid" then
		-- Pass
	elseif kwargs.stroke == "dash" then
		f = f + 0b000100
	elseif kwargs.stroke == "dot" then
		f = f + 0b001000
	elseif kwargs.stroke == "double" then
		f = f + 0b010000
	end

	if kwargs.corner == "square" then
		-- Pass
	elseif kwargs.corner == "round" then
		f = f + 0b100000
	end

	local s = border_flags[f]
	if s == nil then
		error("Invalid border parameters")
	end
	return s
end

-- Expands a border string to a border table
---@see Rabbit.Term.Border.Box
---@param border Rabbit.Term.Border.String The border string; Format: ╭╮╰╯─│═┃
---@return Rabbit.Term.Border.Box
function M.expand(border)
	return {
		nw = border:sub(1, 3),
		ne = border:sub(4, 6),
		sw = border:sub(7, 9),
		se = border:sub(10, 12),
		h = border:sub(13, 15),
		v = border:sub(16, 18),
		emph = border:sub(19, 21),
		scroll = border:sub(22, 24),
	}
end

-- Creates a border box with the specified parameters
---@see Rabbit.Term.Border.Custom
---@param kwargs Rabbit.Term.Border.Custom
---@return Rabbit.Term.Border.Box
function M.custom(kwargs)
	if type(kwargs) ~= "table" then
		error("Expected table, got " .. type(kwargs))
	end

	---@type Rabbit.Term.Border.Custom.Kwargs
	kwargs = {
		weight = kwargs.weight or kwargs[2] or "thin",
		stroke = kwargs.stroke or kwargs[3] or "solid",
		corner = kwargs.corner or kwargs[1] or "square",
		emphasis = kwargs.emphasis or kwargs[4] or { "double", "solid" },
		scrollbar = kwargs.scrollbar or kwargs[5] or { "bold", "solid" },
	}

	---@type Rabbit.Term.Border.Custom.Extras.Kwargs
	kwargs.emphasis = {
		weight = kwargs.emphasis.weight or kwargs.emphasis[1] or "double",
		stroke = kwargs.emphasis.stroke or kwargs.emphasis[2] or "solid",
	}

	---@type Rabbit.Term.Border.Custom.Extras.Kwargs
	kwargs.scrollbar = {
		weight = kwargs.scrollbar.weight or kwargs.scrollbar[1] or "double",
		stroke = kwargs.scrollbar.stroke or kwargs.scrollbar[2] or "solid",
	}

	---@diagnostic disable-next-line: param-type-mismatch
	return M.expand(M.flag(kwargs) .. M.flag(kwargs.emphasis):sub(13, 15) .. M.flag(kwargs.scrollbar):sub(16, 18))
end

-- Normalizes a border input
---@see Rabbit.Term.Border
---@param border Rabbit.Term.Border
---@return Rabbit.Term.Border.Box
function M.normalize(border)
	if type(border) == "string" then
		return M.expand(border)
	end

	if type(border) ~= "table" then
		error("Expected string or table, got " .. type(border))
	end

	if border.nw ~= nil then
		return border ---@type Rabbit.Term.Border.Box
	end

	---@diagnostic disable-next-line: param-type-mismatch
	return M.custom(border)
end

return M
