local MEM = require("rabbit.util.mem")
local UI = require("rabbit.term.listing")
local CTX = require("rabbit.term.ctx")
local BOX = require("rabbit.term.border")

local MSG = {}

---@param data Rabbit.Message.Preview
function MSG.preview(data)
	local win_config = CTX.win_config(data.winid)
	local box = BOX.normalize("┏┓╚┛━┃║")

	if UI._hov[data.winid] ~= nil then
		UI._bufid = UI._hov[data.winid]
		vim.api.nvim_win_set_buf(data.winid, UI._bufid)
	else
		UI._hov[data.winid] = vim.api.nvim_win_get_buf(data.winid)
	end

	for _, v in pairs(UI._pre) do
		v:close()
	end

	local relpath
	if vim.api.nvim_buf_is_valid(data.bufid or -1) then
		relpath = MEM.rel_path(vim.api.nvim_buf_get_name(data.bufid))
		-- vim.api.nvim_win_set_option(
		UI._bufid = data.bufid
		vim.api.nvim_win_set_buf(data.winid, data.bufid)
	else
		relpath = MEM.rel_path(data.file)
	end

	local sides = BOX.make_sides(win_config.width, win_config.height, box, {
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

	local this_config = {
		row = win_config.row,
		col = win_config.col,
		width = 1,
		height = win_config.height,
		relative = "editor",
		zindex = 10,
		anchor = "NW",
		style = "minimal",
	}

	UI._bufid = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(UI._bufid, false, this_config)
	UI._pre.l = CTX.append(UI._bufid, win, UI._fg)

	this_config.col = win_config.width + win_config.col - 1
	UI._bufid = vim.api.nvim_create_buf(false, true)
	win = vim.api.nvim_open_win(UI._bufid, false, this_config)
	UI._pre.r = CTX.append(UI._bufid, win, UI._pre.l)

	this_config.height = 1
	this_config.col = win_config.col + 1
	this_config.width = win_config.width - 2
	UI._bufid = vim.api.nvim_create_buf(false, true)
	win = vim.api.nvim_open_win(UI._bufid, false, this_config)
	UI._pre.t = CTX.append(UI._bufid, win, UI._pre.r)

	this_config.row = win_config.height + win_config.row - 1
	UI._bufid = vim.api.nvim_create_buf(false, true)
	win = vim.api.nvim_open_win(UI._bufid, false, this_config)
	UI._pre.b = CTX.append(UI._bufid, win, UI._pre.t)
	UI._pre.l:add_child(UI._pre.b)

	table.insert(sides.r.txt, 1, box.ne)
	table.insert(sides.l.txt, 1, box.nw)
	table.insert(sides.r.txt, box.se)
	table.insert(sides.l.txt, box.sw)

	vim.api.nvim_buf_set_lines(UI._pre.l.buf, 0, -1, false, sides.l.txt)
	vim.api.nvim_buf_set_lines(UI._pre.r.buf, 0, -1, false, sides.r.txt)
	for i = 1, win_config.height do
		vim.api.nvim_buf_add_highlight(UI._pre.l.buf, -1, "rabbit.plugin.inv", i - 1, 0, -1)
		vim.api.nvim_buf_add_highlight(UI._pre.r.buf, -1, "rabbit.plugin.inv", i - 1, 0, -1)
	end

	vim.api.nvim_buf_set_lines(UI._pre.t.buf, 0, -1, false, { table.concat(sides.t.txt) })
	vim.api.nvim_buf_set_lines(UI._pre.b.buf, 0, -1, false, { table.concat(sides.b.txt) })
	vim.api.nvim_buf_add_highlight(UI._pre.t.buf, -1, "rabbit.plugin.inv", 0, 0, -1)
	vim.api.nvim_buf_add_highlight(UI._pre.b.buf, -1, "rabbit.plugin.inv", 0, 0, -1)

	for _, i in ipairs(sides.b.hl) do
		vim.api.nvim_buf_add_highlight(UI._pre.b.buf, -1, "rabbit.types.title", 0, i - 1, i)
	end
end

---@param data Rabbit.Message
function MSG.Handle(data)
	if data.type == "preview" then
		data = data --[[@as Rabbit.Message.Preview]]
		return MSG.preview(data)
	end

	error("Message type not implemented: " .. vim.inspect(data))
end

return MSG
