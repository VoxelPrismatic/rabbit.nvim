local MEM = require("rabbit.util.mem")
local PLUGIN_CONFIG = require("rabbit.plugins.forage.config")

---@class Rabbit*Forage.List
local LIST = {
	---@type Rabbit*Forage.Memory
	---@diagnostic disable-next-line: missing-fields
	forage = {},
}

-- Get the scoped directory
---@param cwd? Rabbit.Recursive<string>
---@return string
local function _cwd(cwd)
	cwd = cwd or PLUGIN_CONFIG.cwd or vim.fn.getcwd()
	while type(cwd) == "function" do
		cwd = cwd()
	end
	assert(type(cwd) == "string", "Expected string, got " .. type(cwd))
	return cwd
end

---@class (exact) Rabbit*Forage.Score
---@field path string The path
---@field time integer When you last opened this file
---@field count integer How many times you opened this file
---@field score integer Calculated score

---@class (exact) Rabbit*Forage.Memory: Rabbit.Writeable
---@field oxide table<string, Rabbit*Forage.Score[]>
---@field fzf_opts Rabbit*Forage.Options.FuzzyFind
---@field rg_opts Rabbit*Forage.Options.Grep
---@field find_opts Rabbit*Forage.Options.Find

---@class (exact) Rabbit*Forage.Project
---@field score table<string, Rabbit*Forage.Score>
---@field history Rabbit*Forage.SearchHistory[]

---@class (exact) Rabbit*Forage.SearchHistory
---@field time integer Timestamp
---@field term string Searched term
---@field tool string Search tool

-- [Zoxide's aging algorithm](https://github.com/ajeetdsouza/zoxide/wiki/Algorithm#matching)
-- Zoxide is a substitute for cd, whereas this is a substitute
-- for opening files, so we check files instead of directories.
---@param cwd? string | fun(): string The current working directory
---@return Rabbit*Forage.Score[]
function LIST.quickscore(cwd)
	cwd = _cwd(cwd)
	local time = os.time()
	local sum = 0
	local listing = LIST.forage.oxide[cwd]
	if listing == nil then
		listing = {}
		LIST.forage.oxide[cwd] = listing
	end
	assert(type(listing) == "table", "Expected table, got " .. type(listing))
	local children_only = PLUGIN_CONFIG.oxide.children_only and MEM.is_type(cwd, "directory")
	local do_delete = math.random() < 0.05
	for i = #listing, 1, -1 do
		local obj = listing[i]
		if children_only and not obj.path:find(cwd, 1, true) or (do_delete and not MEM.is_type(obj.path, "file")) then
			table.remove(listing, i)
			goto continue
		end

		local diff = time - obj.time
		local score = obj.count

		if diff < 3600 then -- Within the last hour
			score = score * 4
		elseif diff < 86400 then -- Within the last day
			score = score * 2
		elseif diff < 604800 then -- Within the last week
			score = score / 2
		else
			score = score / 4
		end

		sum = sum + score
		obj.score = score

		::continue::
	end

	table.sort(listing, function(a, b)
		return a.score > b.score
	end)

	if sum > PLUGIN_CONFIG.oxide.max_age then
		local clip = (PLUGIN_CONFIG.oxide.max_age * 0.9) / sum
		for i = #listing, 1, -1 do
			local obj = listing[i]
			obj.score = obj.score * clip
			if obj.score < 1 then
				table.remove(listing, i)
			end
		end
	end

	LIST.forage:__Save()
	return listing
end

-- Loads collection data from disk
---@param path string File path
function LIST.load(path)
	LIST.forage = MEM.Read(path) --[[@as Rabbit*Forage.Memory]]
	LIST.forage.oxide = LIST.forage.oxide or {}
	for _, listing in pairs(LIST.forage.oxide) do
		for i = #listing, 1, -1 do
			if not MEM.is_type(listing[i].path, "file") then
				table.remove(listing, i)
			end
		end
	end
end

-- Touch a file in the oxide list
---@param file string File path
---@param cwd? Rabbit.Recursive<string>
function LIST.touch(file, cwd)
	cwd = _cwd(cwd)
	local children_only = PLUGIN_CONFIG.oxide.children_only and MEM.is_type(cwd, "directory")
	if children_only and not file:find(cwd, 1, true) then
		return
	end

	local target = LIST.forage.oxide[cwd]
	if target == nil then
		target = {}
		LIST.forage.oxide[cwd] = target
	end

	local obj = nil ---@type Rabbit*Forage.Score
	for _, v in ipairs(target) do
		if v.path == file then
			obj = v
			break
		end
	end

	if obj == nil then
		obj = {
			path = file,
			time = os.time(),
			count = 1,
			score = 0,
		}
		table.insert(target, obj)
	else
		obj.count = obj.count + 1
		obj.time = os.time()
	end

	LIST.forage:__Save()
end

---@type Rabbit.Entry.Collection
LIST.default = {
	class = "entry",
	type = "collection",
	label = "Forage",
	actions = {
		children = true,
	},
	ctx = {
		root = true,
	},
}

return LIST
