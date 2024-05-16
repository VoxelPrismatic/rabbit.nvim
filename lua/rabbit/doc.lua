---@alias VimHighlight string
---@describe VimHighlight highlight group name
--.

---@class RabbitColor
---@field title VimHighlight Vim highlight group name.
---@field box VimHighlight Vim highlight group name.
---@field index VimHighlight Vim highlight group name.
---@field dir VimHighlight Vim highlight group name.
---@field file VimHighlight Vim highlight group name.
---@field noname VimHighlight Vim highlight group name.
--.


---@class RabbitKeys
---@field quit string[]
---@field confirm string[]
---@field open string[]
--.


---@class RabbitWindow
---@field title string
---@field emphasis_width number
---@field width number
---@field height number
--.


---@class RabbitPaths
---@field min_visible integer
---@field rollover integer
---@field overflow string
--.


---@class RabbitOptions
---@field color RabbitColor
---@field box RabbitBox
---@field window RabbitWindow
---@field keys RabbitKeys
---@field paths RabbitPaths
--.


---@class RabbitBox
---@field top_left string
---@field top_right string
---@field bottom_left string
---@field bottom_right string
---@field vertical string
---@field horizontal string
---@field emphasis string
--.


---@class ScreenSpec
---@field expand? boolean - Place this at the right edge (should only be in last call)
---@field color VimHighlight Vim highlight group name
---@field text string | table
---@field [1] ScreenSpec
--.


---@alias winnr integer | nil
---@alias bufnr integer | nil
---@alias filepath string
--.


---@class RabbitHistory
---@field [winnr] bufnr[]
--.
