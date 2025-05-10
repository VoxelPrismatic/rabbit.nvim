--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

local SET = require("rabbit.util.set")

---@class (exact) Rabbit.Stack.Kwargs.Keybind
---@field mode? "n" | string | string[] Keymap mode
---@field shown? true | boolean Whether or not to show this in the legend
---@field keys string | string[] Keys to bind
---@field label string Description/legend label
---@field callback? function Callback
---@field hl? string Highlight name when building namespace. Used to filter.
---@field align? "left" | "right" | "center" Alignment when returning this legend

-- Creates the legend entry
---@param self Rabbit.Stack.Keybind
---@param align? "left" | "right" | "center" Alignment
---@param new_label? string New label to use
---@return Rabbit.Term.HlLine[] "Legend entry"
local function bind_legend(self, align, new_label)
	local ret = {
		{
			text = new_label or self.label,
			hl = { "rabbit.legend.action", self.hl },
			align = align,
		},
		{
			text = ":",
			hl = "rabbit.legend.separator",
			align = align,
		},
		{
			text = self.keys[1],
			hl = "rabbit.legend.key",
			align = align,
		},
	}

	table.insert(ret, align == "right" and #ret + 1 or 1, { text = " ", align = align })
	return ret
end

-- Checks if two keybinds conflict
---@param self Rabbit.Stack.Keybind
---@param other Rabbit.Stack.Keybind
---@return boolean
local function bind_conflict(self, other)
	return self.label == other.label and self.mode == other.mode
end

-- Actually binds the keymap to the buffer
---@param self Rabbit.Stack.Keybind
---@param bufid integer
---@param callback? function Custom callback function
local function bind_set(self, bufid, callback)
	for _, k in ipairs(self.keys) do
		vim.keymap.set(self.mode, k, callback or self.callback, { buffer = bufid, desc = self.label })
	end
end

-- Actually deletes the keybind from the buffer
---@param self Rabbit.Stack.Keybind
---@param bufid integer
local function bind_del(self, bufid)
	for _, k in ipairs(self.keys) do
		_ = pcall(vim.keymap.del, self.mode, k, { buffer = bufid })
	end
end

-- Creates a new keybind
---@param kwargs Rabbit.Stack.Kwargs.Keybind
---@return Rabbit.Stack.Keybind[]
local function new_bind(kwargs)
	local mode = kwargs.mode or { "n" }
	if type(mode) == "string" then
		mode = { mode }
	end
	mode = SET.new(mode)

	assert(#mode > 0, "Keybinds must have at least one mode")

	local keys = kwargs.keys or {}
	if type(keys) == "string" then
		keys = { keys }
	end
	keys = SET.new(keys)

	assert(kwargs.callback ~= nil or #keys == 0, "Keybinds with callbacks must have at least one key")

	local shown = kwargs.shown
	if shown == nil then
		shown = true
	end

	local ret = {}
	for _, m in ipairs(mode) do
		---@class Rabbit.Stack.Keybind
		local key = {
			-- Description/legend label
			---@type string
			label = kwargs.label or "nil",

			-- Keys bound to this action
			---@type Rabbit.Table.Set<string>
			keys = keys,

			-- Keymap mode
			---@type "n" | "i" | "v" | "x"
			mode = m,

			-- Highlight namespace
			---@type string
			hl = kwargs.hl,

			-- Whether or not to show this in the legend
			---@type boolean
			shown = shown,

			-- Callback function
			---@type fun(evt: NvimEvent): boolean?
			callback = kwargs.callback,

			-- Returns the legend for this keybind
			legend = bind_legend,

			-- Returns true if there is a conflict with this keybind
			conflict = bind_conflict,

			-- Sets the keybinds to the buffer
			set = bind_set,

			-- Deletes the keybinds from the buffer
			del = bind_del,
		}
		table.insert(ret, key)
	end

	return ret
end

---@class Rabbit.Stack.Workspace.Keys
local KEYS = {
	-- Actual keys
	---@type Rabbit.Stack.Keybind[]
	binds = {},

	-- Target workspace
	---@type Rabbit.Stack.Workspace
	target = nil,
}

-- Creates a new keybind manager
---@param workspace Rabbit.Stack.Workspace
function KEYS.new(workspace)
	return setmetatable({ target = workspace }, { __index = vim.deepcopy(KEYS) })
end

-- Adds a keybind to this workspace
---@param ... Rabbit.Stack.Kwargs.Keybind
---@return Rabbit.Term.HlLine[] "Legend entry"
function KEYS:add(...)
	assert(self.target ~= nil, "Cannot add keybinds to nil workspace")

	local ret = {}
	for _, kwargs in ipairs({ ... }) do
		local keys = new_bind(kwargs)
		for _, new in ipairs(keys) do
			for i = #self.binds, 1, -1 do
				local old = self.binds[i]
				old.keys:del(new.keys)
				if #old.keys == 0 or old:conflict(new) then
					table.remove(self.binds, i):del(self.target.buf.id)
				end
			end

			new:set(self.target.buf.id)
			table.insert(self.binds, new)
		end
		if keys[1].shown then
			table.insert(ret, keys[1]:legend(kwargs.align))
		end
	end

	return ret
end

-- Removes keybinds from this workspace
---@param ... string Labels to remove (regardless of mode)
function KEYS:del(...)
	assert(self.target ~= nil, "Cannot delete keybinds from nil workspace")

	for _, label in ipairs({ ... }) do
		for i = #self.binds, 1, -1 do
			if self.binds[i].label == label then
				table.remove(self.binds, i):del(self.target.buf.id)
			end
		end
	end
end

-- Removes all keybinds from this workspace
function KEYS:clear()
	assert(self.target ~= nil, "Cannot clear keybinds from nil workspace")
	for _, key in ipairs(self.binds) do
		key:del(self.target.buf.id)
	end
	self.binds = {}
end

-- Returns true if there is a keybind with the given label
---@param label string
---@return boolean
function KEYS:has(label)
	for _, key in ipairs(self.binds) do
		if key.label == label then
			return true
		end
	end
	return false
end

---@class Rabbit.Stack.Kwargs.Legend
---@field align? "left" | "right" | "center" Set alignment
---@field hl? string Highlight name
---@field mode? "n" | "i" | "v" | "x" Keymap mode
---@field labels? string[] List of labels to return. If nil or empty, all returned
---@field rename? table<string, string> Map of old label to new label

-- Returns all the legends with the current mode and highlight
---@param kwargs? Rabbit.Stack.Kwargs.Legend
function KEYS:legend(kwargs)
	table.sort(self.binds, function(a, b)
		return a.label < b.label
	end)

	kwargs = kwargs or {}
	kwargs.labels = kwargs.labels or {}
	kwargs.rename = kwargs.rename or {}

	local to_ret = SET.new(kwargs.labels)
	local actions = {}

	local mode = kwargs.mode or vim.fn.mode():lower()
	for _, key in ipairs(self.binds) do
		local found = to_ret:idx(key.label) ~= nil
		if #to_ret > 0 and not found then
			-- pass
		elseif (key.shown or found) and key.mode == mode and (kwargs.hl == nil or key.hl == kwargs.hl) then
			table.insert(actions, key:legend(kwargs.align, kwargs.rename[key.label] or key.label))
		end
	end

	return actions
end

-- Returns the keybind with the given label
---@param ... string
---@return table<string, Rabbit.Stack.Keybind> "Keybind by name"
---@return Rabbit.Stack.Keybind? "Last match, eg `_, select = KEYS:find('select')`"
function KEYS:find(...)
	local ret = {}
	local last
	for _, label in ipairs({ ... }) do
		for _, bind in ipairs(self.binds) do
			if bind.label == label then
				ret[label] = bind
				last = bind
			end
		end
	end
	return ret, last
end

-- Rebinds the keybinds with the given callbacks to the new buffer ID
-- Note: does NOT touch anything in this instance. Simply a helper function
-- to use user's existing keybinds with new callbacks
---@param bufid integer
---@param callbacks table<string, function>
function KEYS:rebind(bufid, callbacks)
	local keys = self:find(unpack(vim.tbl_keys(callbacks)))
	for label, callback in pairs(callbacks) do
		keys[label]:set(bufid, callback)
	end
end

return KEYS
