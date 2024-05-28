---@class NvimHlKwargs
---@field fg? string Foreground color name or "#RRGGBB"
---@field bg? string Background color name or "#RRGGBB"
---@field sp? string Space color name or "#RRGGBB"
---@field blend? integer Opacity between 0 and 100
---@field bold? boolean **Bold** text
---@field standout? boolean
---@field underline? boolean __Underline__ text
---@field undercurl? boolean __Underline__, but curled like misspelled words
---@field underdouble? boolean __Underline__, but double underline
---@field underdotted? boolean __Underline__, but dotted underline
---@field underdashed? boolean __Underline__, but dashed underline
---@field strikethrough? boolean ~~Strike~~
---@field italic? boolean *Italic* text
---@field reverse? boolean Reverse FG and BG
---@field nocombine? boolean
---@field link? string Link to another highlight group name
---@field default? boolean Don't override existing definition
---@field ctermfg? string Sets foreground of cterm color
---@field ctermbg? string Sets background of cterm color
---@field cterm? NvimHlKwargs cterm attr map
---@field force? boolean Update the highlight group if it exists


---@class RabbitBox
---@field top_left string Top left corner
---@field top_right string Top right corner
---@field bottom_left string Bottom left corner
---@field bottom_right string Bottom right corner
---@field vertical string Vertical line
---@field horizontal string Horizontal line
---@field emphasis string Emphasis line


---@class DefaultRabbitBox
---@field [string] RabbitBox


---@class RabbitOptions
---@field colors RabbitOptsColor Color scheme
---@field window RabbitOptsWindow Window options
---@field default_keys RabbitKeymap Default keymaps
---@field plugin_opts RabbitPluginOptTbl Plugin options
---@field enable RabbitBuiltin[] List of builtin plugins to enable


---@class RabbitPluginOptTbl
---@field [string] RabbitPluginOpts

---@alias RabbitBuiltin "history" | "oxide" | "reopen"


---@class RabbitOptsWindow
---@field title string Window title
---@field plugin_name_position "title" | "bottom" | "hide" Plugin name position
---@field emphasis_width integer Width of the emphasis title
---@field width integer Window width
---@field height integer Window height
---@field box RabbitBox
---@field box_style? "round" | "square" | "double" | "thick" Box style
---@field float false | FloatingWindowOffset | FloatingWindowAnchor Floating window position
---@field split false | SplitAnchor Split window position
---@field overflow string Characters to display when the file path is too long
---@field path_len integer Maximum length of the file/folder name


---@class FloatingWindowOffset
---@field top integer Vertical offset, in lines
---@field left integer Horizontal offset, in columns


---@class FloatingWindowAnchor
---@field [1] "top" | "bottom" Vertical anchor
---@field [2] "left" | "right" Horizontal anchor


---@alias SplitAnchor "above" | "below" | "left" | "right"


---@class RabbitOptsColor
---@field title NvimHlKwargs | string
---@field index NvimHlKwargs | string
---@field dir NvimHlKwargs | string
---@field file NvimHlKwargs | string
---@field noname NvimHlKwargs | string
---@field term NvimHlKwargs | string



---@class RabbitPluginOpts
---@field color NvimHlKwargs | string
---@field keys RabbitPluginKeymap Any keys used to bind to function names in `plugin.func`
---@field switch string Key to switch to this plugin
---@field opts table Any plugin specific options


---@class RabbitKeymap
---@field open? string[] Keys to open the window
---@field select? string[] Keys to select the current entry
---@field close? string[] Keys to close the window
---@field file_add? string[] Keys to add a file, like in Harpoon
---@field file_del? string[] Keys to delete a file, like in Harpoon
---@field [string] string[]


---@class ScreenSetBorderKwargs
---@field colors RabbitOptsColor
---@field border_color NvimHlKwargs | string
---@field width integer
---@field height integer
---@field emph_width integer
---@field box RabbitBox
---@field fullscreen boolean
---@field title string
---@field mode string


---@class ScreenSpec
---@field [integer] ScreenSpec
---@field color RabbitHlGroup Highlight group name
---@field text string | string[] Text to render
---@field expand? boolean | string Expand to full width


---@alias RabbitHlGroup "RabbitDir" | "RabbitFile" | "RabbitBorder" | "RabbitIndex" | "RabbitMode" | "RabbitTitle" | "RabbitNil" | "RabbitTerm"


---@class RabbitPlugin
---@field evt RabbitPluginEvent Autocmd:Function table
---@field func RabbitPluginFuncs Extra functions
---@field switch string Default key pressed to switch to this plugin
---@field keys RabbitPluginKeymap `plugin.func` name: key[] map
---@field name string Plugin name
---@field listing RabbitPluginListing
---@field empty_msg string Message shown when listing is empty
---@field color NvimHlKwargs | string Border color
---@field skip_same boolean Whether or not to skip the first entry if it's the same as the current one
---@field init function Initializes the plugin
---@field memory? string If set, Rabbit will make a file, and set `memory` to the file name
---@field opts? table Plugin specific options


---@class RabbitPluginEvent
---@field BufEnter? RabbitEvtHandler Autocmd on BufEnter
---@field BufDelete? RabbitEvtHandler Autocmd on BufDelete
---@field RabbitEnter? function Called when the Rabbit window is opened
---@field [string] RabbitEvtHandler

---@alias RabbitEvtHandler function(evt: NvimEvent, winid: integer)

---@class NvimEvent
---@field buf integer Buffer ID
---@field event string Event type
---@field file string File name
---@field id integer Event ID
---@field match string


---@class RabbitPluginFuncs
---@field select? function(integer) Select current entry
---@field close? function(integer) Close Rabbit window
---@field file_add? function(integer) Add a file, like in Harpoon
---@field file_del? function(integer) Delete a file, like in Harpoon
---@field [string] function(integer)


---@class RabbitPluginKeymap
---@field select? string[] Keys to select the current entry
---@field close? string[] Keys to close the window
---@field file_add? string[] Keys to add a file, like in Harpoon
---@field file_del? string[] Keys to delete a file, like in Harpoon
---@field [string] string[]


---@class RabbitPluginListing
---@field [integer] RabbitPluginWinListing


---@class RabbitPluginWinListing
---@field [integer] integer | string


---@class RabbitInstance
---@field rabbit RabbitWorkspace Rabbit's workspace
---@field user RabbitWorkspace User's workspace
---@field ctx RabbitContext Context
---@field opts RabbitOptions Rabbit options
---@field func RabbitPluginFuncs
---@field plugins RabbitPluginTable Loaded plugins
---@field compat RabbitCompatEntry Compatibility table
---@field default string Default plugin


---@class RabbitContext
---@field plugin RabbitPlugin | nil Active plugin
---@field listing RabbitPluginWinListing

---@class RabbitPluginTable
---@field [string] RabbitPlugin


---@class RabbitWorkspace
---@field win integer | nil Window ID
---@field buf integer | nil Buffer ID
---@field ns integer Highlight Namespace ID


---@class RabbitCompat
---@field [string] RabbitCompatEntry Compatibility entry


---@class RabbitCompatEntry
---@field path string Directory separator. Linux and macOS use `/`
---@field warn boolean Whether or not to warn about compatibility issues
---@field __name__ string OS Name
---@field __has__ string[] List of names under vim.fn.has(...)
