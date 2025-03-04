local rect = require("rabbit.term.rect")

---@class Rabbit.UI.Listing
UIL = {
	user = { ns = 0 }, ---@type Rabbit.UI.Workspace
	this = { ns = vim.api.nvim_create_namespace("rabbit") }, ---@type Rabbit.UI.Workspace
}

-- Creates a buffer for the given plugin
---@param plugin Rabbit.Plugin
function UIL.spawn(plugin)
	UIL.user.buf = vim.api.nvim_get_current_buf()
	UIL.user.win = vim.api.nvim_get_current_win()
	UIL.user.view = vim.fn.winsaveview()
	UIL.user.conf = vim.api.nvim_win_get_config(UIL.user.win)
	UIL.user.conf.width = UIL.user.conf.width or vim.api.nvim_win_get_width(UIL.user.win)
	UIL.user.conf.height = UIL.user.conf.height or vim.api.nvim_win_get_height(UIL.user.win)

	UIL.this.buf = vim.api.nvim_create_buf(false, true)
	UIL.this.win = vim.api.nvim_open_win(UIL.this.buf, true, UIL.rect(UIL.user.win))
end

-- Creates the bounding box for the window
---@param win number
---@return vim.api.keyset.win_config
function UIL.rect(win)
	local spawn = require("rabbit.config").window.spawn

	local calc_width = spawn.width
	local calc_height = spawn.height

	if calc_width == nil then
		calc_width = 64
	elseif calc_width <= 1 then
		calc_width = math.floor(UIL.user.conf.width * calc_width)
	end

	if calc_height == nil then
		calc_height = 24
	elseif calc_height <= 1 then
		calc_height = math.floor(UIL.user.conf.height * calc_height)
	end

	local ret = {
		x = 0,
		y = 0,
		w = UIL.user.conf.width,
		h = UIL.user.conf.height,
	}

	if spawn.mode == "split" then
		if spawn.side == "left" then
			ret.w = calc_width
		elseif spawn.side == "right" then
			ret.x = UIL.user.conf.width - calc_width
			ret.w = calc_width
		elseif spawn.side == "above" then
			ret.h = calc_height
		elseif spawn.side == "below" then
			ret.y = UIL.user.conf.height - calc_height
			ret.h = calc_height
		else
			error("[Rabbit]: Unknown split mode: " .. spawn.mode)
		end
	end

	if spawn.mode == "float" then
		ret.w = calc_width
		ret.h = calc_height

		if spawn.side == "w" or spawn.side == "c" or spawn.side == "e" then
			ret.y = math.floor((UIL.user.conf.height - calc_height) / 2)
		elseif spawn.side == "sw" or spawn.side == "s" or spawn.side == "se" then
			ret.y = UIL.user.conf.height - calc_height
		end

		if spawn.side == "n" or spawn.side == "c" or spawn.side == "s" then
			ret.x = math.floor((UIL.user.conf.width - calc_width) / 2)
		elseif spawn.side == "ne" or spawn.side == "e" or spawn.side == "se" then
			ret.x = UIL.user.conf.width - calc_width
		end
	end

	ret = rect.calc(ret, win)

	return { ---@type vim.api.keyset.win_config
		row = spawn.mode ~= "split" and ret.y or nil,
		col = spawn.mode ~= "split" and ret.x or nil,
		width = (spawn.side ~= "top" and spawn.side ~= "bottom") and ret.w or nil,
		height = (spawn.side ~= "left" and spawn.side ~= "right") and ret.h or nil,
		relative = spawn.mode ~= "split" and "win" or nil,
		split = spawn.mode == "split" and spawn.side or nil,
		style = "minimal",
		zindex = 10,
	}
end

return UIL
