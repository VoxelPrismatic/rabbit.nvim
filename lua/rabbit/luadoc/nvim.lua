---@class NvimHlKwargs
---@field fg? string Foreground color name or "#RRGGBB"
---@field bg? string Background color name or "#RRGGBB"
---@field sp? string Space color name or "#RRGGBB"
---@field blend? integer Opacity between 0 and 100
---@field bold? boolean **Bold** text
---@field standout? boolean
---@field underline? boolean __Underline__ text
---@field undercurl? boolean __Underline__, but curled like misspelled words
---@field underdouble? boolean __Underline__, but double underline
---@field underdotted? boolean __Underline__, but dotted underline
---@field underdashed? boolean __Underline__, but dashed underline
---@field strikethrough? boolean ~~Strike~~
---@field italic? boolean *Italic* text
---@field reverse? boolean Reverse FG and BG
---@field nocombine? boolean
---@field link? string Link to another highlight group name
---@field default? boolean Don't override existing definition
---@field ctermfg? string Sets foreground of cterm color
---@field ctermbg? string Sets background of cterm color
---@field cterm? NvimHlKwargs cterm attr map
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

