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
