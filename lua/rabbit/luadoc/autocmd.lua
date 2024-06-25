---@class Rabbit.Autocmd
---@field attached string[] List of attached autocmds to prevent duplicates


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
