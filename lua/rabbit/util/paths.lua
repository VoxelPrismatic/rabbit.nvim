local PATHS = {}

local git_cache = {}

-- Git root from current directory
---@return string
function PATHS.git()
	local path = vim.fn.getcwd()
	if git_cache[path] ~= nil then
		return git_cache[path]
	end

	local git, errmsg = io.popen("git rev-parse --show-toplevel 2> /dev/null")
	if git == nil then
		error("Could not run git: " .. errmsg)
	end

	git_cache[path] = path

	for line in git:lines() do
		git_cache[path] = line
		break
	end
	git:close()

	return git_cache[path]
end

return PATHS
