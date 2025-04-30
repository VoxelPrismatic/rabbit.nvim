-- Plugin settings
---@class Rabbit.Config.Plugin
local PLUGINS = {
	-- Disable a plugin with 'false'

	---@type Rabbit*Trail.Options | false
	---@diagnostic disable-next-line: missing-fields
	trail = {},

	---@type Rabbit*Carrot.Options | false
	---@diagnostic disable-next-line: missing-fields
	carrot = {},

	---@type Rabbit*Index.Options | false
	---@diagnostic disable-next-line: missing-fields
	index = {
		default = true,
	},

	---@type Rabbit*Forage.Options | false
	---@diagnostic disable-next-line: missing-fields
	forage = {},

	-- To use a custom plugin, simply set the key to its Require path.
	-- For example: ["path.to.plugin"] = { options }
	-- Rabbit first checks if the plugin is bundled with Rabbit
	-- (checking `require("rabbit.plugins.Key")`). If it doesn't exist,
	-- it will then run `require("Key")`.
}

return PLUGINS
