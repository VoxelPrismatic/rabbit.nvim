local MSG = {
	preview = require("rabbit.messages.preview"),
	rename = require("rabbit.messages.rename"),
	menu = require("rabbit.messages.menu"),
}

function MSG.Handle(data)
	if data.type == nil then
		return
	elseif MSG[data.type] then
		return MSG[data.type](data)
	end

	error("Message type not implemented: " .. vim.inspect(data))
end

return MSG
