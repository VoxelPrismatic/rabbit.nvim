local UI = require("rabbit.term.listing")
local TS = require("rabbit.util.treesitter")
local LIST = require("rabbit.plugins.forage.list")
local MEM = require("rabbit.util.mem")
local GLOBAL_CONFIG = require("rabbit.config")
local HL = require("rabbit.term.highlight")
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

-- Processes proc output
---@param proc vim.SystemCompleted
---@return table<string, Rabbit*Forage.Match.Ripgrep[]>
function RG.process_rg(proc)
	local ret = {}

	local last_line = ""
	for line in proc.stdout:gmatch("[^\r\n]+") do
		local ok, data = pcall(vim.json.decode, last_line .. line)
		if not ok then
			last_line = last_line .. line
			goto continue
		end

		last_line = ""

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

function RG.children()
	return { RG.search }
end

-- Runs rg asynchronously
---@param entry Rabbit.Entry.Search
local function async_rg(entry)
	if entry.fields[1].content == "" then
		return
	end
	vim.system(
		{ "rg", "--json", entry.fields[1].content, "./", "-m", "50" },
		{ text = true },
		vim.schedule_wrap(function(proc)
			UI._fg.buf.o.modifiable = true
			UI._fg.lines:set({}, {
				end_ = -1,
				start = 2,
				many = true,
			})
			UI._fg.buf.o.modifiable = false
			local i = 1
			local rg = RG.process_rg(proc)
			for file, matches in pairs(rg) do
				i = i + 1
				local parser = TS.parser_from_filename[file]
				local e = LIST.files[file]
				local relpath = MEM.rel_path(e.path)
				e.synopsis = {
					{ text = relpath.dir, hl = { "rabbit.files.path" } },
					{ text = relpath.name, hl = { "rabbit.files.file" } },
				}
				for _, match in ipairs(matches) do
					for _, m in ipairs(match.parts) do
						if e.jump then
							table.insert(e.jump.others, {
								line = match.line,
								col = m.rel.start,
								end_ = m.rel.end_,
							})
						else
							e.jump = {
								line = match.line,
								col = m.rel.start,
								end_ = m.rel.end_,
								others = {},
							}
						end
					end
					if match.text:gsub("%s+$", "") == "" then
						i = i - 1
					elseif parser ~= nil then
						parser:parse(match.text:gsub("%s+$", ""), function(lines)
							local ee = vim.tbl_extend("force", {}, e) -- shallow copy
							lines = HL.split(lines)
							for _, m in ipairs(match.parts) do
								for c = m.rel.start + 1, m.rel.end_ do
									if lines[c] ~= nil then
										local tbl = lines[c].hl
										if type(tbl) ~= "table" then
											tbl = { tbl }
											lines[c].hl = tbl
										end
										table.insert(tbl, "CurSearch")
									end
								end
							end

							for _ = 1, match.parts[1].rel.start - UI._fg.win.config.width / 4 do
								table.remove(lines, 1)
							end

							while #lines > 0 and lines[1].text:match("^%s+") do
								table.remove(lines, 1)
							end

							if #lines == 0 then
								i = i - 1
							else
								ee.label = lines

								UI.place_entry({
									entry = ee,
									idx = i - 2,
									line = i,
									pad = 0,
								})
							end
						end)
					end
				end
			end
		end)
	)
end

RG.timer = vim.uv.new_timer()

---@param entry Rabbit.Entry.Search
---@param new_name string
---@return string
local function process_rename(entry, new_name)
	entry.fields[entry.open].content = new_name
	if RG.timer == nil then
		local err
		RG.timer, _, err = vim.uv.new_timer()
		assert(RG.timer ~= nil, "failed to create timer: " .. err)
	end

	RG.timer:start(0, 0, function()
		async_rg(entry)
	end)
	return new_name
end

---@param entry Rabbit.Entry.Search
local function rename(entry)
	return {
		class = "message",
		type = "rename",
		apply = process_rename,
		check = process_rename,
		color = false,
		name = entry.fields[entry.open].content,
	}
end

---@type Rabbit.Entry.Search
RG.search = {
	class = "entry",
	type = "search",
	label = {
		text = "Grep",
		hl = { "rabbit.types.collection", "rabbit.paint.rose" },
	},
	fields = {
		{
			content = "type shit here",
			icon = "",
			name = "query",
		},
		{
			content = "",
			icon = "",
			name = "filter",
		},
		{
			content = "",
			icon = "",
			name = "flags",
		},
	},
	open = 1,
	actions = {
		select = true,
		rename = rename,
	},
	action_label = {
		rename = "edit",
	},
}

---@type Rabbit.Entry.Collection
RG.root = {
	class = "entry",
	type = "collection",
	label = {
		text = "Ripgrep",
		hl = { "rabbit.types.collection", "rabbit.paint.tree" },
	},
	actions = {
		select = true,
		children = RG.children,
	},
}

return RG
