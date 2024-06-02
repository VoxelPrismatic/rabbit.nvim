---@class Rabbit.Options
---@field public colors? Rabbit.Options.Color Color scheme
---@field public window? Rabbit.Options.Window Window options
---@field public default_keys? Rabbit.Keymap Default keymaps
---@field public plugin_opts? Rabbit.Options.Plugin_Options Plugin options
---@field public enable? Rabbit.Builtin[] List of builtin plugins to enable


---@class Rabbit.Options.Plugin_Options
---@field [string] Rabbit.Plugin.Options


---@class Rabbit.Options.Window
---@field public title? string Window title
---@field public plugin_name_position? "title" | "bottom" | "hide" Plugin name position
---@field public emphasis_width? integer Width of the emphasis title
---@field public width? integer Window width
---@field public height? integer Window height
---@field public box? Rabbit.Box
---@field public box_style? "round" | "square" | "double" | "thick" Box style
---@field public float? false | FloatingWindow.Offset | FloatingWindow.Anchor Floating window position
---@field public split? false | SplitWindow.Anchor Split window position
---@field public overflow? string Characters to display when the file path is too long
---@field public path_len? integer Maximum length of the file/folder name


---@class Rabbit.Options.Color
---@field public title? NvimHlKwargs | string
---@field public index? NvimHlKwargs | string
---@field public dir? NvimHlKwargs | string
---@field public file? NvimHlKwargs | string
---@field public noname? NvimHlKwargs | string
---@field public term? NvimHlKwargs | string


---@class Rabbit.Box
---@field top_left string Top left corner
---@field top_right string Top right corner
---@field bottom_left string Bottom left corner
---@field bottom_right string Bottom right corner
---@field vertical string Vertical line
---@field horizontal string Horizontal line
---@field emphasis string Emphasis line


---@class Rabbit.Box.Default
---@field [string] Rabbit.Box


---@class FloatingWindow.Offset
---@field public top integer Vertical offset, in lines
---@field public left integer Horizontal offset, in columns


---@class FloatingWindow.Anchor
---@field [1] "top" | "bottom" Vertical anchor
---@field [2] "left" | "right" Horizontal anchor

---@alias Rabbit.Builtin "history" | "oxide" | "reopen"

---@alias SplitWindow.Anchor "above" | "below" | "left" | "right"

---@alias RabbitHlGroup "RabbitDir" | "RabbitFile" | "RabbitBorder" | "RabbitIndex" | "RabbitMode" | "RabbitTitle" | "RabbitNil" | "RabbitTerm"


