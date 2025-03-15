---@class (exact) Rabbit.Term.Border.Box
---@field ne string Top right corner (┐).
---@field se string Bottom right corner (┘).
---@field nw string Top left corner (┌).
---@field sw string Bottom left corner (└).
---@field v string Vertical line (│).
---@field h string Horizontal line (─).
---@field scroll string Scrollbar position character (┇). Not available if the right side is used by the title or plugin name.

---@alias Rabbit.Term.Border.String string Specified as "┌┐└┘─│═┇"

---@alias Rabbit.Enum.Border.Weight # Border weight
---| "thin" # ┌─┐
---| "bold" # ┏━┓
---| "double" # ╔═╗

---@alias Rabbit.Enum.Border.Stroke # Stroke style; solid if weight is "double"
---| "solid" # ─│
---| "dash" # ┄┆
---| "dot" # ┈┊
---| "double" # ╌╎

---@alias Rabbit.Enum.Border.Corner # Corner style
---| "square" # ┌┐
---| "round" # ╭╮

---@class (exact) Rabbit.Term.Border.Custom.Extras.Positional
---@field [1] Rabbit.Enum.Border.Weight Line weight
---@field [2] Rabbit.Enum.Border.Stroke Stroke style; Falls back to "solid" if weight is "double."

---@class (exact) Rabbit.Term.Border.Custom.Extras.Kwargs
---@field weight Rabbit.Enum.Border.Weight Line weight
---@field stroke Rabbit.Enum.Border.Stroke Stroke style; Falls back to "solid" if weight is "double."

---@alias Rabbit.Term.Border.Custom.Extras
---| Rabbit.Term.Border.Custom.Extras.Positional
---| Rabbit.Term.Border.Custom.Extras.Kwargs

---@class (exact) Rabbit.Term.Border.Custom.Kwargs
---@field corner Rabbit.Enum.Border.Corner Corner style; Falls back to "square" if weight is NOT "thin."
---@field weight Rabbit.Enum.Border.Weight Line weight.
---@field stroke Rabbit.Enum.Border.Stroke Stroke style; Falls back to "solid" if weight is "double."
---@field scrollbar Rabbit.Term.Border.Custom.Extras | string Scrollbar position character; If table, will use vertical line. Not available if the right side is used by the title or plugin name.

---@class (exact) Rabbit.Term.Border.Custom.Positional
---@field [1] Rabbit.Enum.Border.Corner Corner style; Falls back to "square" if weight is NOT "thin."
---@field [2] Rabbit.Enum.Border.Weight Line weight.
---@field [3] Rabbit.Enum.Border.Stroke Stroke style; Falls back to "solid" if weight is "double."
---@field [4] Rabbit.Term.Border.Custom.Extras | string Scrollbar position character; If table, will use vertical line. Not available if the right side is used by the title or plugin name.
---
---@class (exact) Rabbit.Term.Border.Side
---@field align Rabbit.Config.Window.Titles.Position
---@field text? string Main text
---@field pre? string Prefix
---@field suf? string Suffix
---@field make? fun(size: integer, text: string): string, string, string Function to call to make the side

---@class (exact) Rabbit.Term.Border.Applied
---@field t Rabbit.Term.Border.Applied.Side Top side
---@field b Rabbit.Term.Border.Applied.Side Bottom side
---@field r Rabbit.Term.Border.Applied.Side Right side
---@field l Rabbit.Term.Border.Applied.Side Left side

---@class (exact) Rabbit.Term.Border.Applied.Side
---@field txt string[] Text characters
---@field hl integer[] Main text highlight indexes

---@alias Rabbit.Term.Border.Custom
---| Rabbit.Term.Border.Custom.Positional
---| Rabbit.Term.Border.Custom.Kwargs

---@alias Rabbit.Term.Border
---| Rabbit.Term.Border.Box
---| Rabbit.Term.Border.Custom
---| Rabbit.Term.Border.String
