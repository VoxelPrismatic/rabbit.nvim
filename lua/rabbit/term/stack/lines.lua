local HL = require("rabbit.term.highlight")

---@class Rabbit.Stack.Lines
local LINES = {
	-- Target workspace
	---@type Rabbit.Stack.Workspace
	target = nil,
}

function LINES.new(workspace)
	return setmetatable({ target = workspace }, { __index = LINES })
end

-- Gets the lines from the buffer
---@param start integer | 0 Start line
---@param end_ integer | -1 End line
---@param strict? boolean | false Whether to use strict mode
---@return string[]
---@overload fun(): string[] # All lines
function LINES:get(start, end_, strict)
	assert(self.target ~= nil, "Cannot get lines from nil workspace")

	return vim.api.nvim_buf_get_lines(self.target.buf.id, start or 0, end_ or -1, strict or false)
end

-- Gets one line
---@param line integer Line number
function LINES:nr(line)
	return self:get(line, line + 1)[1]
end

---@class (exact) Rabbit.Stack.Kwargs.SetLines
---@field start integer | 0 Start line
---@field end_? integer End line (used to clear the rest of the buffer)
---@field many boolean If true, the lines field will be treated as many lines
---@field strict? boolean | false Whether to use strict mode
---@field ns? integer | string Highlight namespace

-- Sets the lines in the buffer
---@param lines (Rabbit.Term.HlLine | string)[] Lines to set
---@param opts? Rabbit.Stack.Kwargs.SetLines
function LINES:set(lines, opts)
	assert(self.target ~= nil, "Cannot set lines in nil workspace")

	if opts == nil then
		opts = { strict = false, start = 0, many = true }
	end

	if opts.strict == nil then
		opts.strict = false
	end

	local ns = opts.ns or self.target.ns
	if type(ns) == "string" then
		ns = vim.api.nvim_create_namespace(ns)
	end

	local new_end = HL.set_lines({
		bufnr = self.target.buf.id,
		ns = ns,
		lines = lines,
		width = self.target.win.config.width,
		lineno = opts.start or 0,
		strict = opts.strict or false,
		many = opts.many or false,
	})

	if opts.end_ ~= nil and (opts.end_ == -1 or opts.end_ > new_end) then
		vim.api.nvim_buf_set_lines(self.target.buf.id, opts.end_, -1, opts.strict, {})
	end
end

return LINES
