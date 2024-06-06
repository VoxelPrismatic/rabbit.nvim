---@class Rabbit.Keymap
---@field public open? string[] Keys to open the window
---@field public select? string[] Keys to select the current entry
---@field public close? string[] Keys to close the window
---@field public file_add? string[] Keys to add a file, like in Harpoon
---@field public file_del? string[] Keys to delete a file, like in Harpoon
---@field [string] string[]


---@class Rabbit.Instance
---@field rabbit Rabbit.Workspace Rabbit's workspace
---@field user Rabbit.Workspace User's workspace
---@field ctx Rabbit.Context Context
---@field opts Rabbit.Options Rabbit options
---@field func Rabbit.Instance.Functions
---@field plugins Rabbit.Plugin_Table Loaded plugins
---@field compat Rabbit.Compat.Entry Compatibility table
---@field default string Default plugin


---@class Rabbit.Instance.Functions
---@field select fun(integer) Select current entry
---@field close fun(integer) Close Rabbit window


---@class Rabbit.Context
---@field plugin Rabbit.Plugin | nil Active plugin
---@field listing Rabbit.Plugin.Listing.Window

---@class Rabbit.Plugin_Table
---@field [string] Rabbit.Plugin


---@class Rabbit.Workspace
---@field win integer | nil Window ID
---@field buf integer | nil Buffer ID
---@field ns integer Highlight Namespace ID


---@class Rabbit.Compat
---@field [string] Rabbit.Compat.Entry Compatibility entry


---@class Rabbit.Compat.Entry
---@field path string Directory separator. Linux and macOS use `/`
---@field warn boolean Whether or not to warn about compatibility issues
---@field __name__ string OS Name
---@field __has__ string[] List of names under vim.fn.has(...)
