local UI = require("rabbit.term.listing")
local LIST = require("rabbit.plugins.forage.list")
local SET = require("rabbit.util.set")
local GLOBAL_CONFIG = require("rabbit.config")
local HL = require("rabbit.term.highlight")
local FZR = {}

local fzr_path = ""

---@type Rabbit.Message.Options
FZR.options = {
	type = "options",
	class = "message",
	options = {},
}

function FZR.children()
	vim.defer_fn(function()
		FZR.process_rename(FZR.search, FZR.search.fields[FZR.search.open].content)
	end, GLOBAL_CONFIG.system.defer)
	return { FZR.search }
end

---@class FuzzerOutput
---@field text string File path
---@field lines Rabbit.Term.HlLine[] Highlight lines

-- Processes fuzzer output
---@param proc vim.SystemCompleted
function FZR.fuzzer(proc)
	UI._entries = { FZR.search }
	vim.schedule(function()
		UI._fg.lines:set({}, {
			end_ = -1,
			start = 2,
			many = true,
			lock = true,
		})
	end)

	local entry_no = 1
	local line_no = 0
	for line in proc.stderr:gmatch("[^\r\n]+") do
		if line:gsub("%s+", "") == "" then
			goto continue
		end

		if line_no > GLOBAL_CONFIG.system.max_results then
			return
		end

		local ok, data = pcall(vim.json.decode, line) --[[@as FuzzerOutput[]=]]
		if not ok then
			vim.schedule(function()
				local lines = HL.wrap({ text = line }, UI._fg.win.config.width, " ")
				table.insert(lines, "")
				UI._fg.lines:set(lines, {
					start = 2,
					end_ = -1,
					many = true,
					lock = true,
				})
			end)
			return
		end

		for _, result in ipairs(data) do
			line_no = line_no + 1

			vim.schedule(function()
				if vim.fs.basename(result.text) == "" then
					return
				end
				result.lines = HL.split(result.lines)
				local entry = LIST.files[result.text]
				local dirname = vim.fs.dirname(result.text) .. "/"
				entry.label = result.lines

				for i = 1, #dirname do
					local part = result.lines[i]
					if part ~= nil and part.hl[1] == "rabbit.files.file" then
						part.hl[1] = "rabbit.files.path"
					end
				end
				if entry.closed then
					for i = #dirname + 1, #result.lines do
						local part = result.lines[i]
						if part ~= nil and part.hl[1] == "rabbit.files.file" then
							part.hl[1] = "rabbit.files.closed"
						end
					end
				end

				UI.place_entry({
					entry = entry,
					idx = entry_no - 1,
					line = entry_no + 1,
					pad = #tostring(line_no),
				})
				entry_no = entry_no + 1
			end)
		end

		::continue::
	end
end

-- Runs fuzzer asynchronously
---@param entry Rabbit.Entry.Search
local function async_fzr(entry)
	local command = { fzr_path, "@", entry.fields["command"].content }
	for token in entry.fields["query"].content:gmatch("%S+") do
		table.insert(command, token)
	end
	vim.system(command, {
		text = true,
		timeout = 2000,
	}, FZR.fuzzer)
end

FZR.timer = vim.uv.new_timer()

---@param entry Rabbit.Entry.Search
---@param new_name string
---@return string
function FZR.process_rename(entry, new_name)
	entry.fields[entry.open].content = new_name
	if FZR.timer == nil then
		local err
		FZR.timer, _, err = vim.uv.new_timer()
		assert(FZR.timer ~= nil, "failed to create timer: " .. err)
	end

	FZR.timer:start(0, 0, function()
		async_fzr(entry)
	end)
	return new_name
end

---@param entry Rabbit.Entry.Search
local function rename(entry)
	return {
		class = "message",
		type = "rename",
		check = FZR.process_rename,
		apply = function(e, new_name)
			vim.fn.setreg("/", new_name)
			return FZR.process_rename(e, new_name)
		end,
		color = false,
		name = entry.fields[entry.open].content,
	}
end

---@type Rabbit.Entry.Search
FZR.search = {
	class = "entry",
	type = "search",
	label = {
		text = "Grep",
		hl = { "rabbit.types.collection", "rabbit.paint.rose" },
	},
	fields = SET.lookup("name", {
		{
			content = "",
			icon = "",
			name = "query",
		},
		{
			content = "find . -type f -not -path '*/.*' -not -name '.*'",
			icon = "",
			name = "command",
		},
	}),
	open = 1,
	actions = {
		select = true,
		rename = rename,
		parent = true,
	},
	action_label = {
		rename = "edit",
	},
}

---@param entry Rabbit.Entry.Search
function FZR.select(entry)
	if fzr_path == "" then
		local paths = package.path
		for _, path in ipairs(vim.api.nvim_list_runtime_paths()) do
			paths = paths .. ";" .. path .. "/lua/?.lua" .. ";" .. path .. "/lua/?/init.lua"
		end

		local module_path = package.searchpath("rabbit.plugins.forage", paths)
		fzr_path = vim.fs.dirname(module_path) .. "/fzr"
	end

	if vim.fn.executable(fzr_path) == 1 then
		return entry
	end

	return {
		class = "message",
		type = "menu",
		color = "rabbit.popup.error",
		title = "Fuzzer not found",
		msg = {
			{
				text = "Fuzzer could not be located. Please file an issue on GitHub, "
					.. "as the binary should be shipped with Rabbit",
			},
		},
		options = {},
	}
end

---@type Rabbit.Entry.Collection
FZR.root = {
	class = "entry",
	type = "collection",
	label = {
		text = "Fuzzy Find",
		hl = { "rabbit.types.collection", "rabbit.paint.tree" },
	},
	actions = {
		select = FZR.select,
		children = FZR.children,
	},
}

return FZR
