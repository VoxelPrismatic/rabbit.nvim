--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

---@class Rabbit.Entry
---@field class "entry"
---@field ctx? table Any context you like. Rabbit will not touch this.
---@field type string
---@field idx?
---| true # Show the index number
---| false # Use dashes instead of the index number
---| string # Custom icon to use
---@field _env? Rabbit.Entry._.Environment The environment this entry lives in
---@field actions table
---@field default? boolean Automatically hover over this entry by default
---@field synopsis? Rabbit.Term.HlLine.NoAlign A description of the entry. Wrapping is handled automatically
---@field action_label? table<string, string> Rename action labels
---@field label? Rabbit.Entry._.Label

---@class Rabbit.Entry._.Environment
---@field cwd string The current working directory.
---@field idx integer The index of the file in the list.
---@field parent Rabbit.Entry.Collection The parent collection.
---@field siblings Rabbit.Entry[] The siblings.
---@field entry Rabbit.Entry The current entry.
---@field real? integer The real index as shown in the listing. Nil if index was disabled
---@field ident string The indent string (eg " 1. ").

---@alias Rabbit.Entry._.Label
---| string # Generic text
---| Rabbit.Term.HlLine # Highlighted text
---| string[] # Generic text
