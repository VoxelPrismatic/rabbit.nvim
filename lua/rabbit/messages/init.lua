local MSG = {
	preview = require("rabbit.messages.preview"),
	rename = require("rabbit.messages.rename"),
}

function MSG.Handle(data)
	if MSG[data.type] then
		return MSG[data.type](data)
	end

	error("Message type not implemented: " .. vim.inspect(data))
end

return MSG
