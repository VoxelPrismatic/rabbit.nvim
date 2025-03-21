---@class Rabbit.UI.Rect
---@field x number X position.
---@field y number Y position.
---@field w number Width.
---@field h number Height.
---@field T? number Y position of top border.
---@field B? number Y position of bottom border.
---@field L? number X position of left border.
---@field R? number X position of right border.
---@field split? string
---@field z? number Z-index

---@class Rabbit.UI.Workspace
---@field win? integer Window ID.
---@field buf? integer Buffer ID.
---@field ns? integer Highlight Namespace ID.
---@field view? vim.fn.winsaveview.ret Window viewport details.
---@field conf? vim.api.keyset.win_config Window configuration details.
---@field children? Rabbit.UI.Workspace[]
---@field add_child? fun(self: Rabbit.UI.Workspace, child: Rabbit.UI.Workspace): Rabbit.UI.Workspace Adds a child workspace and returns it.
---@field close? fun(self: Rabbit.UI.Workspace)
