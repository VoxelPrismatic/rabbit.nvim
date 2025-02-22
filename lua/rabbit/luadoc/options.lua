---@class Rabbit.Options
---@field public colors? Rabbit.Options.Color Color scheme
---@field public window? Rabbit.Options.Window Window options
---@field public default_keys? Rabbit.Keymap Default keymaps
---@field public plugin_opts? Rabbit.Options.Plugin_Options Plugin options
---@field public enable? Rabbit.Builtin[] List of builtin plugins to enable
---@field public path_key? string|function:string Function to scope your working directory (default: vim.fn.getcwd)


---@class Rabbit.Options.Plugin_Options
---@field history? Rabbit.Plugin.Options.History
---@field oxide? Rabbit.Plugin.Options.Oxide
---@field reopen? Rabbit.Plugin.Options.Reopen
---@field harpoon? Rabbit.Plugin.Options.Harpoon
---@field [string] Rabbit.Plugin.Options


---@class Rabbit.Options.Window
---@field public title? string Window title
---@field public plugin_name_position? "title" | "bottom" | "hide" Plugin name position
---@field public emphasis_width? integer Width of the emphasis title
---@field public width? integer Window width
---@field public height? integer Window height
---@field public box? Rabbit.Box
---@field public box_style? "round" | "square" | "double" | "thick" Box style
---@field public float? false | FloatingWindow.Offset | FloatingWindow.Anchor | "center" Floating window position
---@field public split? false | SplitWindow.Anchor Split window position
---@field public overflow? string Characters to display when the file path is too long
---@field public path_len? integer Maximum length of the file/folder name


---@class Rabbit.Options.Color
---@field public title? NvimHlKwargs | string Window title
---@field public index? NvimHlKwargs | string List entry index number
---@field public dir? NvimHlKwargs | string Directory portion of entry
---@field public file? NvimHlKwargs | string File portion of entry
---@field public noname? NvimHlKwargs | string Displayed when the buffer has no filename
---@field public term? NvimHlKwargs | string Displayed when the buffer is a terminal
---@field public message? NvimHlKwargs | string Message
---@field public popup? Rabbit.Options.Color.Popup Popup colors


---@class Rabbit.Options.Color.Popup
---@field public error NvimHlKwargs | string
---@field public warning NvimHlKwargs | string
---@field public info NvimHlKwargs | string


---@class Rabbit.Box
---@field public top_left string Top left corner
---@field public top_right string Top right corner
---@field public bottom_left string Bottom left corner
---@field public bottom_right string Bottom right corner
---@field public vertical string Vertical line
---@field public horizontal string Horizontal line
---@field public emphasis string Emphasis line


---@class Rabbit.Box.Default
---@field [string] Rabbit.Box


---@class FloatingWindow.Offset
---@field top integer Vertical offset, in lines
---@field left integer Horizontal offset, in columns


---@class FloatingWindow.Anchor
---@field [1] "top" | "bottom" Vertical anchor
---@field [2] "left" | "right" Horizontal anchor

---@alias Rabbit.Builtin
---| "history" # History plugin
---| "oxide" # Oxide plugin
---| "reopen" # Reopen plugin
---| "harpoon" # Harpoon plugin


---@alias SplitWindow.Anchor
---| "above" # Create split above current window
---| "below" # Create split below current window
---| "left" # Create split to the left of current window
---| "right" # Create split to the right of current window


---@alias RabbitHlGroup
---| "RabbitDir" # Color of the directory portion of an entry
---| "RabbitFile" # Color of the file portion of an entry
---| "RabbitBorder" # Color of the border of the window
---| "RabbitIndex" # Color of the entry index number
---| "RabbitTitle" # Color of the window title
---| "RabbitNil" # Color of Blank Filename
---| "RabbitTerm" # Color of extras, eg :term or :Oil
---| "RabbitMsg" # Color of messages
---| "RabbitPopupErr" # Color of the error message box border
---| "RabbitPopupWarn" # Color of the warning message box border
---| "RabbitPopupInfo" # Color of the info message box border
---| "RabbitInput" # Color of the input prompt background


