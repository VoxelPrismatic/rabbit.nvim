---@class Rabbit.Message.Preview: Rabbit.Message
---@field type "preview"
---@field file? string File to preview (only necessary if bufid is nil)
---@field bufid? integer Buffer number to preview
---@field winid? integer Window number to preview
---@field jump? Rabbit.Entry.File.Jump The line number and column to highlight
