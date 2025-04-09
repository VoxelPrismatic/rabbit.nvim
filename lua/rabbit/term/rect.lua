local TERM = require("rabbit.util.term")
local RECT = {}

---@class Rabbit.UI.Rect
---@field x number X position.
---@field y number Y position.
---@field w number Width.
---@field h number Height.
---@field T? number Y position of top border.
---@field B? number Y position of bottom border.
---@field L? number X position of left border.
---@field R? number X position of right border.
---@field split? string
---@field z? number Z-index

-- Creates a bounding box
-- @param rect Rabbit.UI.Rect
-- @param win? integer Window ID (default: current window)
---@return Rabbit.UI.Rect
function RECT.calc(rect, win)
	local conf = TERM.win_config(win)
	if conf == nil then
		error("Invalid window ID: " .. win)
	end

	if rect.x < 0 then
		rect.x = 0
	elseif rect.x > conf.width then
		rect.x = conf.width
	end

	if rect.y < 0 then
		rect.y = 0
	elseif rect.y > conf.height then
		rect.y = conf.height
	end

	if rect.w < 0 then
		rect.w = 0
	elseif rect.w + rect.x > conf.width then
		rect.w = conf.width - rect.x
	end

	if rect.h < 0 then
		rect.h = 0
	elseif rect.h + rect.y > conf.height then
		rect.h = conf.height - rect.y
	end

	rect.x = rect.x + conf.col
	rect.y = rect.y + conf.row

	rect.T = rect.y
	rect.B = rect.y + rect.h
	rect.L = rect.x
	rect.R = rect.x + rect.w
	return rect
end

-- Creates a win_config
---@param rect Rabbit.UI.Rect
---@return vim.api.keyset.win_config
function RECT.win(rect)
	return { ---@type vim.api.keyset.win_config
		row = rect.split == nil and rect.y or nil,
		col = rect.split == nil and rect.x or nil,
		width = rect.w,
		height = rect.h,
		relative = rect.split == nil and "editor" or nil,
		split = rect.split,
		style = "minimal",
		anchor = "NW",
		zindex = rect.z,
	}
end

return RECT
