local rect = require("rabbit.term.rect")
local CTX = require("rabbit.term.ctx")
local bufid, winid

---@class Rabbit.UI.Listing
UIL = {}

vim.api.nvim_create_autocmd("BufEnter", {
	callback = function()
		local w = vim.api.nvim_get_current_win()
		for _, v in ipairs(CTX.stack) do
			if v.win == w then
				return
			end
		end

		if bufid == vim.api.nvim_get_current_buf() then
			return
		end

		while #CTX.stack > 0 do
			local v = CTX.stack[1]
			vim.api.nvim_win_close(v.win, true)
			vim.api.nvim_buf_delete(v.buf, { force = true })
			table.remove(CTX.stack, 1)
		end
	end,
})

-- Creates a buffer for the given plugin
---@param plugin Rabbit.Plugin
function UIL.spawn(plugin)
	CTX.user = CTX.workspace()

	-- Create background window
	local r = UIL.rect(CTX.user.win, 55)
	bufid = vim.api.nvim_create_buf(false, true)
	winid = vim.api.nvim_open_win(bufid, true, r)
	CTX.append(bufid, winid)

	-- Create foreground window
	r.split = nil
	r.relative = "win"
	r.row = 2
	r.col = 1
	r.width = r.width - 2
	r.height = r.height - 4
	r.zindex = r.zindex + 1
	bufid = vim.api.nvim_create_buf(false, true)
	winid = vim.api.nvim_open_win(bufid, true, r)
	CTX.append(bufid, winid)
	bufid = -1
end

-- Creates the bounding box for the window
---@param win integer
---@param z integer
---@return vim.api.keyset.win_config
function UIL.rect(win, z)
	local spawn = require("rabbit.config").window.spawn

	local calc_width = spawn.width
	local calc_height = spawn.height

	if calc_width == nil then
		calc_width = 64
	elseif calc_width <= 1 then
		calc_width = math.floor(CTX.user.conf.width * calc_width)
	end

	if calc_height == nil then
		calc_height = 24
	elseif calc_height <= 1 then
		calc_height = math.floor(CTX.user.conf.height * calc_height)
	end

	local ret = { ---@type Rabbit.UI.Rect
		x = 0,
		y = 0,
		z = z or 10,
		w = CTX.user.conf.width,
		h = CTX.user.conf.height,
	}

	if spawn.mode == "split" then
		ret.split = spawn.side
		if spawn.side == "left" then
			ret.w = calc_width
		elseif spawn.side == "right" then
			ret.x = CTX.user.conf.width - calc_width
			ret.w = calc_width
		elseif spawn.side == "above" then
			ret.h = calc_height
		elseif spawn.side == "below" then
			ret.y = CTX.user.conf.height - calc_height
			ret.h = calc_height
		else
			error("[Rabbit]: Unknown split mode: " .. spawn.mode)
		end
	end

	if spawn.mode == "float" then
		ret.w = calc_width
		ret.h = calc_height

		if spawn.side == "w" or spawn.side == "c" or spawn.side == "e" then
			ret.y = math.floor((CTX.user.conf.height - calc_height) / 2)
		elseif spawn.side == "sw" or spawn.side == "s" or spawn.side == "se" then
			ret.y = CTX.user.conf.height - calc_height
		end

		if spawn.side == "n" or spawn.side == "c" or spawn.side == "s" then
			ret.x = math.floor((CTX.user.conf.width - calc_width) / 2)
		elseif spawn.side == "ne" or spawn.side == "e" or spawn.side == "se" then
			ret.x = CTX.user.conf.width - calc_width
		end
	end

	return rect.win(rect.calc(ret, win))
end

return UIL
