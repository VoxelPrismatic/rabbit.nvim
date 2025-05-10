--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

---@class (exact) Rabbit.Entry.Search: Rabbit.Entry
---@field type "search"
---@field label Rabbit.Entry._.Label The entry label.
---@field fields { [string | integer]: Rabbit.Entry.Search.Fields }
---@field actions Rabbit.Entry.File.Actions
---@field open integer Which field is currently open

---@class Rabbit.Entry.Search.Fields
---@field name string Name of the field, eg "search" or "filter".
---@field content string Text content to pre-fill when the window is spawned.
---@field icon string Icon to display after the search box,
---@field on_switch (fun(): Rabbit.Response)? A function that is called when the user switches to this field.
