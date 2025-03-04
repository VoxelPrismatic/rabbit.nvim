---@alias Color string

---@alias Color.Term
---| "red"
---| "green"
---| "yellow"
---| "blue"
---| "pink"
---| "purple"

---@alias Color.Nvim string | NvimHlKwargs

---@class (exact) Rabbit.Config.Colors.Types
---@field title Color.Nvim Title text color
---@field index Color.Nvim Entry index color, eg "1. "
---@field dir Color.Nvim Directory part color, eg "/home/priz/Desktop/"
---@field file Color.Nvim File name color, eg "init.vim"
---@field term Color.Nvim Terminal shell color, eg "bash" or "zsh"
---@field noname Color.Nvim Buffer with no name

---@class (exact) Rabbit.Config.Colors.Paint
---@field rose Color.Nvim Pink
---@field love Color.Nvim Red
---@field gold Color.Nvim Yellow
---@field tree Color.Nvim Green
---@field foam Color.Nvim Light Blue
---@field iris Color.Nvim Deep Blue
---@field pine Color.Nvim Navy

---@class (exact) Rabbit.Config.Colors.Popup
---@field error Color.Nvim Error message
---@field warning Color.Nvim Warning message
---@field info Color.Nvim Info message

---@class (exact) Rabbit.Config.Colors
---@field types Rabbit.Config.Colors.Types Highlight different parts of each entry.
---@field paint Rabbit.Config.Colors.Paint Colors to use for your collections. Will pull from rose-pine or the background colors from highlight groups when possible
---@field popup Rabbit.Config.Colors.Popup Colors for popup boxes.
