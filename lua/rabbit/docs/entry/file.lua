--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

---@class (exact) Rabbit.Entry.File: Rabbit.Entry
---@field type "file"
---@field path string The path to the file.
---@field closed boolean True if the file is closed. This will be listed in red.
---@field bufid integer The buffer number, if the file is currently open.
---@field target_winid integer The window number the file should be opened in.
---@field actions Rabbit.Entry.File.Actions The actions to perform on the file.
---@field jump? Rabbit.Entry.File.Jump The line number and column to highlight
---@field label? Rabbit.Term.HlLine Label to display. If nil, it will use the relative path handler.

---@class (exact) Rabbit.Entry.File.Jump
---@field line integer Highlight line number
---@field col integer Highlight column start (if nil, entire line is highlighted)
---@field end_ integer Highlight column end (if nil, entire line is highlighted)
---@field others? Rabbit.Entry.File.Jump[] Other jumps
---@field hl? boolean Whether to highlight this match

---@class Rabbit.Entry.File.Actions
---@field select? Rabbit.Action.Callback<Rabbit.Action.Select>
---@field delete? Rabbit.Action.Callback<Rabbit.Action.Delete>
---@field hover? Rabbit.Action.Callback<Rabbit.Action.Hover>
---@field parent? Rabbit.Action.Callback<Rabbit.Action.Parent>
---@field insert? Rabbit.Action.Callback<Rabbit.Action.Insert>
---@field collect? Rabbit.Action.Callback<Rabbit.Action.Collect>
---@field yank? Rabbit.Action.Callback<Rabbit.Action.Yank>
---@field cut? Rabbit.Action.Callback<Rabbit.Action.Cut>
---@field rename? Rabbit.Action.Callback<Rabbit.Action.Rename>
---@field visual? Rabbit.Action.Callback<Rabbit.Action.Visual>
---@field paste? Rabbit.Action.Callback<Rabbit.Action.Paste>
