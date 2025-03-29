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
---@field align Rabbit.Config.Boxes.Titles.Position
---@field text? string | fun(): string Main text
---@field pre? string Prefix
---@field suf? string Suffix
---@field make? fun(size: integer, text: string): string, string, string Function to call to make the side

---@class (exact) Rabbit.Term.Border.Generic<T>: { b: T, t: T, l: T, r: T }

---@class (exact) Rabbit.Term.Border.Applied: Rabbit.Term.Border.Generic<Rabbit.Term.Border.Side>
---@field top_left string Top left character.
---@field bot_left string Bottom left character.
---@field top_right string Top right character.
---@field bot_right string Bottom right character.
---@field to_hl fun(self: Rabbit.Term.Border.Applied, kwargs: Rabbit.Term.Border.Applied.Hl.Kwargs): Rabbit.Term.Border.Applied.Hl Convert to highlight lines

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

---@alias Rabbit.Config.Boxes.Titles.Position # Where to place the title text
---| "ne" # Top right.
---| "n" # Top center.
---| "nw" # Top left.
---| "se" # Bottom right.
---| "s" # Bottom center.
---| "sw" # Bottom left.
---| "wn" # Left top. (Vertical text)
---| "w" # Left center. (Vertical text)
---| "ws" # Left bottom. (Vertical text)
---| "en" # Right top. (Vertical text)
---| "e" # Right center. (Vertical text)
---| "es" # Right bottom. (Vertical text)
---| "nil" # No title.

---@class (exact) Rabbit.Term.Border.Config
---@field top_left string Top left corner character.
---@field top_side string | Rabbit.Term.Border.Config.Side Top side text.
---@field top_right string Top right corner character.
---@field right_side string | Rabbit.Term.Border.Config.Side Right side text.
---@field bot_left string Bottom left corner character.
---@field bot_side string | Rabbit.Term.Border.Config.Side Bottom side text.
---@field bot_right string Bottom right corner character.
---@field left_side string | Rabbit.Term.Border.Config.Side Left side text.
---@field chars? Rabbit.Term.Border.Chars Extra characters
---@field parts? { [string]: Rabbit.Term.Border.Config.Part } Custom parts used to complete the parts on each side.

---@class (exact) Rabbit.Term.Border.Config.Side
---@field base string Base character
---@field left? Rabbit.Term.Border.Config.Align Left/top aligned text. Be careful, this may be overwritten by other alignments.
---@field right? Rabbit.Term.Border.Config.Align Right/bottom aligned text. Be careful, this may be overwritten by other alignments.
---@field center? Rabbit.Term.Border.Config.Align Center aligned text. Be careful, this may be overwritten by other alignments.

---@class (exact) Rabbit.Term.Border.Config.Align
---@field parts string | string[] Parts to print.
---@field join? string Join text between multiple parts.
---@field case? Rabbit.Enum.Case Apply case to the text
---@field prefix? string Prefix. This will be treated as part of the border text.
---@field suffix? string Suffix. This will be treated as part of the border text.
---@field build? fun(self: Rabbit.Term.Border.Config.Align, size: integer, text: string) Update the prefix and suffix based on the built text and size of the side

---@class (exact) Rabbit.Config.Boxes
---@field rabbit Rabbit.Term.Border.Config Title box
---@field preview Rabbit.Term.Border.Config Preview box
---@field popup? Rabbit.Term.Border.Config Popup box

---@class (exact) Rabbit.Term.Border.Chars
---@field rise string Left-side rise character.
---@field emphasis string Emphasis character.
---@field scroll string Scrollbar position character.

---@alias Rabbit.Term.Border.Config.Part
---| string # String literal
---| fun(): (string, boolean) # Function to call to produce text. Boolean:True = highlight as title. Boolean:False = highlight as border.
---| { [1]: string, [2]: boolean } # Unpacked to produce the same result as the function call.

---@alias Rabbit.Enum.Case
---| "unchanged" # No change.
---| "lower" # lower case.
---| "upper" # UPPER CASE.
---| "title" # Title Case.
