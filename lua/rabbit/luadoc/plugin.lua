---@meta

---@class (exact) Rabbit.Plugin
---@field public evt Rabbit.Plugin.Event Autocmd:Function table
---@field public func Rabbit.Plugin.Functions Extra functions
---@field public switch string Default key pressed to switch to this plugin
---@field public keys Rabbit.Plugin.Keymap `plugin.func` name: key[] map
---@field public name string Plugin name
---@field public listing Rabbit.Plugin.Listing
---@field public empty_msg string Message shown when listing is empty
---@field public color NvimHlKwargs | string Border color
---@field public skip_same boolean Whether or not to skip the first entry if it's the same as the current one
---@field public init fun(p: Rabbit.Plugin) Initializes the plugin
---@field public memory? string If set, Rabbit will make a file, and set `memory` to the file name
---@field public opts? table Plugin specific options


---@alias Rabbit.plugin.default_store
---| "bufnr" # Rabbit will automatically add the buffer ID to new window listings
---| "filename" # Rabbit will automatically add the filename to new window listings
---| "custom" # Rabbit will not add anything to new window listings
---| fun(evt: NvimEvent, winid: integer) -> any # Custom function to add to new window listings


---@class Rabbit.Plugin.Functions
---@field select? fun(integer) Select current entry
---@field close? fun(integer) Close Rabbit window
---@field file_add? fun(integer) Add a file, like in Harpoon
---@field file_del? fun(integer) Delete a file, like in Harpoon
---@field group? fun(integer) Create a collection of files
---@field group_up? fun(integer) Move up a collection
---@field [string] fun(integer)


---@class Rabbit.Plugin.Keymap
---@field select? string[] Keys to select the current entry
---@field close? string[] Keys to close the window
---@field file_add? string[] Keys to add a file, like in Harpoon
---@field file_del? string[] Keys to delete a file, like in Harpoon
---@field group? string[] Keys to create a collection of files
---@field group_up? string[] Keys to move up a collection
---@field [string] string[]


---@class Rabbit.Plugin.Listing
---@field [0] Rabbit.Plugin.Listing.Window Listing shown to the user
---@field persist? Rabbit.Plugin.Listing.Persist Internal persistent listing
---@field opened? Rabbit.Plugin.Listing.Window Tracks open files
---@field collections? Rabbit.Plugin.Listing.Persist.Recursive Tracks collections
---@field recursive? Rabbit.Plugin.Listing.Persist.Recursive
---@field paths? Rabbit.Plugin.Listing.Persist.Table[]
---@field [integer] Rabbit.Plugin.Listing.Window
---@field [string] Rabbit.Plugin.Listing.Window


---@class Rabbit.Plugin.Listing.Window
---@field [integer] integer | string


---@class (exact) Rabbit.Plugin.Options
---@field public color? NvimHlKwargs | string
---@field public keys? Rabbit.Plugin.Keymap Any keys used to bind to function names in `plugin.func`
---@field public switch? string Key to switch to this plugin
---@field public opts? table Any plugin specific options


---@class (exact) Rabbit.Plugin.Options.History
---@field public color? NvimHlKwargs | string
---@field public keys? Rabbit.Plugin.Keymap Any keys used to bind to function names in `plugin.func`
---@field public switch? string Key to switch to this plugin
---@field public opts? Rabbit.Plugin.History.Options Any plugin specific options


---@class (exact) Rabbit.Plugin.Options.Oxide
---@field public color? NvimHlKwargs | string
---@field public keys? Rabbit.Plugin.Keymap Any keys used to bind to function names in `plugin.func`
---@field public switch? string Key to switch to this plugin
---@field public opts? Rabbit.Plugin.Oxide.Options Any plugin specific options


---@class (exact) Rabbit.Plugin.Options.Harpoon
---@field public color? NvimHlKwargs | string
---@field public keys? Rabbit.Plugin.Keymap Any keys used to bind to function names in `plugin.func`
---@field public switch? string Key to switch to this plugin
---@field public opts? Rabbit.Plugin.Harpoon.Options Any plugin specific options


---@class (exact) Rabbit.Plugin.Options.Reopen
---@field public color? NvimHlKwargs | string
---@field public keys? Rabbit.Plugin.Keymap Any keys used to bind to function names in `plugin.func`
---@field public switch? string Key to switch to this plugin


---@alias Rabbit.Event.Handler fun(evt: NvimEvent, winid: integer)


---@class Rabbit.Plugin.Listing.Persist
---@field [string] Rabbit.Plugin.Listing.Persist.Table `Directory Name : Table` table


---@class Rabbit.Plugin.Listing.Persist.Table
---@field [integer] string Just the filename; no Oxide details
---@field [string] Rabbit.Plugin.Listing.Persist.Entry | Rabbit.Plugin.Listing.Persist.Table `File Name : Entry` table


---@class Rabbit.Plugin.Listing.Persist.Entry
---@field age integer The last time the file was accessed
---@field count integer The total number of times this file was accessed


---@alias Rabbit.Plugin.Listing.Persist.Recursive
---| Rabbit.Plugin.Listing.Persist
---| Rabbit.Plugin.Listing.Persist.Table
---| Rabbit.Plugin.Listing.Persist.Entry
