local MEM = require("rabbit.util.mem")
local UI = require("rabbit.term.listing")
local CTX = require("rabbit.term.ctx")
local BOX = require("rabbit.term.border")
local CONFIG = require("rabbit.config")

local MSG = {}

local rename_ws ---@type Rabbit.UI.Workspace

---@param data Rabbit.Message.Preview
function MSG.preview(data)
	for _, v in pairs(UI._pre) do
		v:close()
	end

	if not vim.api.nvim_buf_is_valid(data.bufid) then
		return
	end

	local win_config = CTX.win_config(data.winid)
	if win_config == nil then
		return
	end
	local box = BOX.normalize("┏┓╚┛━┃║")

	local relpath
	local fallback_bufid = UI._hov[data.winid]
	if vim.api.nvim_buf_is_valid(data.bufid or -1) then
		relpath = MEM.rel_path(vim.api.nvim_buf_get_name(data.bufid))
		vim.api.nvim_win_set_buf(data.winid, data.bufid)
	elseif vim.api.nvim_buf_is_valid(fallback_bufid) then
		return vim.api.nvim_win_set_buf(data.winid, fallback_bufid)
	end

	local sides ---@type Rabbit.Term.Border.Applied
	if CONFIG.window.spawn.side == "sw" then
		box = BOX.normalize("┏┓┗╝━┃║")
		sides = BOX.make_sides(win_config.width, win_config.height, box, {
			align = "se",
			make = function(sz, _)
				local name = relpath.name
				local suf = ("═"):rep(math.floor(sz / 2) - #name - 2 - #relpath.dir) .. " "
				return suf .. relpath.dir, name, " ═"
			end,
		}, {
			align = "es",
			make = function(sz, _)
				return "", "", ("║"):rep(math.floor(sz / 4))
			end,
		})
	else
		sides = BOX.make_sides(win_config.width, win_config.height, box, {
			align = "sw",
			make = function(sz, _)
				local name = relpath.name
				local suf = " " .. ("═"):rep(math.floor(sz / 2) - #name - 2 - #relpath.dir)
				return "═ " .. relpath.dir, name, suf
			end,
		}, {
			align = "ws",
			make = function(sz, _)
				return "", "", ("║"):rep(math.floor(sz / 4))
			end,
		})
	end

	table.insert(sides.r.txt, 1, box.ne)
	table.insert(sides.l.txt, 1, box.nw)
	table.insert(sides.r.txt, box.se)
	table.insert(sides.l.txt, box.sw)

	local left_config = {
		row = win_config.row,
		col = win_config.col,
		width = 1,
		height = win_config.height,
		relative = "editor",
		zindex = 10,
		anchor = "NW",
		style = "minimal",
	}

	local right_config = vim.deepcopy(left_config)
	right_config.col = win_config.col + win_config.width - 1

	local top_config = vim.deepcopy(right_config)
	top_config.height = 1
	top_config.col = win_config.col + 1
	top_config.width = win_config.width - 2

	local bot_config = vim.deepcopy(top_config)
	bot_config.row = win_config.row + win_config.height - 1

	UI._pre.l = CTX.scratch({
		focus = false,
		config = left_config,
		parent = UI._bg,
		lines = sides.l.txt,
	})

	UI._pre.r = CTX.scratch({
		focus = false,
		config = right_config,
		parent = UI._pre.l,
		lines = sides.r.txt,
	})

	UI._pre.t = CTX.scratch({
		focus = false,
		config = top_config,
		parent = UI._pre.r,
		lines = { table.concat(sides.t.txt, "") },
	})

	UI._pre.b = CTX.scratch({
		focus = false,
		config = bot_config,
		parent = UI._pre.t,
		lines = { table.concat(sides.b.txt, "") },
	})

	UI._pre.l:add_child(UI._pre.b) -- Circle so they all close at the same time

	for i = 1, win_config.height do
		vim.api.nvim_buf_add_highlight(UI._pre.l.buf, -1, "rabbit.plugin.inv", i - 1, 0, -1)
		vim.api.nvim_buf_add_highlight(UI._pre.r.buf, -1, "rabbit.plugin.inv", i - 1, 0, -1)
	end

	vim.api.nvim_buf_add_highlight(UI._pre.t.buf, -1, "rabbit.plugin.inv", 0, 0, -1)
	vim.api.nvim_buf_add_highlight(UI._pre.b.buf, -1, "rabbit.plugin.inv", 0, 0, -1)

	for _, i in ipairs(sides.b.hl) do
		vim.api.nvim_buf_add_highlight(UI._pre.b.buf, -1, "rabbit.types.title", 0, i - 1, i)
	end

	UI._bufid = -1
end

---@param data Rabbit.Message.Rename
function MSG.rename(data)
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
			vim.api.nvim_buf_add_highlight(rename_ws.buf, rename_ws.ns, "rabbit.paint.love", 1, 0, -1)
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

---@param data Rabbit.Message
function MSG.Handle(data)
	if MSG[data.type] then
		return MSG[data.type](data)
	end

	error("Message type not implemented: " .. vim.inspect(data))
end

return MSG
