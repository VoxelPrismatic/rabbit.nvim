---@class Rabbit.Stack.Cursor
local CURSOR = {
	-- Target workspace
	---@type Rabbit.Stack.Workspace
	target = nil,
}

function CURSOR.new(workspace)
	return setmetatable({ target = workspace }, { __index = CURSOR })
end

-- Gets the window's cursor position
function CURSOR:get()
	assert(self.target ~= nil, "Cannot get cursor from nil workspace")
	return vim.api.nvim_win_get_cursor(self.target.win.id)
end

-- Sets the window's cursor position. Handles out of bounds warning
---@param line integer Line number
---@param col integer Column number
---@param focus? boolean Focus the window
---@return boolean Out of bounds
---@return { [1]: integer, [2]: integer } New cursor position (in case it was out of bounds)
---@overload fun(pos: { [1]: integer, [2]: integer }): { [1]: integer, [2]: integer }
function CURSOR:set(line, col, focus)
	assert(self.target ~= nil, "Cannot set lines in nil workspace")

	local cur = { line, col }
	if type(line) == "table" then
		cur = line
	end

	if focus then
		self.target:focus()
	end

	local ok = pcall(vim.api.nvim_win_set_cursor, self.target.win.id, cur)
	if ok then
		return false, cur
	end

	cur[1] = math.min(cur[1], vim.api.nvim_buf_line_count(self.target.buf.id) - 1)
	cur[2] = math.min(cur[2], #vim.api.nvim_buf_get_lines(self.target.buf.id, cur[1] - 1, cur[1], true)[1])
	vim.api.nvim_win_set_cursor(self.target.win.id, cur)

	return true, cur
end

return CURSOR
