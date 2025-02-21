local set = require("rabbit.plugins.util")


---@class Rabbit.Plugin.Harpoon.Options
---@field public ignore_opened? boolean Do not display currently open buffers
---@field public path_key? string|function:string Scope your working directory


---@class Rabbit.Plugin.Harpoon: Rabbit.Plugin
local M = { ---@type Rabbit.Plugin
	color = "#ff733f",
	name = "harpoon",
	func = {},
	switch = "p",
	listing = {},
	empty_msg = "There's nowhere to jump to! Get started by adding a file",
	skip_same = false,
	keys = {},
	evt = {},
	flags = {},
	memory = "",

	_dir = "",

	---@type Rabbit.Plugin.Harpoon.Options
	opts = {
		ignore_opened = false,
		path_key = nil,
	},

	---@param p Rabbit.Plugin.Harpoon
	init = function(p)
		p.listing[0] = {}
		p.listing.paths = {}
		p.listing.persist = set.clean(set.read(p.memory), p.flags.sys.path_key)
		p.listing.opened = {}
		p.listing.collections = {}
		p.listing.recursive = nil
	end,

	ctx = {},
}

function M._validate_group_name(name)
	if #M.listing.paths[M._dir] > 0 and name ~= M.listing.recursive[1] then
		local recur = M.listing.persist[M._dir]
		for i, v in ipairs(M.listing.paths[M._dir]) do
			if i < #M.listing.paths[M._dir] then
				recur = recur[v]
			end
		end

		for _, v in ipairs(recur) do
			if type(v) == "table" and name == v[1] then
				return "That name already exists!", false
			end
		end
	elseif name == "" then
		return "Name can't be empty!", false
	elseif string.find(name, "#up!") == 1 then
		return "Can't go up from here!", false
	elseif string.find(name, "rabbitmsg://") == 1 then
		return "That's a reserved name!", false
	elseif set.index(M.listing[0], "rabbitmsg://" .. name) ~= nil then
		return "That name already exists!", false
	end

	return "", true
end

---@param n integer
function M.func.group(n)
	require("rabbit.input").prompt("Collection name", function(name)
		n = math.max(1, math.min(#M.listing[0] + 1, n))
		if #M.listing.paths[M._dir] > 0 then
			set.add(M.listing[0], "rabbitmsg://#up!\n" .. M._path())
			n = math.max(2, n)
		end

		local msg, valid = M._validate_group_name(name)
		if not valid then
			vim.print(msg)
			return
		end

		table.insert(M.listing[0], n, "rabbitmsg://" .. name)
		table.insert(M.listing.recursive, n, { name })

		set.save(M.memory, M.listing.persist)
		require("rabbit").Redraw()
	end, function(name)
		local _, valid = M._validate_group_name(name)
		return valid
	end)
end

---@param old_name string
function M._rename(old_name)
	require("rabbit.input").prompt("Rename collection", function(name)
		local msg, valid = M._validate_group_name(name)
		if not valid then
			vim.print(msg)
			return
		end

		M.listing.recursive[1] = name
		M.listing[0][1] = "rabbitmsg://#up!\n" .. M._path()
		set.save(M.memory, M.listing.persist)
		require("rabbit").Redraw()
	end, function(name)
		local _, valid = M._validate_group_name(name)
		return valid
	end, old_name)
end

---@param n integer
function M.func.select(n)
	M.listing[0] = require("rabbit").ctx.listing
	if M.listing[0][n] == nil then
		M.listing.paths[M._dir] = {""}
		M.listing[0][n] = "rabbitmsg://#up!"
	elseif string.find(M.listing[0][n], "rabbitmsg://") ~= 1 then
		vim.print("Not a group")
		return require("rabbit").func.select(n)
	end

	local entry = M.listing[0][n]:sub(#"rabbitmsg://" + 1)

	if string.find(entry, "#up!") == 1 then
		table.remove(M.listing.paths[M._dir], #M.listing.paths[M._dir])
		M.listing.recursive = M.listing.persist[M._dir]
		for _, v in ipairs(M.listing.paths[M._dir]) do
			M.listing.recursive = M.listing.recursive[v]
		end
	else
		table.insert(M.listing.paths[M._dir], n)
		local t = M.listing.recursive[n]
		if type(t) == "table" then
			M.listing.recursive = t
		end
	end

	M._generate()
	if #M.listing.paths[M._dir] > 0 then
		set.add(M.listing[0], "rabbitmsg://#up!\n" .. M._path())
	end
	require("rabbit").Redraw()
end

---@param evt NvimEvent
---@param winid integer
function M.evt.BufEnter(evt, winid)
	if vim.uv.fs_stat(evt.file) == nil then
		return -- Not a local file
	end
	set.add(M.listing[winid], evt.file)
	M.listing.opened[1] = evt.file
end


---@param evt NvimEvent
---@param winid integer
function M.evt.BufDelete(evt, winid)
	set.sub(M.listing[winid], set.index(M.listing[winid], evt.file))
end


function M._prevent_duped_collections(obj)
	local recur = M.listing.persist[M._dir]

	for _, v in ipairs(M.listing.paths[M._dir]) do
		recur = recur[v]
		if obj == recur then
			vim.print("You cannot put a collection in itself!")
			return false
		end
	end

	recur = M.listing.persist[M._dir]
	local route = M.listing.refs[("%p"):format(obj)]
	local path = "~"
	for _, v in ipairs(route) do
		recur = recur[v]
		path = path .. "/" .. recur[1]
	end

	local ret = true

	for i, v in ipairs(recur) do
		if obj == v then
			vim.ui.select({"Copy", "Move"}, {
				prompt = "This collection (" .. v[1] .. ") is already in `" .. path .. "`. What do you want to do?",
			}, function(choice)
				if choice == "Move" then
					table.remove(recur, i)
					if #M.listing.paths[M._dir] > 0 and i <= M.listing.paths[M._dir][#M.listing.paths[M._dir]] then
						M.listing.paths[M._dir][#M.listing.paths[M._dir]] = M.listing.paths[M._dir][#M.listing.paths[M._dir]] - 1
					end
					if #route > 0 and i <= route[#route] then
						route[#route] = route[#route] - 1
					end
					if M.listing.recursive == recur then
						set.sub(M.listing.recursive, v)
						set.sub(M.listing[0], "rabbitmsg://" .. v[1])
					end
				elseif choice == "Copy" then
					recur[i] = vim.deepcopy(obj)
				else
					ret = false
				end
			end)
		end
	end

	return ret
end

---@param n integer
function M.func.file_add(n)
	M.listing[0] = require("rabbit").ctx.listing
	print("")

	local cur = M.listing.opened[1] or vim.api.nvim_buf_get_name(require("rabbit").user.buf)
	M.listing.opened[1] = cur

	local collection = M.listing.collections[cur]
	if collection == nil and vim.uv.fs_stat(tostring(cur)) == nil then
		return
	end

	n = math.max((#M.listing.paths[M._dir] > 0 and 2 or 1), math.min(#M.listing[0] + 1, n))

	if collection ~= nil then
		if not M._prevent_duped_collections(collection) then
			return
		end

		M.listing.refs[("%p"):format(collection)] = vim.deepcopy(M.listing.paths[M._dir])
		local conflict = true
		while conflict do
			conflict = false
			for _, v in pairs(M.listing.recursive) do
				if v[1] == collection[1] then
					conflict = true
					collection[1] = collection[1] .. "+"
					break
				end
			end
		end
		table.insert(M.listing.recursive, n, collection)
		table.insert(M.listing[0], n, "rabbitmsg://" .. collection[1])
	else
		set.sub(M.listing.recursive, cur)
		set.sub(M.listing[0], cur)
		table.insert(M.listing.recursive, n, cur)
		table.insert(M.listing[0], n, cur)
	end
	set.save(M.memory, M.listing.persist)
	require("rabbit").Redraw()
end


---@param n integer
function M.func.file_del(n)
	M.listing[0] = require("rabbit").ctx.listing
	local entry = M.listing[0][n]
	if entry == nil then
		return
	end

	if string.find(entry, "rabbitmsg://#up!") == 1 then
		return M._rename(M.listing.recursive[1])
	end

	set.sub(M.listing[0], entry)
	if string.find(entry, "rabbitmsg://") == 1 then
		local t = M.listing.recursive[n]
		if type(t) == "table" then
			local new_t = vim.deepcopy(t)
			M.listing.collections[entry] = new_t
			M.listing.opened[1] = entry
			if M.listing.refs == nil then
				M.listing.refs = {}
			end
			M.listing.refs[("%p"):format(new_t)] = {}
		end

		table.remove(M.listing.recursive, n)
	else
		set.sub(M.listing.recursive, entry)
		M.listing.opened[1] = entry
	end

	set.save(M.memory, M.listing.persist)
	require("rabbit").Redraw()
end


---@param winid integer
function M.evt.RabbitEnter(evt, winid)
	M.listing.opened[1] = nil
	M.ctx.winid = winid

	if M.listing.persist[evt.match] == nil then
		M.listing.persist[evt.match] = {}
	end

	if M.listing.recursive == nil then
		M.listing.persist[evt.match] = M.listing.persist[evt.match] or {}
		M.listing.recursive = M.listing.persist[evt.match]
	end

	if M.listing.paths[evt.match] == nil then
		M.listing.paths[evt.match] = {}
	end

	if M._dir ~= evt.match then
		M._dir = evt.match
		M.listing.recursive = M.listing.persist[evt.match]
		for _, v in ipairs(M.listing.paths[M._dir]) do
			M.listing.recursive = M.listing.recursive[v]
		end
	end

	M._generate()

	if #M.listing.paths[evt.match] > 0 then
		table.insert(M.listing[0], 1, "rabbitmsg://#up!\n" .. M._path())
	end
end


function M._generate()
	M.listing[0] = {}
	for i, v in pairs(M.listing.recursive) do
		if i == 1 and #M.listing.paths[M._dir] > 0 then
			-- pass
		elseif type(v) == "table" then
			if #v <= 0 then
				table.insert(v, 1, "something went terribly wrong here")
			end
			table.insert(M.listing[0], "rabbitmsg://" .. v[1])
		elseif not M.opts.ignore_opened or set.index(M.listing[M.ctx.winid], v) == nil then
			table.insert(M.listing[0], v)
		end
	end
end


---Returns the collection path
---@return string string
function M._path()
	local s = (#M.listing.paths[M._dir] > 3 and require("rabbit").opts.window.overflow or "~")
	local recur = M.listing.persist[M._dir]
	local l = require("rabbit").opts.window.path_len
	for i = 1, #M.listing.paths[M._dir] do
		recur = recur[M.listing.paths[M._dir][i]]
		if i > #M.listing.paths[M._dir] - 3 then
			local a = recur[1]
			if #a > l then
				a = a:sub(1, l - 1) .. "…"
			end
			s = s .. "/" .. a
		end
	end
	return s
end


function M.func.group_up()
	if #M.listing.paths[M._dir] > 0 then
		M.func.select(1)
	end
end

return M
