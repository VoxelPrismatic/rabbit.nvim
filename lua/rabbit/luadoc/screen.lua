---@class (exact) Rabbit.Screen.Border_Kwargs
---@field colors Rabbit.Options.Color
---@field border_color NvimHlKwargs | string
---@field width integer Window width
---@field height integer Window height
---@field emph_width integer Emphasis character width
---@field box Rabbit.Box Box style
---@field fullscreen boolean Full screen
---@field title string Window title
---@field mode string Plugin name
---@field pos_col integer Window position: column
---@field pos_row integer Window position: row


---@class Rabbit.Screen.Spec
---@field [integer] Rabbit.Screen.Spec
---@field color RabbitHlGroup | string Highlight group name
---@field text string | string[] Text to render
---@field expand? boolean | string Expand to full width


---@class Rabbit.Input.Menu.Entry.Named
---@field text string Menu item text
---@field callback function Callback when selected
---@field color? RabbitHlGroup | string Highlight group
---@field hidden? boolean Do not display


---@class Rabbit.Input.Menu.Entry.Positional
---@field [1] string Menu item text
---@field [2] function Callback when selected
---@field [3]? RabbitHlGroup | string Highlight group
---@field [4]? boolean Do not display


---@alias Rabbit.Input.Menu.Entry
---| Rabbit.Input.Menu.Entry.Named
---| Rabbit.Input.Menu.Entry.Positional
