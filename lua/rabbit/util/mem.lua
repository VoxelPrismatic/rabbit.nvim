local MEM = {}

-- Split the paths into components
---@param path string
local function split_path(path)
	local components = {}
	if vim.fn.has("win") then
		path = path:gsub("\\", "/"):sub(2) -- C:\ --> /
	end
	for component in path:gmatch("[^/]+") do
		table.insert(components, component)
	end
	return components
end

---@param source string
---@param target string
---@return string[]
local function relative_filepath(source, target)
	-- Split the paths into components
	-- We do not care about the filename for the source
	local src_path = split_path(vim.fs.dirname(source))
	local dst_path = split_path(target)

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

local rel_cache = {} ---@type { [integer]: { [string]: { [string]: { dir: string, name: string } } } }
local rel_semi_cache = {} ---@type { [string]: { [string]: string[] } }

---@class Rabbit.Mem.RelPath.Kwargs
---@field source string Which file you're coming from.
---@field target string Which file you're going to.
---@field dirname_trim integer The maximum number of characters to display in a folder name.
---@field dirname_char string The character to use for directory name trimming. (use with dirname_trim)
---@field distance_trim integer The maximum number of folders to display.
---@field distance_char string The character to use for overflow. (use with distance_trim)
---@field width integer The maximum width of the window.

-- Return the relative path between two paths. Separated here so you can easily copy/paste
---@param kwargs Rabbit.Mem.RelPath.Kwargs
---@return { dir: string, name: string }
local function rel_path(kwargs)
	-- Cache results; calculating every time is expensive, especially on WSL.
	-- It saves an order of magnitude of time. 50us+ down to 3us
	-- We can assume that the trim characters will be the same, since this is a private function
	if rel_cache[kwargs.width] == nil then
		rel_cache[kwargs.width] = { [kwargs.source] = {} }
	elseif rel_cache[kwargs.width][kwargs.source] == nil then
		rel_cache[kwargs.width][kwargs.source] = {}
	elseif rel_cache[kwargs.width][kwargs.source][kwargs.target] ~= nil then
		return rel_cache[kwargs.width][kwargs.source][kwargs.target]
	end

	if rel_semi_cache[kwargs.source] == nil then
		rel_semi_cache[kwargs.source] = {}
	end

	-- Again, cache results. This time, we're just storing the relative path instead of the final return
	if rel_semi_cache[kwargs.source][kwargs.target] == nil then
		local source = vim.fn.fnamemodify(kwargs.source, ":p")
		local target = vim.fn.fnamemodify(kwargs.target, ":p")
		rel_semi_cache[kwargs.source][kwargs.target] = relative_filepath(source, target)
	end

	local relative = rel_semi_cache[kwargs.source][kwargs.target]

	if #relative > kwargs.distance_trim + 2 or #table.concat(relative) > kwargs.width then
		while
			#relative > kwargs.distance_trim + 1
			or relative[1] == ".."
			or (#table.concat(relative) > kwargs.width and #relative > 1)
		do
			table.remove(relative, 1)
		end
		table.insert(relative, 1, kwargs.distance_char or ":::")
	elseif relative[1] == ".." then
		while #relative >= 2 and relative[2] == ".." do
			table.remove(relative, 2)
			relative[1] = relative[1] .. "."
		end
	else
		table.insert(relative, 1, ".")
	end

	local ret = {
		dir = "",
		name = "",
	}

	for i, v in ipairs(relative) do
		if i == #relative then
			ret.name = v
		else
			if #v > kwargs.dirname_trim then
				v = v:sub(1, kwargs.dirname_trim - 1) .. kwargs.dirname_char
			end
			ret.dir = ret.dir .. v .. "/"
		end
	end

	rel_cache[kwargs.width][kwargs.source][kwargs.target] = ret

	return ret
end

-- Like rel_path, but fills in all the defaults. (rel_path is separate for easy copy/paste)
---@param target string
---@return { dir: string, name: string }
function MEM.rel_path(target)
	local CTX = require("rabbit.term.ctx")
	local CONFIG = require("rabbit.config")
	local UIL = require("rabbit.term.listing")
	if not vim.api.nvim_buf_is_valid(CTX.user.buf) then
		CTX.user.buf = vim.api.nvim_win_get_buf(CTX.user.win)
	end
	local source = vim.api.nvim_buf_get_name(CTX.user.buf)
	if vim.uv.fs_stat(source) == nil then
		source = vim.fn.getcwd()
	end
	return rel_path({
		source = vim.fs.dirname(source),
		target = tostring(target),
		width = UIL._fg.conf.width,
		distance_trim = CONFIG.window.overflow.distance_trim,
		dirname_trim = CONFIG.window.overflow.dirname_trim,
		distance_char = CONFIG.window.overflow.distance_char,
		dirname_char = CONFIG.window.overflow.dirname_char,
	})
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

return MEM
