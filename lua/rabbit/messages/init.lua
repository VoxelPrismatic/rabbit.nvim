local MSG = {
	preview = require("rabbit.messages.preview"),
	rename = require("rabbit.messages.rename"),
	menu = require("rabbit.messages.menu"),
	color = require("rabbit.messages.color"),
	close = require("rabbit.messages.close"),
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
