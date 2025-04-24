local UI = require("rabbit.term.listing")

---@param data Rabbit.Message.Redraw
return function(data)
	UI.redraw_entry(data.entry)
end
