local TS = {}

---@param query vim.treesitter.Query Highlight query
---@param source string Source code
---@param err? string Error string
---@param tree TSTree Tree to parse
---@param chunks? Rabbit.Term.HlLine[] Chunks to fill. Will be modified
---@return Rabbit.Term.HlLine[]
local function produce_lines(source, query, err, tree, chunks)
	if err ~= nil then
		error(err)
	end

	chunks = chunks or {} ---@type Rabbit.Term.HlLine[]
	local line = ""
	local last_chunk = {} ---@type Rabbit.Term.HlLine[]
	local last_token = {}
	local last_byte = -1
	local hls = query.captures
	local lang = query.lang

	for id, node in query:iter_captures(tree:root(), source) do
		local row, col, byte = node:start()
		local _, _, ebyte = node:end_()
		while row >= #chunks do
			line = ""
			last_chunk = {}
			table.insert(chunks, last_chunk)
		end

		local hl = hls[id]
		if hl ~= nil then
			hl = "@" .. hl .. "." .. lang
		end

		if byte == last_byte then
			local highlights = last_token.hl
			assert(type(highlights) == "table", "Unreachable")
			table.insert(highlights, hl)
		else
			local diff = col - #line
			last_token = {
				text = source:sub(byte - diff + 1, byte) .. source:sub(byte + 1, ebyte),
				hl = { hl },
			}
			table.insert(last_chunk, last_token)
			line = line .. last_token.text
			last_byte = byte
		end
	end

	return chunks
end

-- Generates highlight groups for the given language. This can be passed to HL.set_lines(...)
-- **WARNING**: Only the first tree parsed will be used. Any additional trees will be ignored.
---@param lang string | Rabbit.Treesitter Language
---@param source string Source (stuff to highlight)
---@param callback fun(lines: Rabbit.Term.HlLine[])
---@return Rabbit.Term.HlLine[] lines
---@overload fun(lang: string | Rabbit.Treesitter, source: string, callback: false): Rabbit.Term.HlLine[] "Run synchronously"
function TS.parse(lang, source, callback)
	if type(lang) ~= "string" then
		lang = lang.lang
	end

	local parser = vim.treesitter.get_string_parser(source, lang)
	local query = vim.treesitter.query.get(lang, "highlights")
	assert(query ~= nil, "No highlighting available for " .. lang)
	local sync_mode = vim.g._ts_force_sync_parsing
	local chunks = {} ---@type Rabbit.Term.HlLine[]

	if callback == false then
		vim.g._ts_force_sync_parsing = true
		local trees = parser:parse(true)
		assert(trees ~= nil, "Failed to parse")
		produce_lines(source, query, nil, trees[1], chunks)
		vim.g._ts_force_sync_parsing = sync_mode
	else
		parser:parse(true, function(err, trees)
			produce_lines(source, query, err, trees[1], chunks)
			callback(chunks)
		end)
	end

	return chunks
end

---@class Rabbit.Treesitter
---@field lang string Language
---@field parse fun(self: Rabbit.Treesitter, source: string, callback: false | fun(lines: Rabbit.Term.HlLine[]))

-- If nil, there is no parser for lang
---@type table<string, Rabbit.Treesitter?>
TS.parsers_by_filetype = setmetatable({}, {
	__index = function(self, lang)
		if lang == nil then
			return nil
		end
		local ok, _ = pcall(vim.treesitter.get_string_parser, "", lang)
		if not ok then
			-- No parser for lang
			return nil
		end
		rawset(self, lang, {
			lang = lang,
			parse = TS.parse,
		})
		return rawget(self, lang)
	end,
})

---@type table<string, Rabbit.Treesitter?>
TS.parser_from_filename = setmetatable({}, {
	__index = function(self, filename)
		local lang = vim.filetype.match({ filename = filename })
		rawset(self, filename, TS.parsers_by_filetype[lang])
		return TS.parsers_by_filetype[lang]
	end,
})

-- Uses nvim_echo so you can see for yourself what's going on
-- **WARNING**: This function does not support layered highlight groups.
-- Only the last highlight group will be applied when passing to nvim_echo.
---@param lines Rabbit.Term.HlLine[]
function TS.test_print(lines)
	for _, line in ipairs(lines) do
		local chunks = {}
		for _, chunk in ipairs(line) do
			table.insert(chunks, { chunk.text, chunk.hl[#chunk.hl] })
		end
		if #chunks == 0 then
			table.insert(chunks, { " " })
		end
		vim.api.nvim_echo(chunks, true, {})
	end
end

return TS
