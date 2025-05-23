--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

---@class (exact) Rabbit.Plugin
---@field name string Name of the plugin
---@field actions Rabbit.Plugin.Actions Action callbacks
---@field events Rabbit.Plugin.Events NvimEvent Callbacks
---@field opts Rabbit.Plugin.Options Plugin specific options (user editable)
---@field _env Rabbit.Plugin.Environment Callback context. Consider this READ-ONLY; it is set by the parent Rabbit handler
---@field save string | false Where to save persistent storage, if necessary.
---@field setup? fun(opts: Rabbit.Plugin.Options) Initialize the plugin
---@field list? fun(): Rabbit.Entry.Collection Create a listing
---@field requires? string[] List of other required plugins
---@field empty Rabbit.Plugin.Empty What to do when the listing is empty
---@field synopsis string Plugin description
---@field version string Plugin version

---@class (exact) Rabbit.Plugin.Empty
---@field msg string Message to display when the listing is empty
---@field actions Rabbit.Entry.Collection.Actions Action callbacks

---@class Rabbit.Plugin.Environment
---@field plugin? Rabbit.Plugin
---@field winid? integer User's current Window ID
---@field cwd? Rabbit.Plugin.Context.Directory Working directory, according to `opts.cwd`
---@field open? boolean Whether Rabbit is currently open
---@field bufid? integer User's current Buffer ID
---@field hov? { [integer]: integer } Window:Buffer IDs

---@class Rabbit.Plugin.Context.Directory
---@field value any Current scoped directory
---@field scope "global" | "plugin" | "fallback" | "script" Indicates where the scope was evaluated
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

---@class (exact) Rabbit.Plugin.Options
---@field color Rabbit.Color Default border color.
---@field keys Rabbit.Plugin.Keymap Any keys used to bind to function names in `plugin.func`
---@field cwd? string | fun(): string Current working directory function. (leave blank to use global cwd)
---@field default? boolean Default plugin to open upon Rabbit opening
