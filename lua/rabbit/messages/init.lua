--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

local MSG = {
	preview = require("rabbit.messages.preview"),
	rename = require("rabbit.messages.rename"),
	menu = require("rabbit.messages.menu"),
	color = require("rabbit.messages.color"),
	close = require("rabbit.messages.close"),
	redraw = require("rabbit.messages.redraw"),
}

function MSG.Handle(data)
	if data.type == nil then
		return
	elseif MSG[data.type] then
		return MSG[data.type](data)
	end

	local ok, callback = pcall(require, "rabbit.messages." .. data.type)
	if ok then
		vim.notify("Loaded message type: " .. data.type, vim.log.levels.WARN)
		MSG[data.type] = callback
		return callback(data)
	end

	error("Message type not implemented: " .. vim.inspect(data))
end

return MSG
