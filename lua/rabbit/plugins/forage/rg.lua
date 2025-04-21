local RG = {}

---@class Rabbit*Forage.Kwargs.Ripgrep
---@field search_zip? boolean (-z) Search in zip files.
---@field encoding? string (-E) Specify the text encoding.
---@field engine?: --engine
---| "default" # Usually the fastest and should be good for most use cases.
---| "pcre2" # Generally useful when you want to use features such as look-around or backreferences.
---| "auto" # Dynamically choose between supported regex engines depending on the features used in a pattern on a best effort basis.
---@field fixed_strings? boolean (-F) Treat all patterns as literals instead of regular expressions.
---@field invert_match? boolean (-v) Invert match. That is, print non-matching lines.
---@field multiline? boolean (-U) Multiline search
---@field multiline_dotall? boolean The `.` pattern will also match newlines
---@field regexp?: Pattern matching
---| "line" # (-x) Match the whole line. (Surround patterns with ^ and $)
---| "word" # (-w) Match the whole word. (Surround patterns with \b)
---@field unicode? boolean Enable unicode support for all patterns given to ripgrep
---@field follow_symlinks? boolean Follow symlinks when searching
---@field search_hidden? boolean Search hidden files

---@param command string[] Command
local function run_rg(command)
	local proc = vim.system(command, { text = true }):wait()
	local ret = {}

	for line in proc.stdout:gmatch("[^\r?\n]+") do
		local data = vim.json.decode(line)

		if data.type ~= "match" then
			goto continue
		end

		data = data.data --[[@as Ripgrep.Match.Data]]

		local target = ret[data.path.text]
		if target == nil then
			target = {}
			ret[data.path.text] = target
		end

		---@type Rabbit*Forage.Match.Ripgrep
		local match = {
			text = data.lines.text,
			line = data.line_number,
			parts = {},
		}

		for _, submatch in ipairs(data.submatches) do
			table.insert(match.parts, {
				rel = {
					start = submatch.start,
					end_ = submatch["end"],
				},
				abs = {
					start = data.absolute_offset + submatch.start,
					end_ = data.absolute_offset + submatch["end"],
				},
				match = submatch.match.text,
			})
		end

		table.insert(target, match)

		::continue::
	end
	return ret
end

---@param text string Text to search
---@param kwargs? Rabbit*Forage.Kwargs.Ripgrep
---@param ... string Extra flags to pass to rg
function RG.find(text, kwargs, ...)
	local command = { "rg", text, "--json", ... }

	kwargs = kwargs or {}

	if kwargs.search_zip then
		table.insert(command, "-z")
	end

	if kwargs.encoding then
		table.insert(command, "--encoding=" .. kwargs.encoding)
	end

	if kwargs.engine then
		table.insert(command, "--engine=" .. kwargs.engine)
	end

	if kwargs.fixed_strings then
		table.insert(command, "-F")
	end

	if kwargs.invert_match then
		table.insert(command, "-v")
	end

	if kwargs.regexp == "line" then
		table.insert(command, "-x")
	elseif kwargs.regexp == "word" then
		table.insert(command, "-w")
	end

	if kwargs.multiline == true then
		table.insert(command, "--multiline")
	elseif kwargs.multiline == false then
		table.insert(command, "--no-multiline")
	end

	if kwargs.multiline_dotall == true then
		table.insert(command, "--multiline-dotall")
	elseif kwargs.multiline_dotall == false then
		table.insert(command, "--no-multiline-dotall")
	end

	return run_rg(command)
end

---@class Ripgrep.Match
---@field type "match"
---@field data Ripgrep.Match.Data

---@class Ripgrep.Match.Data
---@field path { text: string } File path of the match.
---@field lines { text: string } Matched line (many lines are returned as multiple Ripgrep.Match.Data objects).
---@field line_number integer Line number of the match.
---@field absolute_offset integer Byte offset of the match from the beginning of the file.
---@field submatches Ripgrep.Match.Submatch[] List of submatches

---@class Ripgrep.Match.Submatch
---@field match { text: string } Matched text
---@field start integer Column number of the beginning of the match
---@field end integer Column number of the end of the match

---@class Rabbit*Forage.Match.Ripgrep
---@field text string Line text.
---@field line integer Line number of the match.
---@field parts Rabbit*Forage.Match.Ripgrep.Submatch[] List of submatches

---@class Rabbit*Forage.Match.Ripgrep.Submatch
---@field rel { start: integer, end_: integer } Relative position of the submatch.
---@field abs { start: integer, end_: integer } Absolute position of the submatch.
---@field match string Matched text.

---@type Rabbit.Message.Options
RG.options = {
	type = "options",
	class = "message",
	options = {
		{
			type = "list",
			label = "Casing",
			style = {
				set = "",
				float = "",
				reset = "",
			},
			entries = {
				{
					label = "Smart",
					single = true,
					tri = false,
					flags = {
						set = "-S",
					},
				},
				{
					label = "Ignore",
					single = true,
					tri = false,
					flags = {
						set = "-i",
					},
				},
				{
					id = "strict",
					label = "Strict",
					single = true,
					tri = false,
					flags = {
						set = "-s",
					},
				},
			},
		},
		{
			type = "list",
			label = "Line endings",
			style = {
				set = "",
				float = "",
				reset = "",
			},
			entries = {
				{
					label = "Unix",
					synopsis = "Standard line terminator of \n",
					single = true,
					tri = false,
					flags = {
						set = "--no-crlf",
					},
				},
				{
					label = "Null",
					synopsis = "Treat NUL as a line terminator; useful when searching in binary files",
					single = true,
					tri = false,
					flags = {
						set = "--null-data",
					},
				},
				{
					label = "Windows",
					synopsis = "Use \r\n as line terminators instead of just \n",
					single = true,
					tri = false,
					flags = {
						set = "--crlf",
					},
				},
			},
		},
		{
			type = "list",
			label = "Toggles",
			style = {
				set = "",
				reset = "",
				float = "",
			},
			entries = {
				{
					label = "Follow Symlinks",
					single = false,
					tri = true,
					flags = {
						set = "--follow",
						reset = "--no-follow",
					},
				},
				{
					label = "Include Hidden",
					single = false,
					tri = true,
					flags = {
						set = "--hidden",
						reset = "--no-hidden",
					},
				},
				{
					label = "Unicode in RegEx",
					single = false,
					tri = true,
					flags = {
						set = "--unicode",
						reset = "--no-unicode",
					},
				},
			},
		},
	},
}

local function rg_children() end

---@type Rabbit.Entry.Search
RG.root = {
	class = "entry",
	type = "search",
	label = {
		text = "Grep",
		hl = { "rabbit.types.collection", "rabbit.paint.rose" },
	},
	fields = {
		{
			default = "",
			icon = "",
			name = "query",
		},
		{
			default = "",
			icon = "",
			name = "filter",
		},
		{
			default = "",
			icon = "",
			name = "flags",
		},
	},
	actions = {
		children = rg_children,
	},
}
return RG
