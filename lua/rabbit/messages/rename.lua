local UI = require("rabbit.term.listing")
local CTX = require("rabbit.term.ctx")

local rename_ws ---@type Rabbit.UI.Workspace

---@param data Rabbit.Message.Rename
return function(data)
	local linenr, curpos = unpack(vim.api.nvim_win_get_cursor(UI._fg.win))
	local entry = UI._entries[linenr] ---@type Rabbit.Entry
	if not entry.actions.rename then
		vim.print("WARNING: Attempt to rename an entry that cannot be renamed.")
		return
	end

	local line = vim.api.nvim_buf_get_lines(UI._fg.buf, linenr - 1, linenr, true)[1]
	local _, startchar = line:find("\u{a0}")
	local startcol = vim.fn.strdisplaywidth(line:sub(1, startchar))

	local append = false
	curpos = math.max(0, curpos - startcol - 1)
	if curpos >= #data.name then
		append = true
		curpos = #data.name
	end

	local old_ws = rename_ws
	rename_ws = CTX.scratch({
		focus = true,
		config = {
			relative = "win",
			win = UI._fg.win,
			row = linenr - 1,
			col = startcol,
			height = 1,
			width = UI._fg.conf.width - startcol - 1,
			style = "minimal",
			zindex = 60,
		},
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

	local function text_changed()
		local lines = vim.api.nvim_buf_get_lines(rename_ws.buf, 0, -1, false)
		local new_name = table.concat(lines, "")

		if #lines < 3 then
			local col = vim.fn.col(".")
			vim.api.nvim_buf_set_lines(rename_ws.buf, 0, -1, false, { "", new_name, "" })
			vim.api.nvim_win_set_cursor(rename_ws.win, { 2, col - 1 })
		end

		local valid_name = data.apply(entry, new_name)
		vim.api.nvim_buf_clear_namespace(rename_ws.buf, rename_ws.ns, 0, -1)
		if valid_name ~= new_name then
			vim.api.nvim_buf_set_extmark(rename_ws.buf, rename_ws.ns, 1, 0, {
				hl_group = "rabbit.paint.love",
				end_line = 1,
				end_col = #valid_name,
			})
			local _, _, copy = valid_name:find("%++([0-9]+)$")
			if #valid_name < #new_name then
				vim.api.nvim_buf_set_extmark(rename_ws.buf, rename_ws.ns, 1, #new_name, {
					virt_text = { { valid_name, "rabbit.types.index" } },
					virt_text_pos = "right_align",
				})
			elseif copy ~= nil then
				local _, _, exist = new_name:find("%++([0-9]+)$")
				local c = #new_name - #copy + (exist == nil and 1 or 0)

				vim.api.nvim_buf_set_extmark(rename_ws.buf, rename_ws.ns, 1, c, {
					virt_text = { { copy, "rabbit.types.index" } },
					virt_text_pos = "overlay",
					priority = 1000,
				})
			else
				vim.api.nvim_buf_set_extmark(rename_ws.buf, rename_ws.ns, 1, #new_name, {
					virt_text = { { valid_name:sub(#new_name + 1), "rabbit.types.index" } },
					virt_text_pos = "inline",
				})
			end
		end
	end

	local function cursor_moved()
		local idx = entry._env.idx or 0
		local dx = vim.fn.line(".") - 2

		if dx == 0 or vim.fn.line("$") < 3 then
			curpos = vim.fn.col(".")
			return
		elseif vim.fn.line("$") > 3 then
			vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, true, true), "n")
			return
		end

		local continue_key = dx == -1 and "<Up>" or "<Down>"
		local opposite_key = dx == -1 and "<Down>" or "<Up>"

		local new_entry = entry._env.siblings[idx + dx]
		if new_entry == nil then
			vim.fn.feedkeys(vim.api.nvim_replace_termcodes(opposite_key, true, true, true), "n")
			return
		end

		local new_rename = UI.find_action("rename", entry._env.siblings[idx + dx])
		if new_rename ~= nil then
			ignore_leave = true
			entry.default = false
			new_entry.default = true
			local old_cur = vim.api.nvim_win_get_cursor(UI._fg.win)
			vim.api.nvim_win_set_cursor(UI._fg.win, { old_cur[1] + dx, curpos + startcol })
			UI.place_entry(entry, idx, entry._env.real, #tostring(#UI._entries))
			UI.apply_actions()
			UI.handle_callback(new_rename(new_entry))
		else
			vim.cmd("stopinsert")
			vim.api.nvim_set_current_win(UI._bg.win)
			vim.defer_fn(function()
				rename_ws:close()
				vim.api.nvim_set_current_win(UI._fg.win)
				vim.fn.feedkeys(vim.api.nvim_replace_termcodes(continue_key, true, true, true), "n")
			end, 25)
		end
	end

	vim.api.nvim_create_autocmd("InsertLeave", {
		buffer = rename_ws.buf,
		callback = function()
			rename_ws:close()
			if not ignore_leave then
				UI.list(UI._parent)
				vim.api.nvim_win_set_cursor(UI._fg.win, { linenr, startcol + curpos })
				vim.api.nvim_set_current_win(UI._fg.win)
			end
		end,
	})

	vim.api.nvim_create_autocmd("TextChangedI", {
		buffer = rename_ws.buf,
		callback = text_changed,
	})

	vim.api.nvim_create_autocmd("CursorMovedI", {
		buffer = rename_ws.buf,
		callback = cursor_moved,
	})

	if vim.fn.mode() == "i" then
		curpos = curpos + 1
	elseif append then
		vim.fn.feedkeys("a", "n")
	else
		vim.fn.feedkeys("i", "n")
	end

	text_changed()
end
