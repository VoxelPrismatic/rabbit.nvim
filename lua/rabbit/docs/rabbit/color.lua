---@alias Color string

---@alias Color.Term
---| "rose"
---| "love"
---| "gold"
---| "tree"
---| "foam"
---| "iris"
---| "pine"

---@alias Color.Nvim string | NvimHlKwargs

---@class (exact) Rabbit.Config.Colors.Types
---@field title Color.Nvim Title text color
---@field index Color.Nvim Entry index color, eg "1. "
---@field tail Color.Nvim Default tail color, eg buffer number or terminal PID
---@field head Color.Nvim Default head color, whatever prefixes the entry label
---@field collection Color.Nvim Default collection color

---@class (exact) Rabbit.Config.Colors.Files
---@field path Color.Nvim Directory part color, eg "/home/user/Desktop/"
---@field file Color.Nvim File name color, eg "init.vim"
---@field term Color.Nvim Terminal shell color, eg "bash" or "zsh"
---@field void Color.Nvim Buffer with no name
---@field closed Color.Nvim Buffer that has been closed

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
---@field files Rabbit.Config.Colors.Files Colors for different types of files
---@field paint Rabbit.Config.Colors.Paint Colors to use for your collections. Will pull from rose-pine or the background colors from highlight groups when possible
---@field marks Rabbit.Config.Colors.Paint Colors to use for your collections. Will pull from rose-pine or the background colors from highlight groups when possible
---@field popup Rabbit.Config.Colors.Popup Colors for popup boxes.
---@field lsp Rabbit.Config.Colors.Lsp Colors for lsp info

---@class (exact) Rabbit.Config.Colors.Lsp
---@field hint Color.Nvim LSP level 'Hint'
---@field info Color.Nvim LSP level 'Info'
---@field warn Color.Nvim LSP level 'Warn'
---@field error Color.Nvim LSP level 'Error'

---@alias Rabbit.Colors.Paint
---| "rose" # Pink
---| "love" # Red
---| "gold" # Yellow
---| "tree" # Green
---| "foam" # Light Blue
---| "iris" # Deep Blue
---| "pine" # Navy
