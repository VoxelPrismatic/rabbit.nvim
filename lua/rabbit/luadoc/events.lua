---@class Rabbit.Plugin.Event
---@field RabbitInvalid? fun(evt: Rabbit.Event.Invalid, winid: integer)
---@field RabbitFileRename? fun(evt: Rabbit.Event.FileRename, winid: integer)
---@field RabbitChangeDirectory? fun(evt: Rabbit.Event.ChangeDirectory, winid: integer)
---@field RabbitEnter? fun(evt: Rabbit.Event.Enter, winid: integer)
---@field BufAdd? fun(evt: NvimEvent.BufAdd, winid: integer)
---@field BufEnter? fun(evt: NvimEvent.BufEnter, winid: integer)
---@field BufDelete? fun(evt: NvimEvent.BufDelete, winid: integer)
---@field BufLeave? fun(evt: NvimEvent.BufLeave, winid: integer)
---@field BufNew? fun(evt: NvimEvent.BufNew, winid: integer)
---@field BufFilePre? fun(evt: NvimEvent.BufFilePre, winid: integer)
---@field BufFilePost? fun(evt: NvimEvent.BufFilePost, winid: integer)
---@field WinEnter? fun(evt: NvimEvent.WinEnter, winid: integer)
---@field WinLeave? fun(evt: NvimEvent.WinLeave, winid: integer)
---@field WinNew? fun(evt: NvimEvent.WinNew, winid: integer)
---@field WinClosed? fun(evt: NvimEvent.WinClosed, winid: integer)
---@field WinScrolled? fun(evt: NvimEvent.WinScrolled, winid: integer)
---@field WinResized? fun(evt: NvimEvent.WinResized, winid: integer)
---@field ColorScheme? fun(evt: NvimEvent.ColorScheme, winid: integer)
---@field ColorSchemePre? fun(evt: NvimEvent.ColorSchemePre, winid: integer)
---@field [string] fun(evt: NvimEvent, winid: integer)



-- BufHidden
-- BufNewFile
-- BufRead
-- BufReadPost
-- BufReadCmd
-- BufReadPre
-- BufUnload
-- BufWinEnter
-- BufWinLeave
-- BufWipeout
-- BufWrite
-- BufWriteCmd
-- BufWritePost


-- ChanInfo
-- ChanOpen


-- CmdUndefined
-- CmdlineChanged
-- CmdlineEnter
-- CmdlineLeave
-- CmdwinEnter
-- CmdwinLeave


-- CompleteChanged
-- CompleteDonePre
-- CompleteDone


-- CursorHold
-- CursorHoldI
-- CursorMoved
-- CursorMovedC
-- CursorMovedI


-- DiffUpdated


-- DirChanged
-- DirChangedPre


-- ExitPre


-- FileAppendCmd
-- FileAppendPost
-- FileAppendPre
-- FileChangedRO
-- FileChangedShell
-- FileChangedShellPost
-- FileReadCmd
-- FileReadPost
-- FileReadPre
-- FileType
-- FileWriteCmd
-- FileWritePost
-- FileWritePre


-- FilterReadPre
-- FilterReadPost
-- FilterWritePre
-- FilterWritePost


-- FocusGained
-- FocusLost


-- FuncUndefined


-- UIEnter
-- UILeave


-- InsertChange
-- InsertCharPre
-- InsertEnter
-- InsertLeave


-- MenuPopup


-- ModeChanged


-- OptionSet


-- QuickFixCmdPre
-- QuickFixCmdPost


-- QuitPre


-- RemoteReply


-- SearchWrapped


-- RecordingEnter
-- RecordingLeave


-- SafeState


-- SessionLoadPost
-- SessionWritePost


-- ShellCmdPost
-- ShellFilterPost


-- Signal


-- SourcePre
-- SourcePost
-- SourceCmd


-- SpellFileMissing


-- StdinReadPost
-- StdinReadPre


-- SwapExists


-- Syntax


-- TabEnter
-- TabLeave
-- TabNew
-- TabNewEntered
-- TabClosed


-- TermOpen
-- TermEnter
-- TermLeave
-- TermClose
-- TermRequest
-- TermResponse


-- TextChanged
-- TextChangedI
-- TextChangedP
-- TextChangedT
-- TextYankPost


-- User
-- UserGettingBored


-- VimEnter
-- VimLeave
-- VimLeavePre
-- VimResized
-- VimResume
-- VimSuspend
