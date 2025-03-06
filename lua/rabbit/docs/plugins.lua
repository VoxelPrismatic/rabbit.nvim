---@class Rabbit.Plugin
---@field act Rabbit.Listing.Actions Action callbacks
---@field evt Rabbit.Plugin.Events NvimEvent Callbacks
---@field opts Rabbit.Plugin.Options Plugin specific options (user editable)
---@field ctx Rabbit.Plugin.Context Callback context. Consider this READ-ONLY; it is set by the parent Rabbit handler
---@field save string | false Where to save persistent storage, if necessary.
---@field setup? fun(opts: Rabbit.Plugin.Options) Initialize the plugin
---@field list? fun() Create a listing

---@class Rabbit.Plugin.Context
---@field plugin? Rabbit.Plugin
---@field winid? integer Window ID
---@field dir? Rabbit.Plugin.Context.Directory Working directory, according to `opts.cwd`

---@class Rabbit.Plugin.Context.Directory
---@field value any Current scoped directory
---@field scope "global" | "plugin" Indicates where the scope was evaluated
---@field raw string | fun() The generating function

---@class Rabbit.Plugin.Events
---@field BufAdd? fun(evt: NvimEvent.BufAdd, ctx: Rabbit.Plugin.Context)
---@field BufEnter? fun(evt: NvimEvent.BufEnter, ctx: Rabbit.Plugin.Context)
---@field BufDelete? fun(evt: NvimEvent.BufDelete, ctx: Rabbit.Plugin.Context)
---@field BufLeave? fun(evt: NvimEvent.BufLeave, ctx: Rabbit.Plugin.Context)
---@field BufNew? fun(evt: NvimEvent.BufNew, ctx: Rabbit.Plugin.Context)
---@field WinEnter? fun(evt: NvimEvent.WinEnter, ctx: Rabbit.Plugin.Context)
---@field WinLeave? fun(evt: NvimEvent.WinLeave, ctx: Rabbit.Plugin.Context)
---@field WinNew? fun(evt: NvimEvent.WinNew, ctx: Rabbit.Plugin.Context)
---@field WinClosed? fun(evt: NvimEvent.WinClosed, ctx: Rabbit.Plugin.Context)
---@field WinResized? fun(evt: NvimEvent.WinResized, ctx: Rabbit.Plugin.Context)
---@field ColorScheme? fun(evt: NvimEvent.ColorScheme, ctx: Rabbit.Plugin.Context)
---@field ColorSchemePre? fun(evt: NvimEvent.ColorSchemePre, ctx: Rabbit.Plugin.Context)
---@field BufFilePre? fun(evt: NvimEvent.BufFilePre, ctx: Rabbit.Plugin.Context)
---@field BufFilePost? fun(evt: NvimEvent.BufFilePost, ctx: Rabbit.Plugin.Context)
---@field RabbitInvalid? fun(evt: Rabbit.Event.Invalid, ctx: Rabbit.Plugin.Context)
---@field RabbitFileRename? fun(evt: Rabbit.Event.FileRename, ctx: Rabbit.Plugin.Context)
---@field RabbitEnter? fun(evt: Rabbit.Event.Enter, ctx: Rabbit.Plugin.Context)
---@field [string] fun(evt: NvimEvent, ctx: Rabbit.Plugin.Context)

---@class Rabbit.Plugin.Keymap
---@field select? _Str Select an entry; Open a file or open a collection.
---@field close? _Str Close Rabbit.
---@field delete? _Str Delete an entry; Remove a file or cut a collection.
---@field collect? _Str Create a collection.
---@field parent? _Str Move to the parent collection.
---@field insert? _Str Insert the current file or previously deleted file.
---@field help? _Str Open the keymap legend.
---@field debug? _Str Open the debug dialog.
---@field switch _Str Open this plugin after Rabbit is open.
---@field [string] _Str Keybindings

---@class Rabbit.Plugin.Options
---@field name string Name of the plugin
---@field color Color.Nvim Default border color.
---@field border? Rabbit.Term.Border Default border style. (leave blank to use global border)
---@field keys Rabbit.Plugin.Keymap Any keys used to bind to function names in `plugin.func`
---@field empty_msg string Message shown when listing is empty.
---@field cwd? string | fun() Current working directory function. (leave blank to use global cwd)
