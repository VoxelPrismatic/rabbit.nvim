local LSP = {}

---@param bufid integer
---@param details Rabbit.Config.Window.Extras.Lsp | Rabbit.Config.Window.Extras.Lsp.Callback
---@return Rabbit.Lsp.Count
function LSP.get_count(bufid, details)
	local lsp_count = { ---@type Rabbit.Lsp.Count
		error = 0,
		warn = 0,
		info = 0,
		hint = 0,
	}

	if details == false then
		return lsp_count
	end

	local test_error ---@type Rabbit.Config.Window.Extras.Lsp.Callback
	local test_warn ---@type Rabbit.Config.Window.Extras.Lsp.Callback
	local test_info ---@type Rabbit.Config.Window.Extras.Lsp.Callback
	local test_hint ---@type Rabbit.Config.Window.Extras.Lsp.Callback

	if type(details) == "function" then
		test_error = details
		test_warn = details
		test_info = details
		test_hint = details
	elseif details == true then
		test_error = true
		test_warn = true
		test_info = true
		test_hint = true
	else
		test_error = details.error
		test_warn = details.warn
		test_info = details.info
		test_hint = details.hint
	end

	if type(test_error) == "boolean" then
		test_error = function()
			return test_error
		end
	end

	if type(test_warn) == "boolean" then
		test_warn = function()
			return test_warn
		end
	end

	if type(test_info) == "boolean" then
		test_info = function()
			return test_info
		end
	end

	if type(test_hint) == "boolean" then
		test_hint = function()
			return test_hint
		end
	end

	for _, d in pairs(vim.diagnostic.get(bufid)) do
		if d.severity == vim.diagnostic.severity.ERROR and test_error(d) then
			lsp_count.error = lsp_count.error + 1
		elseif d.severity == vim.diagnostic.severity.WARN and test_warn(d) then
			lsp_count.warn = lsp_count.warn + 1
		elseif d.severity == vim.diagnostic.severity.INFO and test_info(d) then
			lsp_count.info = lsp_count.info + 1
		elseif d.severity == vim.diagnostic.severity.HINT and test_hint(d) then
			lsp_count.hint = lsp_count.hint + 1
		end
	end

	return lsp_count
end

---@class Rabbit.Lsp.Count
---@field error integer
---@field warn integer
---@field info integer
---@field hint integer

return LSP
