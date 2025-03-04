---@class (exact) Rabbit.Config.Window.Mode.Float
---@field mode "float"
---@field width integer
---@field height integer
---@field side Rabbit.Config.Window.Float.Spawn

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
---@field side "left" | "right"
---@field width integer

---@class (exact) Rabbit.Config.Window.Mode.Split.Horizontal
---@field mode "split"
---@field side "top" | "bottom"
---@field height integer

---@alias Rabbit.Config.Window.Mode.Split Rabbit.Config.Window.Mode.Split.Vertical | Rabbit.Config.Window.Mode.Split.Horizontal

---@class Rabbit.Config.Window.Mode.Fullscreen
---@field mode "fullscreen"

---@alias Rabbit.Config.Window.Mode Rabbit.Config.Window.Mode.Float | Rabbit.Config.Window.Mode.Split | Rabbit.Config.Window.Mode.Fullscreen

---@class (exact) Rabbit.Config.Window.Titles
---@field title_text string Title text.
---@field title_pos Rabbit.Config.Window.Titles.Position Where to place the title.
---@field plugin_pos Rabbit.Config.Window.Titles.Position Where to place the plugin name.
---@field emphasis_width integer How many emphasis characters to use. eg 5: ===== Rabbit Plugin =====
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

---@class (exact) Rabbit.Config.Window.Overflow
---@field char string String to use when a line overflows. This is not used when trimming dir names with `path_len`.
---@field path_len integer Maximum directory name length before trimming with ellipses.

---@class (exact) Rabbit.Config.Window
---@field box Rabbit.Term.Border Border box style.
---@field spawn Rabbit.Config.Window.Mode Window position.
---@field titles Rabbit.Config.Window.Titles TItle positioning & whatnot.
---@field overflow Rabbit.Config.Window.Overflow How to handle overflow.
