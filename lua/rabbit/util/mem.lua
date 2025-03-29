local CTX = require("rabbit.term.ctx")
local CONFIG = require("rabbit.config")
local MEM = {}

-- Split the paths into components
---@param path string
---@return string[] Components
---@return string Absolute path
local function split_path(path)
	local components = {}
	path = vim.fn.fnamemodify(path, ":p")
	if vim.fn.has("win") == 1 then
		path = path:gsub("\\", "/"):sub(2) -- C:\ --> /
	end
	for component in path:gmatch("[^/]+") do
		table.insert(components, component)
	end
	return components, path
end

---@param source string
---@param target string
---@return string[]
local function relative_filepath(source, target)
	-- Split the paths into components
	local src_path, source_path = split_path(source)
	local dst_path = split_path(target)

	-- We do not care about the file part
	local stat = vim.uv.fs_stat(source_path)
	if stat == nil or stat.type ~= "directory" then
		table.remove(src_path, #src_path)
	end

	local same = 1
	local max_len = math.min(#src_path, #dst_path)

	while same <= max_len and src_path[same] == dst_path[same] do
		same = same + 1
	end

	local rel_path = { unpack(dst_path, same) }

	-- Go up one folder for each differing ancestor
	for _ = 0, #src_path - same do
		table.insert(rel_path, 1, "..")
	end

	return rel_path
end

---@class Rabbit.Mem.RelPath.Kwargs
---@field source string Which file you're coming from.
---@field target string Which file you're going to.
---@field dirname_trim integer The maximum number of characters to display in a folder name.
---@field dirname_char string The character to use for directory name trimming. (use with dirname_trim)
---@field distance_trim integer The maximum number of folders to display.
---@field distance_char string The character to use for overflow. (use with distance_trim)
---@field width integer The maximum width of the window.

---@class Rabbit.Mem.RelPath
---@field dir string Dir part.
---@field name string Name part.
---@field merge string Merged path.
---@field parts string[] The entire relative path from source to target.
---@field source string The source file.
---@field target string The target file.
---@field [integer] Rabbit.Mem.RelPath re-cast width a new max width.
---
---@type Rabbit.Caching.Mem.RelPath
local real_cache = {}

---@param self Rabbit.Mem.RelPath
---@param new_width integer
local function dynamic_rel_path(self, new_width)
	if type(new_width) ~= "number" or new_width <= 0 or math.floor(new_width) ~= new_width then
		error("width must be a positive integer")
	end

	local target = rawget(real_cache[self.source], self.target) or self

	local ret = rawget(target, new_width)
	if ret ~= nil then
		return ret
	end

	local relative = vim.deepcopy(self.parts)
	local flow = CONFIG.window.overflow
	if #relative > flow.distance_trim + 2 or #table.concat(relative) > new_width then
		while
			#relative > flow.distance_trim + 1
			or relative[1] == ".."
			or (#table.concat(relative) > new_width and #relative > 1)
		do
			table.remove(relative, 1)
		end
		table.insert(relative, 1, flow.distance_char or ":::")
	elseif relative[1] == ".." then
		while #relative >= 2 and relative[2] == ".." do
			table.remove(relative, 2)
			relative[1] = relative[1] .. "."
		end
	else
		table.insert(relative, 1, ".")
	end
	local name = ""
	local dir = ""

	for i, v in ipairs(relative) do
		if i == #relative then
			name = v
		else
			if #v > flow.dirname_trim then
				v = v:sub(1, flow.dirname_trim - 1) .. flow.dirname_char
			end
			dir = dir .. v .. "/"
		end
	end
	ret = {
		source = self.source,
		target = self.target,
		parts = self.parts,
		dir = dir,
		name = name,
		merge = dir .. name,
	}

	local stat = vim.uv.fs_stat(self.target)
	if stat ~= nil and stat.type == "directory" then
		ret.merge = ret.merge .. "/"
		ret.name = ret.name .. "/"
	end

	target[new_width] = setmetatable(ret, { __index = dynamic_rel_path })

	return ret
end

-- Return the relative path between two paths.
---@param source string The source file
---@param target string The target file to get the relative path to
---@param max_width? integer The maximum width of the window
---@return Rabbit.Mem.RelPath
local function rel_path(source, target, max_width)
	if not vim.api.nvim_buf_is_valid(CTX.user.buf) then
		CTX.user.buf = vim.api.nvim_win_get_buf(CTX.user.win)
	end

	if max_width == nil then
		local UI = require("rabbit.term.listing")
		max_width = UI._fg.conf.width
	end

	local ret = { ---@type Rabbit.Mem.RelPath
		source = source,
		target = target,
		parts = relative_filepath(source, target),
		dir = "",
		name = "",
		merge = "",
	}

	setmetatable(ret, { __index = dynamic_rel_path })
	return ret[max_width]
end

---@class Rabbit.Caching.Mem.RelPath
---@field [string] Rabbit.Caching.Mem.RelPath.Target The source directory to cache from

---@class Rabbit.Caching.Mem.RelPath.Target
---@field [0] uv.uv_timer_t Timer that automatically cleans up after 10m
---@field [string] Rabbit.Mem.RelPath The path to cache

---@type Rabbit.Caching.Mem.RelPath
local path_cache = setmetatable({}, {
	__index = function(_, source) ---@param source string
		source = vim.fs.dirname(vim.fn.fnamemodify(source, ":p"))
		local ret = real_cache[source]
		if ret == nil then
			local timer = vim.loop.new_timer()
			if timer == nil then
				error("Failed to create timer")
			end
			ret = { [0] = timer }
			real_cache[source] = setmetatable(ret, {
				__index = function(this, target) ---@param target string
					target = vim.fn.fnamemodify(target, ":p")
					this[target] = rel_path(source, target)
					return this[target]
				end,
			})
		end

		ret[0]:start(1000 * 600, 0, function()
			real_cache[source] = nil
			ret[0]:close()
		end)

		return ret
	end,
})
-- Like rel_path, but fills in all the defaults. (rel_path is separate for easy copy/paste)
---@param target string
---@return Rabbit.Mem.RelPath
function MEM.rel_path(target)
	local UI = require("rabbit.term.listing")
	local ok, source = pcall(vim.api.nvim_buf_get_name, CTX.user.buf)
	if not ok or vim.uv.fs_stat(source) == nil then
		source = vim.fn.getcwd()
	end

	return path_cache[source][target][UI._fg.conf.width]
end

---@param self Rabbit.Writeable
local function writeable_save(self)
	-- Vim doesn't trim functions, so we delete it and reinstate manually
	local dest = self.__Dest
	self.__Dest = nil
	self.__Save = nil
	MEM.Write(self, dest)
	self.__Dest = dest
	self.__Save = writeable_save
end

-- Tries to read a file. If the file isn't found, it returns an empty table.
---@param src string The path to the file to read.
---@return Rabbit.Writeable
function MEM.Read(src)
	local data, msg, errno = io.open(src, "r")
	local ret = {}
	if errno == 2 then
		--pass
	elseif data == nil then
		error(msg)
	else
		local serial = data:read("*a")
		data:close()
		if serial ~= "" then
			ret = vim.fn.json_decode(serial)
		end
	end

	ret.__Dest = src
	ret.__Save = writeable_save

	return ret
end

-- Tries to save a file. If the file doesn't exist, it is created.
-- If the data is not of JSON format, it will throw an error.
-- If the file cannot be saved, it will throw an error.
---@param dest string The path to the file to save.
---@param data table The data to save.
function MEM.Write(data, dest)
	local serial = vim.fn.json_encode(data)
	local writer, msg = io.open(dest, "w")
	if writer == nil then
		error(msg)
	end

	writer:write(serial)
	writer:close()
end

---@class Rabbit.Writeable: table
---@field __Save fun(self: Rabbit.Writeable)
---@field __Dest string The destination
---

MEM.cache = real_cache

return MEM
