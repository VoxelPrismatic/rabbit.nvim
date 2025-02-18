---@class Rabbit.Autocmd
local M = { ---@type Rabbit.Autocmd
	attached = { "WinClosed", "RabbitEnter", "RabbitInvalid", "RabbitFileRename" },
	last_directory = "",
	last_filename = "",
}


---@param rabbit Rabbit.Instance
---@param name string | string[]
---@param callback fun(evt: NvimEvent)
function M.attach_autocmd(rabbit, name, callback)
	vim.api.nvim_create_autocmd(name, {
		pattern = {"*"},
		callback = function(evt)
			rabbit.autocmd(evt)
			callback(evt)
		end
	})
	table.insert(M.attached, name)
end


-- Attaches autocmds to Rabbit
---@param rabbit Rabbit.Instance
function M.attach(rabbit)
	M.attach_autocmd(rabbit, "BufEnter", function() end)

	M.attach_autocmd(rabbit, "BufFilePre", function(evt) ---@param evt NvimEvent.BufFilePre
		M.last_filename = evt.file
	end)

	M.attach_autocmd(rabbit, "BufFilePost", function(evt) ---@param evt NvimEvent.BufFilePost
		local mock_evt = { ---@type Rabbit.Event.FileRename
			buf = evt.buf,
			event = "RabbitFileRename",
			file = evt.file,
			id = rabbit.user.win,
			match = M.last_filename
		}
		rabbit.autocmd(mock_evt)
	end)

	M.attach_autocmd(rabbit, { "BufDelete", "BufUnload" }, function()
		if rabbit.rabbit.win ~= nil then
			rabbit.Redraw()
		end
	end)

	M.attach_autocmd(rabbit, "WinResized", function()
		if rabbit.rabbit.win ~= nil then
			rabbit.Switch(rabbit.ctx.plugin.name)
		end
	end)

	vim.api.nvim_create_autocmd("WinClosed", {
		pattern = {"*"},
		callback = function(evt) ---@param evt NvimEvent.WinClosed
			local w = tonumber(evt.file) or -2
			for k, _ in pairs(rabbit.plugins) do
				local p = rabbit.plugins[k] ---@type Rabbit.Plugin
				if p.evt.WinClosed ~= nil then
					p.evt.WinClosed(evt, w)
				else
					p.listing[w] = nil
				end
			end
		end,
	})
end

return M
