---@class (exact) Rabbit.Config.Window.Mode.Float
---@field mode "float"
---@field width number Window width; automatically shrunk to fit window; if <1, it is a percentage.
---@field height number Window height; automatically shrunk to fit window; if <1, it is a percentage.
---@field side Rabbit.Config.Window.Float.Spawn Where to spawn the floating window.

---@alias Rabbit.Config.Window.Float.Spawn # Where to span the floating window
---| "nw" # Top left
---| "n" # Top center
---| "ne" # Top right
---| "e" # Right middle
---| "se" # Bottom right
---| "s" # Bottom center
---| "sw" # Bottom left
---| "w" # Left middle
---| "c" # Center middle

---@class (exact) Rabbit.Config.Window.Mode.Split.Vertical
---@field mode "split"
---@field side "left" | "right" Where to split
---@field width integer Window width; automatically shrunk to fit window; if <1, it is a percentage

---@class (exact) Rabbit.Config.Window.Mode.Split.Horizontal
---@field mode "split"
---@field side "above" | "below" Where to split
---@field height integer Window height; automatically shrunk to fit window; if <1, it is a percentage

---@alias Rabbit.Config.Window.Mode.Split Rabbit.Config.Window.Mode.Split.Vertical | Rabbit.Config.Window.Mode.Split.Horizontal

---@class Rabbit.Config.Window.Mode.Fullscreen
---@field mode "fullscreen" This is the same as float:nw with massive width and height

---@alias Rabbit.Config.Window.Mode Rabbit.Config.Window.Mode.Float | Rabbit.Config.Window.Mode.Split | Rabbit.Config.Window.Mode.Fullscreen

---@class (exact) Rabbit.Config.Window.Titles
---@field title_text string Title text.
---@field title_pos Rabbit.Config.Window.Titles.Position Where to place the title.
---@field title_emphasis Rabbit.Config.Window.Titles.Emphasis Emphasis characters to place around the title; if plugin and title use the same position, they are joined by title.right and end with plugin.right
---@field plugin_pos Rabbit.Config.Window.Titles.Position Where to place the plugin name.
---@field plugin_emphasis Rabbit.Config.Window.Titles.Emphasis Emphasis characters to place around the plugin name
---@field title_case "title" | "upper" | "lower" | "unchanged"
---@field plugin_case "title" | "upper" | "lower" | "unchanged" Unused if the plugin and title use the same position.
---@see Rabbit.Term.Border

---@alias Rabbit.Config.Window.Titles.Position # Where to place the title text
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

---@class (exact) Rabbit.Config.Window.Titles.Emphasis
---@field left string Left-hand (or top-side) emphasis string
---@field right string Right-hand (or bottom-side) emphasis string

---@class (exact) Rabbit.Config.Window.Overflow
---@field distance_char string String to use when a line overflows.
---@field dirname_trim integer Maximum directory name length before trimming with `dirname_char`.
---@field dirname_char string Character to use when trimming dir names.
---@field distance_trim integer Maximum distance between files before trimming with `distance_char`.

---@class (exact) Rabbit.Config.Window
---@field box Rabbit.Term.Border Border box style.
---@field spawn Rabbit.Config.Window.Mode Window position.
---@field titles Rabbit.Config.Window.Titles | Rabbit.Term.Border.Side[] Title positioning & whatnot.
---@field overflow Rabbit.Config.Window.Overflow How to handle overflow.
---@field legend boolean Show a quick legend at the bottom. Consumes one line.
---@field extras Rabbit.Config.Window.Extras Extra info
---@field preview true Whether or not to display a preview of the buffer about to be opened
---@field icons Rabbit.Config.Window.Icons Icons for various things

---@class (exact) Rabbit.Config.Window.Extras
---@field nrs boolean Whether or not to show BufIDs, WinIDs, term PIDs, etc.
---@field readonly boolean Whether or not to show if the buffer is read-only.
---@field lsp Rabbit.Config.Window.Extras.Lsp | Rabbit.Config.Window.Extras.Lsp.Callback Whether or not to show lsp info.
---@field modified boolean Whether or not to show if the buffer has been modified.

---@class (exact) Rabbit.Config.Window.Extras.Lsp
---@field hint Rabbit.Config.Window.Extras.Lsp.Callback LSP level 'Hint'
---@field info Rabbit.Config.Window.Extras.Lsp.Callback LSP level 'Info'
---@field warn Rabbit.Config.Window.Extras.Lsp.Callback LSP level 'Warn'
---@field error Rabbit.Config.Window.Extras.Lsp.Callback LSP level 'Error'

---@alias Rabbit.Config.Window.Extras.Lsp.Callback boolean | fun(data: vim.Diagnostic): boolean

---@class (exact) Rabbit.Config.Window.Icons
---@field modified string Icon for modified buffers.
---@field readonly string Icon for read-only buffers.
---@field lsp_error string Icon for LSP errors.
---@field lsp_info string Icon for LSP info.
---@field lsp_warn string Icon for LSP warnings.
---@field lsp_hint string Icon for LSP help.
