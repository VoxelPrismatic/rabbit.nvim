---@class Rabbit.Stack.WinConfig: vim.api.keyset.win_config
---@field width integer
---@field height integer
local WINCONFIG = {
	-- Window ID
	---@type integer
	id = 0,
}

local meta_WINCONFIG = {
	__index = {},
	__newindex = function(self, key, value)
		local metatable = getmetatable(self)
		local tmp = vim.deepcopy(metatable.__index)
		tmp[key] = value
		vim.api.nvim_win_set_config(self.id, tmp)
		-- Update self *after* applying
		metatable.__index[key] = value
	end,
}

function WINCONFIG.New(id)
	local ret = vim.deepcopy(WINCONFIG)
	ret.id = id
	setmetatable(ret, vim.deepcopy(meta_WINCONFIG))
	ret:Get()

	return ret
end

-- Updates the window configuration
---@return Rabbit.Stack.WinConfig self
function WINCONFIG:Get()
	local config = vim.api.nvim_win_get_config(self.id)
	local metatable = getmetatable(self)
	metatable.__index = config

	config.width = config.width or vim.api.nvim_win_get_width(self.id)
	config.height = config.height or vim.api.nvim_win_get_height(self.id)

	if config.row == nil or config.col == nil then
		config.row, config.col = unpack(vim.api.nvim_win_get_position(self.id))
	end
	return self
end

-- Saves the window state
---@return vim.fn.winsaveview.ret
function WINCONFIG:Save()
	return vim.api.nvim_win_call(self.id, vim.fn.winsaveview)
end

-- Sets the window configuration
---@param config vim.api.keyset.win_config
function WINCONFIG:Set(config)
	vim.api.nvim_win_set_config(self.id, config)
	self:Get()
end

-- Gets the raw window configuration
---@return vim.api.keyset.win_config raw
function WINCONFIG:Raw()
	return vim.deepcopy(getmetatable(self).__index)
end

setmetatable(WINCONFIG, meta_WINCONFIG)

return WINCONFIG
