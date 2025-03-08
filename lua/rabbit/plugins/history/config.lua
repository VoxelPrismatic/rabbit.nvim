---@class Rabbit._.History.Options: Rabbit.Plugin.Options
local PLUGIN_CONFIG = {
	-- Name of the plugin.
	---@type string
	name = "history",

	-- Default border color.
	---@type Color.Nvim
	color = "#d875a7",

	keys = {
		switch = "o",
	},

	-- Ignore unlisted buffers like those from Oil.
	---@type boolean
	ignore_unlisted = true,
}

function PLUGIN_CONFIG.wrap_msg() end

return PLUGIN_CONFIG
