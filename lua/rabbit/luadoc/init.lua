---@class Rabbit.Keymap
---@field public open string[] Keys to open the window
---@field public select string[] Keys to select the current entry
---@field public close string[] Keys to close the window
---@field public file_add string[] Keys to add a file, like in Harpoon
---@field public file_del string[] Keys to delete a file, like in Harpoon
---@field public group string[] Keys to create a collection of files
---@field public group_up string[] Keys to move up a collection
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


---@class (exact) Rabbit.Context
---@field plugin Rabbit.Plugin | nil Active plugin
---@field listing Rabbit.Plugin.Listing.Window
---@field buffer? Rabbit.Context.Buffer Buffer details


---@class (exact) Rabbit.Context.Buffer
---@field nr integer Buffer ID
---@field w integer Window width
---@field h integer Window height
---@field fs boolean | Rabbit.Screen.Spec Fullscreen
---@field pos integer Cursor position; 0 if fullscreen; length of vertical wall otherwise


---@class Rabbit.Plugin_Table
---@field [string] Rabbit.Plugin


---@class (exact) Rabbit.Workspace
---@field win integer | nil Window ID
---@field buf integer | nil Buffer ID
---@field ns integer Highlight Namespace ID
---@field view? vim.fn.winsaveview.ret Window viewport details
---@field conf? vim.api.keyset.win_config Window configuration details


---@class Rabbit.Compat
---@field [string] Rabbit.Compat.Entry Compatibility entry


---@class (exact) Rabbit.Compat.Entry
---@field path string Directory separator. Linux and macOS use `/`
---@field warn boolean Whether or not to warn about compatibility issues
---@field name string OS Name
---@field has string[] List of names under vim.fn.has(...)


