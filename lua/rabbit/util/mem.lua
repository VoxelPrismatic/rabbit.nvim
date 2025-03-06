local MEM = {}

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
	-- Get absolute paths
	local source = vim.fn.fnamemodify(kwargs.source, ":p")
	local target = vim.fn.fnamemodify(kwargs.target, ":p")

	-- Split by folder
	local separator = vim.fn.has("win") == 1 and "\\" or "/"
	local source_parts = vim.split(source, separator)
	local target_parts = vim.split(target, separator)

	vim.print("--", source_parts, target_parts, separator, source, target, kwargs)
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
