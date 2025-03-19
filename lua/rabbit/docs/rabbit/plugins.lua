---@class (exact) Rabbit.Plugin
---@field name string Name of the plugin
---@field empty_msg string Message to display when the listing is empty
---@field actions Rabbit.Plugin.Actions Action callbacks
---@field events Rabbit.Plugin.Events NvimEvent Callbacks
---@field opts Rabbit.Plugin.Options Plugin specific options (user editable)
---@field _env Rabbit.Plugin.Environment Callback context. Consider this READ-ONLY; it is set by the parent Rabbit handler
---@field save string | false Where to save persistent storage, if necessary.
---@field setup? fun(opts: Rabbit.Plugin.Options) Initialize the plugin
---@field list? fun(): Rabbit.Entry.Collection Create a listing

---@class Rabbit.Plugin.Environment
---@field plugin? Rabbit.Plugin
---@field winid? integer Window ID
---@field cwd? Rabbit.Plugin.Context.Directory Working directory, according to `opts.cwd`
---@field open? boolean Whether Rabbit is currently open

---@class Rabbit.Plugin.Actions
---@field select Rabbit.Action.Select
---@field children Rabbit.Action.Children
---@field close Rabbit.Action.Close
---@field hover Rabbit.Action.Hover
---@field parent Rabbit.Action.Parent
---@field rename Rabbit.Action.Rename

---@class Rabbit.Plugin.Context.Directory
---@field value any Current scoped directory
---@field scope "global" | "plugin" | "fallback" Indicates where the scope was evaluated
---@field raw string | fun() The generating function

---@class Rabbit.Plugin.Events
---@field BufAdd? fun(evt: NvimEvent.BufAdd, ctx: Rabbit.Plugin.Environment)
---@field BufEnter? fun(evt: NvimEvent.BufEnter, ctx: Rabbit.Plugin.Environment)
---@field BufDelete? fun(evt: NvimEvent.BufDelete, ctx: Rabbit.Plugin.Environment)
---@field BufLeave? fun(evt: NvimEvent.BufLeave, ctx: Rabbit.Plugin.Environment)
---@field BufNew? fun(evt: NvimEvent.BufNew, ctx: Rabbit.Plugin.Environment)
---@field WinEnter? fun(evt: NvimEvent.WinEnter, ctx: Rabbit.Plugin.Environment)
---@field WinLeave? fun(evt: NvimEvent.WinLeave, ctx: Rabbit.Plugin.Environment)
---@field WinNew? fun(evt: NvimEvent.WinNew, ctx: Rabbit.Plugin.Environment)
---@field WinClosed? fun(evt: NvimEvent.WinClosed, ctx: Rabbit.Plugin.Environment)
---@field WinResized? fun(evt: NvimEvent.WinResized, ctx: Rabbit.Plugin.Environment)
---@field ColorScheme? fun(evt: NvimEvent.ColorScheme, ctx: Rabbit.Plugin.Environment)
---@field ColorSchemePre? fun(evt: NvimEvent.ColorSchemePre, ctx: Rabbit.Plugin.Environment)
---@field BufFilePre? fun(evt: NvimEvent.BufFilePre, ctx: Rabbit.Plugin.Environment)
---@field BufFilePost? fun(evt: NvimEvent.BufFilePost, ctx: Rabbit.Plugin.Environment)
---@field RabbitInvalid? fun(evt: Rabbit.Event.Invalid, ctx: Rabbit.Plugin.Environment)
---@field RabbitFileRename? fun(evt: Rabbit.Event.FileRename, ctx: Rabbit.Plugin.Environment)
---@field RabbitEnter? fun(evt: Rabbit.Event.Enter, ctx: Rabbit.Plugin.Environment)
---@field [string] fun(evt: NvimEvent, ctx: Rabbit.Plugin.Environment)

---@class Rabbit.Plugin.Keymap
---@field select? _Str Select an entry; Open a file or open a collection.
---@field close? _Str Close Rabbit.
---@field delete? _Str Delete an entry; Remove a file or cut a collection.
---@field collect? _Str Create a collection.
---@field parent? _Str Move to the parent collection.
---@field insert? _Str Insert the current file or previously deleted file.
---@field help? _Str Open the keymap legend.
---@field debug? _Str Open the debug dialog.
---@field rename? _Str Rename an entry.
---@field switch _Str Open this plugin after Rabbit is open.
---@field [string] _Str Keybindings

---@class (exact) Rabbit.Plugin.Options
---@field color Color.Nvim Default border color.
---@field border? Rabbit.Term.Border Default border style. (leave blank to use global border)
---@field keys Rabbit.Plugin.Keymap Any keys used to bind to function names in `plugin.func`
---@field cwd? string | fun() Current working directory function. (leave blank to use global cwd)

---@alias _Str string | string[]
