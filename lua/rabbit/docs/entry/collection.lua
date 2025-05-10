--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

---@class (exact) Rabbit.Entry.Collection: Rabbit.Entry
---@field type "collection"
---@field label Rabbit.Entry._.Label The entry label.
---@field tail? Rabbit.Entry._.Label Any right-aligned context you want to show
---@field actions Rabbit.Entry.Collection.Actions The actions to perform on the file.

---@class Rabbit.Entry.Collection.Actions
---@field select? Rabbit.Action.Callback<Rabbit.Action.Select>
---@field delete? Rabbit.Action.Callback<Rabbit.Action.Delete>
---@field children Rabbit.Action.Callback<Rabbit.Action.Children>
---@field hover? Rabbit.Action.Callback<Rabbit.Action.Hover>
---@field parent? Rabbit.Action.Callback<Rabbit.Action.Parent>
---@field rename? Rabbit.Action.Callback<Rabbit.Action.Rename>
---@field insert? Rabbit.Action.Callback<Rabbit.Action.Insert>
---@field collect? Rabbit.Action.Callback<Rabbit.Action.Collect>
---@field yank? Rabbit.Action.Callback<Rabbit.Action.Yank>
---@field cut? Rabbit.Action.Callback<Rabbit.Action.Cut>
---@field visual? Rabbit.Action.Callback<Rabbit.Action.Visual>
---@field paste? Rabbit.Action.Callback<Rabbit.Action.Paste>
