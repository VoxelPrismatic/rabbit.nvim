local set = require("rabbit.plugins.util")
local screen = require("rabbit.screen")


---@class Rabbit.Plugin.Harpoon.Options
---@field public ignore_opened? boolean Do not display currently open buffers
---@field public path_key? string|function:string Scope your working directory
---@field public conflict_parent? "copy" | "move" | "prompt" Default action when you try to move a collection into itself
---@field public conflict_copy? "copy" | "move" | "prompt" Default action when you try to move an existing collection


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
		conflict_parent = "prompt",
		conflict_copy = "prompt",
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


-- Validates this collection name against this collection and the parent collection
---@param name string The collection name
---@return string, boolean
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

-- Creates a new collection
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
		vim.api.nvim_win_set_cursor(require("rabbit").rabbit.win, { n + 2, #(screen.ctx.box.horizontal) + 1 })
	end, function(name)
		local _, valid = M._validate_group_name(name)
		return valid
	end)
end

-- Renames a collection
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
		return
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


-- Prevents duplicate collections
---@param obj Rabbit.Plugin.Listing.Persist.Recursive The collection possibly being duplicated
---@param n integer The index of the collection
function M._prevent_duped_collections(obj, n)
	local recur = M.listing.persist[M._dir]

	-- When you insert a collection into itself
	for _, v in ipairs(M.listing.paths[M._dir]) do
		recur = recur[v]
		if obj ~= recur then
			goto continue
		end
		require("rabbit.input").menu(
			"What do you want to do?",
			"You are about to place a collection into itself",
			M.opts.conflict_parent,
			nil,
			{
				{"copy", function()
					recur = M.listing.persist[M._dir]
					for i, p in ipairs(M.listing.paths[M._dir]) do
						if i < #M.listing.paths[M._dir] then
							recur = recur[p]
						end
					end

					for i, p in ipairs(recur) do
						if obj == p then
							recur[i] = vim.deepcopy(obj)
							M.listing.recursive = recur[i]
						end
					end
					M._dupe_handled(obj, n)
				end},
				{"cancel", function()
				end},
				{"move", function()
					require("rabbit.input").warn("Error!", "You cannot move a collection into itself!")
				end, hidden = true}
			}
		)

		do
			return
		end

		::continue::
	end



	-- When you try to insert the same collection in multiple places
	recur = M.listing.persist[M._dir]
	local route = M.listing.refs[("%p"):format(obj)]
	local path = "~"
	for _, v in ipairs(route) do
		recur = recur[v]
		path = path .. "/" .. recur[1]
	end

	for i, v in ipairs(recur) do
		if obj ~= v then
			goto continue
		end

		require("rabbit.input").menu(
			"What do you want to do?",
			"This collection (" .. v[1] .. ") is already in `" .. path .. "`",
			M.opts.conflict_copy,
			nil,
			{
				{"move", function()
					table.remove(recur, i)
					local paths = M.listing.paths[M._dir]
					if #paths > 0 and i <= paths[#paths] then
						paths[#paths]= paths[#paths] - 1
					end
					if #route > 0 and i <= route[#route] then
						route[#route] = route[#route] - 1
					end
					if M.listing.recursive == recur then
						set.sub(M.listing.recursive, v)
						set.sub(M.listing[0], "rabbitmsg://" .. v[1])
					end
					M._dupe_handled(obj, n)
				end},
				{"copy", function()
					recur[i] = vim.deepcopy(obj)
					M._dupe_handled(obj, n)
				end},
			}
		)

		do
			return
		end

		::continue::
	end

	-- No conflicts
	M._dupe_handled(obj, n)
end

-- Adds the collection to the listing
---@param collection Rabbit.Plugin.Listing.Persist.Recursive The target collection
---@param n integer Where to place it
function M._dupe_handled(collection, n)
	n = math.max((#M.listing.paths[M._dir] > 0 and 2 or 1), math.min(#M.listing[0] + 1, n))

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

	set.save(M.memory, M.listing.persist)
	require("rabbit").Redraw()
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


	if type(collection) == "table" then
		return M._prevent_duped_collections(collection, n)
	end

	set.sub(M.listing.recursive, cur)
	set.sub(M.listing[0], cur)

	n = math.max((#M.listing.paths[M._dir] > 0 and 2 or 1), math.min(#M.listing[0] + 1, n))

	table.insert(M.listing.recursive, n, cur)
	table.insert(M.listing[0], n, cur)
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
			M.listing.refs = {
				[("%p"):format(new_t)] = {},
			}
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
	for i, v in ipairs(M.listing.paths[M._dir]) do
		recur = recur[v]
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
