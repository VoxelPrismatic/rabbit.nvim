---@alias VimHighlight string
---@describe VimHighlight highlight group name
--.

---@class RabbitColor
---@field title VimHighlight Vim highlight group name.
---@field box RabbitBoxColor
---@field index VimHighlight Vim highlight group name.
---@field dir VimHighlight Vim highlight group name.
---@field file VimHighlight Vim highlight group name.
---@field noname VimHighlight Vim highlight group name.
---@field shell VimHighlight Vim highlight group name.
--.


---@class RabbitBoxColor
---@field [ValidMode] VimHighlight Vim highlight group name.
--.


---@class RabbitKeys
---@field quit string[]
---@field confirm string[]
---@field open string[]
---@field to RabbitModeKeys
--.


---@class RabbitModeKeys
---@field [ValidMode] string
--.

---@class RabbitWindow
---@field title string
---@field emphasis_width number
---@field width number
---@field height number
---@field float RabbitCornerPin | RabbitCornerOffset | false | true
---@field split "left" | "right" | "above" | "below" | false | true
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
---@field expand? boolean | string - Place this at the right edge (should only be in last call)
---@field color VimHighlight Vim highlight group name
---@field text string | table
---@field [1] ScreenSpec
--.


---@alias winnr integer | nil
---@alias bufnr integer | nil
---@alias hlns integer | nil
---@alias filepath string
--.


---@class RabbitWS
---@field win winnr
---@field buf bufnr
---@field ns hlns
--.

---@class RabbitHistory
---@field [winnr] bufnr[]
--.


---@class RabbitReopen
---@field [winnr] filepath[]
--.



---@class RabbitCornerPin
---@field [1] "bottom" | "top"
---@field [2] "left" | "right"
--.


---@class RabbitCornerOffset
---@field top integer
---@field left integer
--.


---@class RabbitContext
---@field border_color VimHighlight Vim highlight group name
---@field listing RabbitHistory | RabbitReopen
---@field mode ValidMode
--.


---@alias ValidMode "history" | "reopen"


---@class RabbitListing
---@field history RabbitHistory
---@field reopen RabbitReopen
--.
