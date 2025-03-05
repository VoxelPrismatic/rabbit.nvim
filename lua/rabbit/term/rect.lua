local RECT = {}

-- Creates a bounding box
-- @param rect Rabbit.UI.Rect
-- @param win? integer Window ID (default: current window)
---@return Rabbit.UI.Rect
function RECT.calc(rect, win)
	local max_width = vim.api.nvim_win_get_width(win or 0)
	local max_height = vim.api.nvim_win_get_height(win or 0)

	if rect.x < 0 then
		rect.x = 0
	elseif rect.x > max_width then
		rect.x = max_width
	end

	if rect.y < 0 then
		rect.y = 0
	elseif rect.y > max_height then
		rect.y = max_height
	end

	if rect.w < 0 then
		rect.w = 0
	elseif rect.w + rect.x > max_width then
		rect.w = max_width - rect.x
	end

	if rect.h < 0 then
		rect.h = 0
	elseif rect.h + rect.y > max_height then
		rect.h = max_height - rect.y
	end

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
		row = rect.y,
		col = rect.x,
		width = rect.w,
		height = rect.h,
		relative = rect.split == nil and "win" or nil,
		split = rect.split,
		style = "minimal",
		zindex = rect.z,
	}
end

return RECT
