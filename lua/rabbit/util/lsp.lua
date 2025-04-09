local LSP = {}

---@param bufid integer
---@param details Rabbit.Config.Window.Beacon.Lsp | Rabbit.Enum.Diagnostic
---@return Rabbit.Lsp.Count
function LSP.get_count(bufid, details)
	if details == false then
		return {
			error = 0,
			warn = 0,
			info = 0,
			hint = 0,
		}
	end

	if type(details) ~= "table" then
		details = {
			error = details,
			warn = details,
			info = details,
			hint = details,
		}
	end

	---@type { [integer]: { cb: boolean | (fun(d: vim.Diagnostic): boolean), count: integer } }
	local tests = {
		[vim.diagnostic.severity.ERROR] = { cb = details.error, count = 0 },
		[vim.diagnostic.severity.WARN] = { cb = details.warn, count = 0 },
		[vim.diagnostic.severity.INFO] = { cb = details.info, count = 0 },
		[vim.diagnostic.severity.HINT] = { cb = details.hint, count = 0 },
	}

	for _, d in pairs(vim.diagnostic.get(bufid)) do
		local test = tests[d.severity]
		if test.cb == false then
			-- pass
		elseif test.cb == true or test.cb(d) then
			test.count = test.count + 1
		end
	end

	return { ---@type Rabbit.Lsp.Count
		error = tests[vim.diagnostic.severity.ERROR].count,
		warn = tests[vim.diagnostic.severity.WARN].count,
		info = tests[vim.diagnostic.severity.INFO].count,
		hint = tests[vim.diagnostic.severity.HINT].count,
	}
end

---@class Rabbit.Lsp.Count
---@field error integer
---@field warn integer
---@field info integer
---@field hint integer

return LSP
