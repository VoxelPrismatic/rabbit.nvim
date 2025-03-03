local set = require("rabbit.plugins.util")

---@class Rabbit.Plugin.Reopen.Options
---@field public path_key? string|function:string Scope your working directory

---@class Rabbit.Plugin.Reopen: Rabbit.Plugin
local M = { ---@type Rabbit.Plugin
	color = "#40c9a2",
	name = "reopen",
	func = {},
	switch = "o",
	listing = {},
	empty_msg = "There's no buffer to reopen! Get started by closing a buffer",
	skip_same = true,
	keys = {},
	evt = {},
	memory = "",
	flags = {},

	---@type Rabbit.Plugin.Reopen.Options
	opts = {
		path_key = nil,
	},

	---@param p Rabbit.Plugin
	init = function(p)
		p.listing.persist = set.clean(set.read(p.memory), p.flags.sys.path_key)
	end,
}

---@param evt NvimEvent
---@return string | nil Nil if event should be ignored
local function prepare(evt)
	local cwd = require("rabbit").path_key(M)
	M.listing.persist[cwd] = M.listing.persist[cwd] or {}

	if vim.uv.fs_stat(evt.file) == nil then
		return nil
	end

	return cwd
end

---@param evt NvimEvent
---@param winid integer
function M.evt.BufEnter(evt, winid)
	local cwd = prepare(evt)
	if cwd == nil then
		return
	end

	set.sub(M.listing[winid], evt.file)
	set.add(M.listing.persist[cwd], evt.file)
	set.save(M.memory, M.listing.persist)
end

---@param evt NvimEvent
---@param winid integer
function M.evt.BufDelete(evt, winid)
	local cwd = prepare(evt)
	if cwd == nil then
		return
	end

	set.sub(M.listing.persist[cwd], evt.match)
	set.add(M.listing[winid], evt.match)
	set.save(M.memory, M.listing.persist)
end

---@param winid integer
function M.evt.RabbitEnter(evt, winid)
	M.listing[0] = nil
	if #vim.tbl_keys(M.listing) ~= 2 or #M.listing[winid] > 0 then
		M.flags.win = winid
		return
	end

	M.flags.dir = evt.match

	M.listing[0] = {}
	for i, v in ipairs(M.listing.persist[evt.match]) do
		local stat = vim.uv.fs_stat(v)
		if stat == nil or (stat.type ~= "file" and stat.type ~= "link") then
			table.remove(M.listing.persist[evt.match], i)
			set.save(M.memory, M.listing.persist)
		else
			M.listing[0][#M.listing[0] + 1] = v
		end
	end

	table.insert(M.listing[0], 1, "rabbitmsg://Open all files")
end

---@param n integer
function M.func.select(n)
	if M.listing[0] == nil or n ~= 1 then
		return require("rabbit").func.select(n)
	end
	M.listing[0] = require("rabbit").ctx.listing

	table.remove(M.listing[0], 1)
	for _, v in ipairs(M.listing[0]) do
		vim.cmd("edit " .. v)
	end
end

---@param n integer
function M.func.file_del(n)
	if M.listing[0] ~= nil then
		if n == 1 then
			return
		else
			table.remove(M.listing[0], n)
			table.remove(M.listing.persist[M.flags.dir], n - 1)
			set.save(M.memory, M.listing.persist)
		end
	else
		table.remove(M.listing[M.flags.win], n)
	end

	require("rabbit").Redraw()
end

return M
