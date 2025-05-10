--[[ Rabbit.nvim - Jump between buffers faster than ever before
	 Copyright (C) 2025 VoxelPrismatic
	 Licensed under AGPLv3: https://gnu.org/licenses/agpl-3.0 ]]

---@class Rabbit.Config
local C = {
	colors = require("rabbit.config.colors"),
	window = require("rabbit.config.window"),
	boxes = require("rabbit.config.boxes"),
	keys = require("rabbit.config.keys"),
	system = require("rabbit.config.system"),
	plugins = require("rabbit.config.plugins"),
	icons = require("rabbit.config.icons"),
}

-- Set up Rabbit
---@param opts Rabbit.Config
function C.setup(opts)
	for k, v in pairs(C) do
		if type(v) == "table" then
			C[k] = vim.tbl_deep_extend("force", v, opts[k] or {})
		end
	end

	for k, v in pairs(C.keys) do
		if type(v) == "string" then
			C.keys[k] = { v }
		end
	end

	for _, p in ipairs(C.plugins) do
		if type(p) == "table" and p.keys ~= nil then
			for k, v in pairs(p.keys) do
				if type(v) == "string" then
					p.keys[k] = { v }
				end
			end
		end
	end

	if C.system.data:sub(-1) ~= "/" then
		C.system.data = C.system.data .. "/"
	end
end

return C
