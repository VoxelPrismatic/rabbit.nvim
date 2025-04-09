local UI = require("rabbit.term.listing")
local HL = require("rabbit.term.highlight")
local TERM = require("rabbit.util.term")
local STACK = require("rabbit.term.stack")

local rename_ws ---@type Rabbit.Stack.Workspace

local priority_legend = {
	{
		{ text = " " },
		{
			text = "apply",
			hl = { "rabbit.legend.action", "rabbit.types.plugin" },
			align = "left",
		},
		{
			text = ":",
			hl = { "rabbit.legend.separator" },
			align = "left",
		},
		{
			text = "<CR>",
			hl = { "rabbit.legend.key" },
			align = "left",
		},
	},
	{
		{ text = " " },
		{
			text = "cancel",
			hl = { "rabbit.legend.action", "rabbit.types.plugin" },
			align = "left",
		},
		{
			text = ":",
			hl = { "rabbit.legend.separator" },
			align = "left",
		},
		{
			text = "<Esc>",
			hl = { "rabbit.legend.key" },
			align = "left",
		},
	},
}

---@param data Rabbit.Message.Rename
return function(data)
	local linenr, curpos = unpack(UI._fg.cursor:get())
	local entry = UI._entries[linenr] ---@type Rabbit.Entry
	if not entry.actions.rename then
		vim.print("WARNING: Attempt to rename an entry that cannot be renamed.")
		return
	end

	local line = UI._fg.lines:nr(linenr)
	local _, startchar = line:find("\u{a0}")
	local startcol = vim.fn.strdisplaywidth(line:sub(1, startchar))

	local append = false
	curpos = math.max(0, curpos - startcol - 1)
	if curpos >= #data.name then
		append = true
		curpos = #data.name
	end

	local old_ws = rename_ws
	rename_ws = STACK.ws.scratch({
		focus = true,
		config = {
			relative = "win",
			win = UI._fg.win.id,
			row = linenr - 1,
			col = startcol,
			height = 1,
			width = UI._fg.win.config.width - startcol - 1,
			style = "minimal",
			zindex = 60,
		},
		---@diagnostic disable-next-line: missing-fields
		wo = {
			cursorline = true,
		},
		parent = UI._fg,
		lines = { "", data.name, "" },
		cursor = { 2, curpos },
		many = true,
		ns = "rabbit:rename",
	})

	if old_ws then
		old_ws:close()
	end

	local ignore_leave = false
	local rename_success = false

	local function text_changed()
		local lines = rename_ws.lines:get()
		local new_name = table.concat(lines, "")

		if #lines < 3 then
			local col = vim.fn.col(".")
			rename_ws.lines:set({ "", new_name, "" })
			rename_ws.cursor:set(2, col - 1)
		end

		local valid_name = data.apply(entry, new_name)
		rename_ws.extmarks:clear()

		if valid_name == new_name then
			return
		end

		if #new_name ~= 0 then
			rename_ws.extmarks:set({
				line = 1,
				col = 0,
				opts = {
					hl_group = "rabbit.paint.love",
					end_line = 1,
					end_col = math.min(#valid_name, #new_name),
				},
			})
		end

		local _, _, copy = valid_name:find("%++([0-9]+)$")

		if #valid_name < #new_name then
			rename_ws.extmarks:set({
				line = 1,
				col = #new_name,
				opts = {
					virt_text = { { valid_name, "rabbit.types.index" } },
					virt_text_pos = "right_align",
				},
			})
		elseif copy ~= nil then
			local _, _, exist = new_name:find("%++([0-9]+)$")
			local c = #new_name - #copy + (exist == nil and 1 or 0)

			rename_ws.extmarks:set({
				line = 1,
				col = c,
				opts = {
					virt_text = { { copy, "rabbit.types.index" } },
					virt_text_pos = "overlay",
					priority = 1000,
				},
			})
		else
			rename_ws.extmarks:set({
				line = 1,
				col = #new_name,
				opts = {
					virt_text = { { valid_name:sub(#new_name + 1), "rabbit.types.index" } },
					virt_text_pos = "inline",
				},
			})
		end
	end

	local function cursor_moved()
		local idx = entry._env.idx or 0
		local dx = vim.fn.line(".") - 2

		if dx == 0 or vim.fn.line("$") < 3 then
			curpos = vim.fn.col(".")
			return
		elseif vim.fn.line("$") > 3 then
			rename_success = true
			TERM.feed("<Esc>")
			return
		end

		local continue_key, opposite_key = unpack(dx == -1 and { "<Up>", "<Down>" } or { "<Down>", "<Up>" })

		local new_entry = entry._env.siblings[idx + dx]
		if new_entry == nil then
			TERM.feed(opposite_key)
			return
		end

		rename_success = true
		local new_rename = UI.find_action("rename", entry._env.siblings[idx + dx])
		if new_rename ~= nil then
			ignore_leave = true
			entry.default = false
			new_entry.default = true
			local old_cur = UI._fg.cursor:get()
			UI.place_entry(entry, idx, entry._env.real, #tostring(#UI._entries))
			UI._fg.cursor:set(old_cur[1] + dx, curpos + startcol)
			UI.apply_actions()
			rename_ws.autocmd:clear()
			vim.defer_fn(function()
				UI.handle_callback(new_rename(new_entry))
			end, 5)
		else
			vim.cmd("stopinsert")
			UI._bg:focus()
			vim.defer_fn(function()
				rename_ws:close()
				UI._fg:focus()
				TERM.feed(continue_key)
			end, 5)
		end
	end

	rename_ws.autocmd:add({
		TextChangedI = text_changed,
		CursorMovedI = cursor_moved,
		InsertLeave = function()
			UI._priority_legend = {}
			if not ignore_leave then
				rename_ws:close()
				UI.list(UI._parent)
				UI._fg.cursor:set(linenr, startcol + curpos, true)
			end

			if not rename_success then
				data.apply(entry, data.name)
				UI.place_entry(entry, entry._env.idx, entry._env.real, #tostring(#UI._entries))
			end
		end,
	})

	if vim.fn.mode() == "i" then
		curpos = curpos + 1
	elseif append then
		TERM.feed("a")
	else
		TERM.feed("i")
	end

	UI._priority_legend = HL.split(priority_legend)
	text_changed()
end
