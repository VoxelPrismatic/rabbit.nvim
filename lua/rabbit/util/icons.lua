--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

local ok, devicons = pcall(require, "nvim-web-devicons")

local ICONS = setmetatable({}, {
	__index = function(self, name)
		local ret = " "
		if ok then
			ret = devicons.get_icon_by_filetype(name)
				or devicons.get_icon_by_filetype(vim.filetype.match({ filename = name }))
				or " "
		end

		rawset(self, name, ret)
		return ret
	end,
})

return ICONS
