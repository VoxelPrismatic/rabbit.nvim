<div align="center">
	<img src="/rabbit.png" width="368" alt="logo"/>
	<h2 id="rabbitnvim">Jump between buffers faster than ever before</h2>
	<a href="https://github.com/VoxelPrismatic/rabbit.nvim/releases/latest"><img
		src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fapi.github.com%2Frepos%2FVoxelPrismatic%2Frabbit.nvim%2Freleases%2Flatest&query=%24.tag_name&style=flat&label=Rabbit&labelColor=white&logo=vowpalwabbit&logoColor=black"
	/></a>
	<a href="https://neovim.io/" target="_blank"><img
		src="https://img.shields.io/badge/Neovim-v0.11.0-brightgreen?style=flat&labelColor=white&logo=neovim&logoColor=black"
	/></a>
	<a href="https://github.com/VoxelPrismatic/rabbit.nvim/releases/latest"><img
		src="https://img.shields.io/github/downloads/voxelprismatic/rabbit.nvim/total?style=flat&logo=github&logoColor=black&label=Downloads&labelColor=white"
	/></a>
	<br/>
	<a href="https://x.com/voxelprismatic" target="_blank"><img
		src="https://img.shields.io/badge/VoxelPrismatic-white?style=flat&logo=x&logoColor=white&labelColor=black"
	/></a>
	<a href="https://discord.com/" target="_blank"><img
		src="https://img.shields.io/badge/VoxelPrismatic-white?style=flat&logo=discord&logoColor=white&labelColor=blue"
	/></a>
	<a href="https://patreon.com/voxelprismatic" target="_blank"><img
		src="https://img.shields.io/badge/VoxelPrismatic-white?style=flat&logo=patreon&logoColor=white&labelColor=red"
	/></a>
	<br>
	<span title="i wish i could customize this, dotfyles">
		<a href="https://dotfyle.com/plugins/VoxelPrismatic/rabbit.nvim"><img
			src="https://dotfyle.com/plugins/VoxelPrismatic/rabbit.nvim/shield?style=social"
		/></a>
	</span>
	<hr/>
</div>

- [Rabbit.nvim](#rabbitnvim)
	- [Why](#why)
	- [Install](#install)
	- [Usage](#usage)
	- [Configuration](#configuration)
	- [Preview](#preview)
- [Plugins](/lua/rabbit/plugins)
	- [![trail][rabbit.trail]][wiki.trail]
	- [![carrot][rabbit.carrot]][wiki.carrot]
	- [![forage][rabbit.forage]][wiki.forage]

[rabbit.trail]: https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FVoxelPrismatic%2Frabbit.nvim%2Frefs%2Fheads%2Frewrite%2Flua%2Frabbit%2Fplugins%2Ftrail%2FVERSION.json&query=%24.latest&style=flat&label=trail&labelColor=white&color=yellow
[wiki.trail]: ./lua/rabbit/plugins/trail

[rabbit.carrot]: https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FVoxelPrismatic%2Frabbit.nvim%2Frefs%2Fheads%2Frewrite%2Flua%2Frabbit%2Fplugins%2Fcarrot%2FVERSION.json&query=%24.latest&style=flat&label=carrot&labelColor=white&color=yellow
[wiki.carrot]: ./lua/rabbit/plugins/carrot

[rabbit.forage]: https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FVoxelPrismatic%2Frabbit.nvim%2Frefs%2Fheads%2Frewrite%2Flua%2Frabbit%2Fplugins%2Fforage%2FVERSION.json&query=%24.latest&style=flat&label=carrot&labelColor=white&color=yellow
[wiki.forage]: ./lua/rabbit/plugins/forage

---

> [!WARNING]
> This is the rewrite branch. All changes will be merged once I am confident in
> feature parity. Please use the original branch for now.

# Rabbit.nvim
A plugin that allows you to switch between buffers faster than ever before, featuring a much more
intuitive experience. You can customize almost every part of it, so it fits right into your workflow.

## Why
- **Telescope**
	1. Consumes your screen; switch context
		- Rabbit takes up a small spot in the corner of your screen
	2. Previews aren't literally where they would appear, making you switch contexts multiple times for a single action
		- Rabbit shows previews in the window you're about to open it. When you select a file, the only thing that happens is the borders disappear
	3. No warnings for missing dependencies
		- Rabbit warns you if tools like `rg` or `fzf` are not installed
	4. Does not order by recency or split by window
		- Rabbit does both
- **Harpoon**
	1. Built for @ThePrimeagen, meaning it's very basic and not intuitive
		- Rabbit shows a legend of actions you can perform
	2. You have to remember where you are and where you were
		- Rabbit allows you to forget about both
- **`:b #`**
	1. You have to remember buffer numbers
		- Rabbit obviously does this for you
	2. You can't open closed buffers
		- Rabbit allows you to open closed buffers
- **Buffer line**
	1. Buffer line is designed for mouse users
		- Rabbit is keyboard-first
	2. You cannot scroll if you have lots of buffers open
		- Rabbit is a vertical list, so you can scroll if you need to
- **`:ls`**
	1. Does not tell you what buffers are open
		- Rabbit does, and, which were recently closed!

## Install
```lua
---@type LazyPluginSpec
return {
	-- Optional, if you want icons for renamed files
	{
		"nvim-tree/nvim-web-devicons",
		lazy = true,
	},

	-- Rabbit
	{
		"voxelprismatic/rabbit.nvim",

		-- Important! The master branch is the previous version
		branch = "rewrite",

		-- Important! Rabbit should launch on startup to track buffers properly
		lazy = false,

		---@type Rabbit.Config
		opts = {},
		config = true,
	}
}
```

## Requirements
- Neovim v0.10.0 + LuaJIT
- Linux, macOS, WSL or other Posix environment
	- Windows is not supported. Any unreproduceable bugs on Windows will not be resolved
- Rabbit will warn you dynamically if any other dependencies are not installed

## Configuration
Because Rabbit is expansive & modular, the config may look jarring and complex, but is fully documented
in [config.lua](./lua/rabbit/config.lua). Feel free to simply use the `---@type Rabbit.Config` directive
or use the extremely sane defaults.

tl;dr:
```lua
---@type Rabbit.Config
{
	-- other rabbit options

	-- plugin specific options
	plugins = {
		[plugin_name] = {
			-- Open this plugin by default. If there are no default plugins, the generic selector is shown
			default = false,


			-- plugin options,
		},
	},
}
```
