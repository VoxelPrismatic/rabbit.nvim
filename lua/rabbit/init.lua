local RABBIT = {
	plugins = {}, ---@type table<string, Rabbit.Plugin>
	order = {}, ---@type string[]
}
local OPTS = require("rabbit.config")

function RABBIT.setup(opts)
	OPTS.setup(opts)

	for k, v in pairs(OPTS.plugins) do
		local ok, p = pcall(require, "rabbit.plugins." .. k)
		if not ok then
			p = require(k)
		end

		RABBIT.plugins[k] = p
		table.insert(RABBIT.order, k)
		p.setup(v)
	end
end

return RABBIT
