local SET = require("rabbit.util.set")
local TERM = require("rabbit.util.term")
local BOX = {}

---@class (exact) Rabbit.Term.Border.Generic<T>: { b: T, t: T, l: T, r: T }

---@class (exact) Rabbit.Term.Border.Applied: Rabbit.Term.Border.Generic<Rabbit.Term.Border.Side>
---@field top_left string Top left character.
---@field bot_left string Bottom left character.
---@field top_right string Top right character.
---@field bot_right string Bottom right character.
---@field to_hl fun(self: Rabbit.Term.Border.Applied, kwargs: Rabbit.Term.Border.Applied.Hl.Kwargs): Rabbit.Term.Border.Applied.Hl Convert to highlight lines

---@class (exact) Rabbit.Term.Border.Applied.Side
---@field txt string[] Text characters
---@field hl integer[] Main text highlight indexes
---@class Rabbit.Term.Border.Applied.Hl: Rabbit.Term.Border.Generic<Rabbit.Term.HlLine[]>
---@field lines Rabbit.Term.HlLine[][] Lines of highlighted lines

---@class Rabbit.Term.Border.Applied.Hl.Kwargs
---@field border_hl string Highlight group for the border.
---@field title_hl string Highlight group for the title.

---@param self Rabbit.Term.Border.Applied
---@param kwargs Rabbit.Term.Border.Applied.Hl.Kwargs
---@return Rabbit.Term.Border.Applied.Hl
local function to_hl(self, kwargs)
	local ret = { ---@type Rabbit.Term.Border.Applied.Hl
		t = { { hl = kwargs.border_hl, text = "" } },
		b = { { hl = kwargs.border_hl, text = "" } },
		l = { { hl = kwargs.border_hl, text = self.top_left } },
		r = { { hl = kwargs.border_hl, text = self.top_right } },
		lines = {},
	}

	for _, k in ipairs({ "t", "b", "l", "r" }) do
		local v = self[k]

		local hls = SET.new(v.hl)

		local o = ret[k]
		local s = ""
		local in_title = false
		local latest = o[#o]

		for i, c in ipairs(v.txt) do
			s = s .. c
			local is_title = hls:idx(#s) ~= nil

			if is_title and not in_title then
				latest = { hl = kwargs.title_hl, text = "" }
				table.insert(o, latest)
				in_title = true
			elseif not is_title and in_title then
				latest = { hl = kwargs.border_hl, text = "" }
				table.insert(o, latest)
				in_title = false
			end
			latest.text = latest.text .. c

			if o == ret.l or o == ret.r then
				if ret.lines[i] == nil then
					ret.lines[i] = {}
				end

				table.insert(ret.lines[i], {
					hl = latest.hl,
					text = c,
					align = o == ret.l and "left" or "right",
				})
			end
		end
	end

	table.insert(ret.l, { hl = kwargs.border_hl, text = self.bot_left })
	table.insert(ret.r, { hl = kwargs.border_hl, text = self.bot_right })

	table.insert(ret.lines, 1, {
		{ text = self.top_left, hl = kwargs.border_hl, align = "left" },
		ret.t,
		{ text = self.top_right, hl = kwargs.border_hl, align = "right" },
	})

	table.insert(ret.lines, {
		{ text = self.bot_left, hl = kwargs.border_hl, align = "left" },
		ret.b,
		{ text = self.bot_right, hl = kwargs.border_hl, align = "right" },
	})

	return ret
end

---@param text string
---@param hl boolean
---@param case string
---@param ret? ({[1]: string, [2]: boolean})[]
---@param idx? integer
---@return string
local function hl_chars(ret, case, idx, text, hl)
	if text == nil then
		text = ""
	end

	if ret == nil then
		ret = {}
	end

	if idx == nil then
		idx = #ret + 1
	elseif idx > #ret then
		idx = #ret + 1
	elseif idx < 1 then
		idx = 1
	end

	local case_fn = TERM.case[case]
	assert(case_fn ~= nil, "Invalid string case: " .. case)
	text = case_fn(text)

	for i, v in ipairs(vim.fn.str2list(text)) do
		table.insert(ret, idx + i - 1, { vim.fn.nr2char(v), hl })
	end

	return text
end

---@param config Rabbit.Cls.Box
---@param ... string Part to find the joining character for. Will return the first match.
---@return string "The joining character"
---@return integer "Number of matches"
---@return string "The joined text"
function BOX.join_for(config, custom, ...)
	local vararg = { ... }
	---@param align Rabbit.Cls.Box.Align
	---@return string | nil, integer, string
	local function iter_align(align)
		if align == nil then
			return nil, 0, ""
		end

		local p = align.parts
		if type(p) == "string" then
			p = { p }
		end

		local count = 0
		local text = {}
		local ret = nil
		for _, part in ipairs(vararg) do
			for _, v in ipairs(p) do
				if v == part then
					ret = ret or align.join or " "
					count = count + 1
					local s = (config.parts or {})[v] or custom[v] or tostring(v)
					if type(s) == "string" then
						table.insert(text, s)
					elseif type(s) == "function" then
						local t, _ = s()
						table.insert(text, t)
					elseif type(s) == "table" then
						local t, _ = unpack(s)
						table.insert(text, t)
					end
				end
			end
		end
		return ret, count, table.concat(text, ret or "")
	end

	for _, p in pairs(config) do
		if type(p) == "table" then
			for _, a in ipairs({ "left", "right", "center" }) do
				local s, count, text = iter_align(p[a])
				if s ~= nil then
					return s, count, text
				end
			end
		end
	end
	return " ", 0, "<no match found>"
end

-- Makes sides for a border
---@param w integer Window width
---@param h integer Window height
---@param config Rabbit.Cls.Box
---@param parts { [string]: Rabbit.Cls.Box.Part } Custom parts
---@return Rabbit.Term.Border.Applied
function BOX.make(w, h, config, parts)
	local sides = { ---@type Rabbit.Term.Border.Applied
		t = { txt = {}, hl = SET.new() },
		b = { txt = {}, hl = SET.new() },
		r = { txt = {}, hl = SET.new() },
		l = { txt = {}, hl = SET.new() },
		top_left = config.top_left,
		top_right = config.top_right,
		bot_left = config.bot_left,
		bot_right = config.bot_right,
		to_hl = to_hl,
	}

	---@param size integer
	---@param section Rabbit.Cls.Box.Align
	---@return {[1]: string, [2]: boolean}[]
	local function build_align(size, section)
		local str_parts = {}
		local cb_parts = {}
		local ps = section.parts
		if type(ps) == "string" then
			ps = { ps }
		end

		local case = section.case or "unchanged"

		for i, v in ipairs(ps) do
			local p = (config.parts or {})[v] or parts[v] or tostring(v)
			table.insert(cb_parts, hl_chars(str_parts, case, nil, BOX.resolve(p)))

			if i < #ps then
				hl_chars(str_parts, case, nil, section.join or " ", false)
				table.insert(cb_parts, section.join or " ")
			end
		end

		if type(section.build) == "function" then
			section.build(section, size, table.concat(cb_parts, ""))
		end

		hl_chars(str_parts, case, 1, section.prefix or "", false)
		hl_chars(str_parts, case, nil, section.suffix or "", false)

		return str_parts
	end

	---@param target { txt: string[], hl: Rabbit.Table.Set<integer> }
	---@param align "left" | "right" | "center" Alignment
	---@param section Rabbit.Cls.Box.Align
	local function do_align(target, align, section)
		if section == nil then
			return
		end
		local size = #target.txt
		local str_parts = build_align(size, section)

		local start, end_ = 1, math.min(#str_parts, size)

		if align == "center" then
			start = math.max(1, math.ceil((size - end_ + 1) / 2))
			end_ = math.min(size, start + size - 1)
		elseif align == "right" then
			start, end_ = size - end_ + 1, size
		end

		local txt = target.txt
		local hl = target.hl
		for i = start, end_ do
			local j = i - start + 1
			txt[i] = str_parts[j][1]
			local strwidth = #table.concat(txt, "", 1, i)
			hl:tog(strwidth, str_parts[j][2])
		end
	end

	---@param target { txt: string[], hl: Rabbit.Table.Set<integer> }
	---@param size integer
	---@param side string | Rabbit.Cls.Box.Side
	local function do_part(target, size, side)
		if type(side) == "string" then
			for i = 1, size do
				target.txt[i] = side
			end
			return
		end

		for i = 1, size do
			target.txt[i] = side.base
		end

		do_align(target, "left", side.left)
		do_align(target, "center", side.center)
		do_align(target, "right", side.right)
	end

	do_part(sides.t, w - 2, config.top_side)
	do_part(sides.b, w - 2, config.bot_side)
	do_part(sides.l, h - 2, config.left_side)
	do_part(sides.r, h - 2, config.right_side)

	return sides
end

---@param part Rabbit.Cls.Box.Part
---@return string text
---@return boolean highlight
function BOX.resolve(part)
	local highlight = true
	while type(part) == "function" do
		part, highlight = part()
	end
	if type(part) == "table" then
		part, highlight = unpack(part)
	end

	return part, highlight
end

return BOX
