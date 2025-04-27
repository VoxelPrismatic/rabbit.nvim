local UI = require("rabbit.term.listing")
local TS = require("rabbit.util.treesitter")
local LIST = require("rabbit.plugins.forage.list")
local MEM = require("rabbit.util.mem")
local HL = require("rabbit.term.highlight")
local GLOBAL_CONFIG = require("rabbit.config")
local RG = {}

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
	vim.defer_fn(function()
		RG.process_rename(RG.search, RG.search.fields[RG.search.open].content)
	end, GLOBAL_CONFIG.system.defer)
	return { RG.search }
end

-- Processes ripgrep output
---@param proc vim.SystemCompleted
function RG.ripgrep(proc)
	local jump_list = {} ---@type table<string, Rabbit.Entry.File.Jump[]>
	local rel_paths = {} ---@type table<string, Rabbit.Term.HlLine[]>
	UI._entries = { RG.search }
	vim.schedule(function()
		UI._fg.buf.o.modifiable = true
		UI._fg.lines:set({}, {
			end_ = -1,
			start = 2,
			many = true,
		})
		UI._fg.buf.o.modifiable = false
	end)

	local entry_no = 1
	local line_no = 0
	for line in proc.stdout:gmatch("[^\r\n]+") do
		if line:gsub("%s+", "") == "" then
			goto continue
		end

		if line_no > GLOBAL_CONFIG.system.max_results then
			return
		end

		line_no = line_no + 1

		local data = vim.json.decode(line) --[[@as Ripgrep.Match]]

		if data.type ~= "match" then
			goto continue
		end

		local match = data.data --[[@as Ripgrep.Match.Data]]

		local jumps = jump_list[match.path.text]
		if jumps == nil then
			jumps = {}
			jump_list[match.path.text] = jumps
		end

		for _, submatch in ipairs(match.submatches) do
			table.insert(jumps, {
				line = match.line_number,
				col = submatch.start,
				end_ = submatch["end"],
			})
		end

		vim.schedule(function()
			local file = LIST.files[match.path.text]
			file.jump = {
				line = match.line_number,
				col = match.submatches[1].start,
				end_ = match.submatches[1]["end"],
				others = jumps,
			}

			---@param lines Rabbit.Term.HlLine[]
			local function write_entry(lines)
				file.synopsis = rel_paths[match.path.text]
				if file.synopsis == nil then
					local relpath = MEM.rel_path(match.path.text)
					file.synopsis = {
						{
							text = relpath.dir,
							hl = { "rabbit.files.path" },
						},
						{
							text = relpath.name,
							hl = { "rabbit.files.file" },
						},
					}
					rel_paths[match.path.text] = file.synopsis
				end
				file.label = RG.trim_ts(lines, match)
				if #file.label > 0 then
					vim.schedule(function()
						UI.place_entry({
							entry = file,
							idx = entry_no - 1,
							line = entry_no + 1,
							pad = 0,
						})
						entry_no = entry_no + 1
					end)
				end
			end

			local parser = TS.parser_from_filename[match.path.text]
			if parser ~= nil then
				parser:parse(match.lines.text:gsub("%s+$", ""), write_entry)
			else
				write_entry({ text = match.lines.text:gsub("%s+$", ""), hl = {} })
			end
		end)

		::continue::
	end
end

---@param line Rabbit.Term.HlLine[]
---@param match Ripgrep.Match.Data
---@return Rabbit.Term.HlLine[]
function RG.trim_ts(line, match)
	local chars = HL.split(line)
	for _, m in ipairs(match.submatches) do
		for c = m.start + 1, m["end"] do
			if chars[c] ~= nil then
				local tbl = chars[c].hl
				if type(tbl) ~= "table" then
					tbl = { tbl }
					chars[c].hl = tbl
				end
				table.insert(tbl, "CurSearch")
			end
		end
	end

	for _ = 1, match.submatches[1].start - UI._fg.win.config.width / 3 * 2 do
		table.remove(chars, 1)
	end

	while #chars > 0 and chars[1].text:match("^%s+") do
		table.remove(chars, 1)
	end

	return chars
end

-- Runs rg asynchronously
---@param entry Rabbit.Entry.Search
local function async_rg(entry)
	if entry.fields[1].content == "" then
		return
	end
	vim.system({ "rg", "--json", entry.fields[1].content, "./", "-m", "50" }, { text = true }, RG.ripgrep)
end

RG.timer = vim.uv.new_timer()

---@param entry Rabbit.Entry.Search
---@param new_name string
---@return string
function RG.process_rename(entry, new_name)
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
		apply = RG.process_rename,
		check = RG.process_rename,
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
