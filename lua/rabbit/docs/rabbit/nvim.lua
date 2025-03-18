---@class NvimHlKwargs: vim.api.keyset.highlight
---@field fg? string Foreground color name or "#RRGGBB" or ":HlGroupName"
---@field bg? string Background color name or "#RRGGBB" or ":HlGroupName"
---@field sp? string Underline color name or "#RRGGBB"
---@field blend? integer Opacity between 0 and 100
---@field bold? boolean **Bold** text
---@field standout? boolean Standout text, usually an alias for reverse
---@field underline? boolean __Underline__ text
---@field undercurl? boolean U᪶nd᪶er᪶cu᪶r᪶l text
---@field underdouble? boolean U͇n͇d͇e͇r͇d͇o͇u͇b͇l͇e͇ text
---@field underdotted? boolean Ṳn̤d̤e̤r̤d̤o̤t̤t̤e̤d̤ text
---@field underdashed? boolean U̱ṉḏe̱ṟḏa̱s̱ẖe̱ḏ text
---@field strikethrough? boolean ~~Strike~~
---@field italic? boolean *Italic* text
---@field reverse? boolean Reverse FG and BG
---@field nocombine? boolean Do not combine text decorations (underlines & strikes)
---@field link? string Link to another highlight group name
---@field default? boolean Don't override existing definition
---@field ctermfg? string Sets foreground of cterm color
---@field ctermbg? string Sets background of cterm color
---@field cterm? string[] Special attributes. Use the boolean values above instead.
---@field force? boolean Update the highlight group if it exists

---@class NvimEvent
---@field buf integer Buffer ID
---@field event string Event type
---@field file string File name
---@field id integer Event ID
---@field match string

---@class NvimEvent.BufAdd: NvimEvent
---@field buf integer Buffer ID or newly added buffer
---@field event "BufAdd" Event type
---@field file string File name of newly made buffer
---@field id integer Event ID
---@field match string Same as `file`

---@class NvimEvent.BufEnter: NvimEvent
---@field buf integer Buffer ID of buffer being entered
---@field event "BufEnter" Event type
---@field file string File name of buffer being entered
---@field id integer Event ID
---@field match string Same as `file`

---@class NvimEvent.BufDelete: NvimEvent
---@field buf integer Buffer ID of buffer being deleted (or hidden)
---@field event "BufDelete" Event type
---@field file string File name of buffer being deleted (or hidden)
---@field id integer Event ID
---@field match string Same as `file`

---@class NvimEvent.BufLeave: NvimEvent
---@field buf integer Buffer ID of buffer being left
---@field event "BufLeave" Event type
---@field file string File name of buffer being left
---@field id integer Event ID
---@field match string Same as `file`

---@class NvimEvent.BufNew: NvimEvent
---@field buf integer Buffer ID of newly made buffer
---@field event "BufNew" Event type
---@field file string File name of newly made buffer
---@field id integer Event ID
---@field match string Same as `file`

---@class NvimEvent.WinEnter: NvimEvent
---@field buf integer Focused buffer ID
---@field event "WinEnter" Event type
---@field file string File name of focused buffer
---@field id integer Event ID
---@field match string Same as `file`

---@class NvimEvent.WinLeave: NvimEvent
---@field buf integer Focused buffer ID
---@field event "WinLeave" Event type
---@field file string File name of focused buffer
---@field id integer Event ID
---@field match string Same as `file`

---@class NvimEvent.WinNew: NvimEvent
---@field buf integer Focused buffer ID
---@field event "WinNew" Event type
---@field file string File name of focused buffer
---@field id integer Event ID
---@field match string Same as `file`

---@class NvimEvent.WinScrolled: NvimEvent
---@field buf integer Buffer ID
---@field event "WinScrolled" Event type
---@field file string ID of the window being scrolled, as a string
---@field id integer Event ID
---@field match string Same as `file`

---@class NvimEvent.WinClosed: NvimEvent
---@field buf integer Buffer ID
---@field event "WinScrolled" Event type
---@field file string ID of the window being closed, as a string
---@field id integer Event ID
---@field match string Same as `file`

---@class NvimEvent.WinResized: NvimEvent
---@field buf integer Buffer ID
---@field event "WinResized" Event type
---@field file string ID of the window being resized, as a string
---@field id integer Event ID
---@field match string Same as `file`

---@class NvimEvent.ColorScheme: NvimEvent
---@field buf integer Buffer ID
---@field event "ColorScheme" Event type
---@field file "" Always empty string
---@field id integer Event ID
---@field match string Name of the color scheme being applied

---@class NvimEvent.ColorSchemePre: NvimEvent
---@field buf integer Buffer ID
---@field event "ColorSchemePre" Event type
---@field file "" Always empty string
---@field id integer Event ID
---@field match string Name of the previous color scheme

---@class NvimEvent.BufFilePre: NvimEvent
---@field buf integer Affected Buffer ID
---@field event "BufFilePre" Event type
---@field file string Old filename
---@field id integer Event ID
---@field match string Same as `file`

---@class NvimEvent.BufFilePost: NvimEvent
---@field buf integer Affected Buffer ID
---@field event "BufFilePost" Event type
---@field file string New filename
---@field id integer Event ID
---@field match string Same as `file`

---@class Rabbit.Event.Invalid: NvimEvent
---@field buf integer Buffer ID (rabbit.user.buf)
---@field event "RabbitInvalid" Event type
---@field file? string Buffer ID or file name, depending on `match`
---@field id integer Event ID
---@field match? "bufnr" | "filename" How to interpret `event`

---@class Rabbit.Event.FileRename: NvimEvent
---@field buf integer Affected Buffer ID
---@field event "RabbitFileRename" Event type
---@field file string New filename
---@field id integer Current window ID
---@field match string Old filename

---@class Rabbit.Event.Enter: NvimEvent
---@field buf integer Buffer ID (rabbit.user.buf)
---@field event "RabbitEnter" Event type
---@field file string Plugin name
---@field id integer Window ID
---@field match string Current working directory
