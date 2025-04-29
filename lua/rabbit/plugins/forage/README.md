[rabbit.forage]: https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FVoxelPrismatic%2Frabbit.nvim%2Frefs%2Fheads%2Frewrite%2Flua%2Frabbit%2Fplugins%2Fforage%2FVERSION.json&query=%24.latest&style=flat&label=forage&labelColor=white&color=yellow

# Forage ![version][rabbit.forage]
### Forage through the filesystem until you find what you're looking for

Rabbit Forage is a plugin that allows you to search the filesystem for files
using various tools like ripgrep, fzf, and find. It also features a list of
your frequently accessed files, sorted using Zoxide's algorithm.

> [!NOTE]
> Classic find is not implemented yet

## About fzr
`fzr` is a no-nonsense fuzzy finder designed for Rabbit. It supports the same
[fzf syntax](https://github.com/junegunn/fzf?tab=readme-ov-file#search-syntax),
but outputs in JSON and prioritizes consecutive matches. It is very easy to extend
should you want to make your own listings.

<details>
	<summary>Command details</summary>

### Running fzr
1. `pipe | fzr token1 token2 token3 ...`
	- Searches the contents of the piped input
2. `fzr [dir] token1 token2 token3 ...`
	- Searches files within a directory
3. `fzr @ '[cmd]' token1 token2 token3 ...`
	- Executes a command and searches its output. The cmd MUST be in quotes

Note: `|` counts as a token. Escape it with `\|`

Note: Inverse tokens are NOT highlighted

### Output
`stdout` is the human readable output, with fancy highlighting and whatnot.

`stderr` is JSON in the following format:

```js
[
	{
		"text": "full line text",
		// List of highlight groups
		// ---@type Rabbit.Term.HlLine[]
		"lines: [
			{
				"text": "full ",
				"hl": ["rabbit.files.file"]
				// 'file' indicates no match
			},
			{
				"text": "line",
				"hl": ["rabbit.paint.love", "rabbit.types.inverse"]
				// Any paint highlight groups indicate a match.
				// These groups are selected at random for each token.
			},
			{
				"text": " text",
				"hl": ["rabbit.files.file"]
			},
			// ...
		]
	},
	{
		// ...
	},
	// ...
]
```

### Extending fzr behavior
Fzr includes a `main()` fn, which means you will have to recompile fzr with your new behavior.
However, it's pretty easy to do, since all you need to do is pass tokens and lines to the `Compute(...)` fn.
`Compute(...)` returns a list of haystacks featuring only the matched lines. Each haystack includes the line
content, and a map of indexes to tokens, so you can highlight them later.

</details>

## Configuration
```lua
---@class (exact) Rabbit*Forage.Options: Rabbit.Plugin.Options
local PLUGIN_CONFIG = {
	-- Default border color
	---@type string
	color = "#33b473",

	keys = {
		-- Keybind to open the Forage plugin from within Rabbit
		---@type string
		switch = "f",
	},

	-- Enable fuzzy find with `fzr`
	---@type boolean
	fuzzy = true,

	-- Enable grep-based search with `rg`
	---@type boolean
	grep = true,

	-- Enable classic-find with `find`
	-- NOTE: find is not implemented yet
	---@type boolean
	find = true,

	-- Length of search history. Set to 0 to disable history
	-- NOTE: History saving is not implemented yet
	---@type integer
	history = 128,

	---@class (exact) Rabbit*Forage.Options.Oxide
	oxide = {
		-- Maximum age of a frequently accessed file, similar to Zoxide's AGING algorithm
		---@type integer
		max_age = 1000,

		-- Do not display files outside of the current working directory
		-- NOTE: This only works if the `cwd` function returns a directory.
		--	   If not, then this option is ignored.
		---@type boolean
		children_only = true,
	},

	-- Scope directory, eg use the git project folder, if it exists
	---@type string | fun(): string
	cwd = require("rabbit.util.paths").git,
}
```

## Change log
- `r0.0b1`: Apr 29, 2025
	- Fixed Bugs
		- Improper field selection
		- Field content is now trimmed to fit
		- The `grep` option is now honored
		- Pressing `-` now brings you to the forage home
	- Known Issues
		- *none*
	- New Features
		- Fuzzy find search!
		- Fuzzy find warns if `fzr` is not available
			- This should never happen because `fzr` is bundled with Rabbit
- `r0.0a2`: Apr 27, 2025
	- Fixed Bugs
		- Oxide move to top upon delete
		- Oxide not saving
		- Oxide erroneous sort
		- Oxide crashing if deleted file during session
	- Known Issues
		- *none*
	- New Features
		- Ripgrep search!
		- Ripgrep warns if `rg` is not available
- `r0.0a1`: Apr 15, 2025
	- Fixed Bugs
		- *none*
	- Known Issues
		- *none*
	- New Features
		- Initial release
		- Implemented oxide

