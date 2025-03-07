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
---@field max_parts integer The maximum number of folders to display.
---@field cutoff integer The maximum number of characters to display in a folder name.
---@field trim string The character to use for directory name trimming. (use with cutoff)
---@field width integer The maximum width of the window.
---@field overflow string The character to use for overflow. (use with max_parts)

-- Return the relative path between two paths.
---@param kwargs Rabbit.Mem.RelPath.Kwargs
---@return { dir: string, name: string }
function MEM.rel_path(kwargs)
	local separator = vim.fn.has("win") and "\\" or "/"
	local source = vim.fn.fnamemodify(kwargs.source, ":p")
	local target = vim.fn.fnamemodify(kwargs.target, ":p")

	local relative = relative_filepath(source, target)
	vim.print(relative)

	if vim.uv.fs_stat(source) == nil then
		source = vim.fn.getcwd() .. separator .. "somethingidk"
	end

	-- Split by folder
	local source_parts = vim.split(source, separator)
	local target_parts = vim.split(target, separator)

	-- Get common path
	local common = 0
	for i = 1, math.min(#source_parts, #target_parts) do
		if source_parts[i] ~= target_parts[i] then
			break
		end
		common = common + 1
	end

	-- Construct relative path
	local cutoff = kwargs.cutoff or 12
	local filename = target_parts[#target_parts]
	local distance = #source_parts - common - 1
	local relative = ("../"):rep(distance)
	local fall = (kwargs.overflow or ":::") .. "/"

	if distance == 0 and #source_parts == #target_parts then
		return { dir = "", name = filename }
	elseif distance < (kwargs.max_parts or 3) then
		relative = ("."):rep(distance + 1) .. "/"
	elseif common + 1 == #source_parts - #target_parts then
		relative = fall
	end

	for i = common + 1, #target_parts - 1 do
		local p = target_parts[i]
		if #p > cutoff then
			p = p:sub(1, cutoff - 1) .. (kwargs.trim or "…")
		end
		relative = relative .. p .. "/"
	end

	-- Manage overflow
	local max_w = kwargs.width - 8 - #fall
	if (#relative + #filename) > max_w then
		while relative:sub(1, #"../") == "../" do
			relative = relative:sub(#"../" + 1)
		end

		while (#relative + #filename) > max_w do
			local q = vim.split(relative, "/")
			table.remove(q, 1)
			relative = table.concat(q, "/")
		end

		relative = fall .. relative
	end
	local r, count = string.gsub(relative, "%.%./", "")
	if count >= (kwargs.max_parts or 3) then
		relative = fall .. r
	elseif count > 1 then
		relative = ("."):rep(count + 1) .. "/" .. r
	end

	return {
		dir = relative ~= "/" and relative or "",
		name = filename,
	}
end

return MEM
