---@class Rabbit.Plugin
---@field public evt Rabbit.Plugin.Event Autocmd:Function table
---@field public func Rabbit.Plugin.Functions Extra functions
---@field public switch string Default key pressed to switch to this plugin
---@field public keys Rabbit.Plugin.Keymap `plugin.func` name: key[] map
---@field public name string Plugin name
---@field public listing Rabbit.Plugin.Listing
---@field public empty_msg string Message shown when listing is empty
---@field public color NvimHlKwargs | string Border color
---@field public skip_same boolean Whether or not to skip the first entry if it's the same as the current one
---@field public init function Initializes the plugin
---@field public memory? string If set, Rabbit will make a file, and set `memory` to the file name
---@field public opts? table Plugin specific options


---@class Rabbit.Plugin.Functions
---@field select? fun(integer) Select current entry
---@field close? fun(integer) Close Rabbit window
---@field file_add? fun(integer) Add a file, like in Harpoon
---@field file_del? fun(integer) Delete a file, like in Harpoon
---@field [string] fun(integer)


---@class Rabbit.Plugin.Keymap
---@field select? string[] Keys to select the current entry
---@field close? string[] Keys to close the window
---@field file_add? string[] Keys to add a file, like in Harpoon
---@field file_del? string[] Keys to delete a file, like in Harpoon
---@field [string] string[]


---@class Rabbit.Plugin.Listing
---@field [integer] Rabbit.Plugin.Listing.Window


---@class Rabbit.Plugin.Listing.Window
---@field [integer] integer | string


---@class Rabbit.Plugin.Options
---@field public color? NvimHlKwargs | string
---@field public keys? Rabbit.Plugin.Keymap Any keys used to bind to function names in `plugin.func`
---@field public switch? string Key to switch to this plugin
---@field public opts? table Any plugin specific options


---@class Rabbit.Plugin.Event
---@field BufEnter? Rabbit.Event.Handler Autocmd on BufEnter
---@field BufDelete? Rabbit.Event.Handler Autocmd on BufDelete
---@field RabbitEnter? fun() Called when the Rabbit window is opened
---@field [string] Rabbit.Event.Handler

---@alias Rabbit.Event.Handler fun(evt: NvimEvent, winid: integer)



