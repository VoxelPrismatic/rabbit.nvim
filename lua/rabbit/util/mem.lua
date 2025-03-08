local MEM = {}

local function split_path(path)
	local components = {}
	if vim.fn.has("win") then
		path = path:gsub("\\", "/"):sub(2) -- C:\...\... -> /.../...
	end
	for component in path:gmatch("[^/]+") do
		table.insert(components, component)
	end
	return components
end

local function relative_filepath(source, target)
	-- Split the paths into components
	local source_components = split_path(source)
	local target_components = split_path(target)
	local relative_components = {}

	-- Drop the file part of the source path
	local source_paths = vim.deepcopy(source_components)
	table.remove(source_paths)

	-- Find the length of the common prefix
	local common_len = 0
	for i = 1, math.min(#source_paths, #target_components) do
		if source_paths[i] ~= target_components[i] then
			break
		end
		common_len = i
	end

	-- Add '..' for each directory to go up from source to the common ancestor
	for _ = 1, #source_paths - common_len do
		table.insert(relative_components, "..")
	end

	-- Add the remaining components from target after the common prefix
	for i = common_len + 1, #target_components do
		table.insert(relative_components, target_components[i])
	end

	return relative_components
end

---@class Rabbit.Mem.RelPath.Kwargs
---@field source string Which file you're coming from.
---@field target string Which file you're going to.
---@field distance_trim integer The maximum number of folders to display.
---@field dirname_trim integer The maximum number of characters to display in a folder name.
---@field dirname_char string The character to use for directory name trimming. (use with cutoff)
---@field distance_char string The character to use for overflow. (use with max_parts)
---@field width integer The maximum width of the window.

-- Return the relative path between two paths.
---@param kwargs Rabbit.Mem.RelPath.Kwargs
---@return { dir: string, name: string }
local function rel_path(kwargs)
	local source = vim.fn.fnamemodify(kwargs.source, ":p")
	local target = vim.fn.fnamemodify(kwargs.target, ":p")

	local relative = relative_filepath(source, target)

	if #relative > kwargs.distance_trim + 2 then
		while #relative > kwargs.distance_trim + 1 or relative[1] == ".." do
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

	return ret
end

-- Like rel_path, but fills in all the defaults. (rel_path is separate for easy copy/paste)
---@param target string
---@return { dir: string, name: string }
function MEM.rel_path(target)
	local CTX = require("rabbit.term.ctx")
	local CONFIG = require("rabbit.config")
	local UIL = require("rabbit.term.listing")
	return rel_path({
		source = vim.api.nvim_buf_get_name(CTX.user.buf),
		target = tostring(target),
		width = UIL._fg.conf.width,
		distance_trim = CONFIG.window.overflow.distance_trim,
		dirname_trim = CONFIG.window.overflow.dirname_trim,
		distance_char = CONFIG.window.overflow.distance_char,
		dirname_char = CONFIG.window.overflow.dirname_char,
	})
end

return MEM
