---@class Rabbit._.History.Listing
local LIST = {
	---@type table<integer, Rabbit._.History.Window>
	win = {},

	---@type integer[]
	order = {},
}

-- Initializes a window entry if one doesn't exist yet
---@param winnr integer
function LIST.init(winnr)
	if LIST.win[winnr] == nil then
		LIST.win[winnr] = { ---@type Rabbit._.History.Window
			killed = false,
			name = "" .. winnr,
			history = {},
			closed = {},
		}
	end

	return LIST.win[winnr]
end

---@class Rabbit._.History.Window
---@field killed boolean Whether or not the window was closed
---@field name string Custom name for the window
---@field history integer[] List of buffers in the window
---@field closed string[] List of buffers that have been closed

return LIST
