---@class Rabbit.Message.Options: Rabbit.Message
---@field type "options"
---@field options Rabbit.Message.Options.Option[]

---@class (exact) Rabbit.Message.Options.Option
---@field type string
---@field label Rabbit.Entry._.Label Label
---@field synopsis? string Description

---@class (exact) Rabbit.Message.Options.List: Rabbit.Message.Options.Option
---@field type "list"
---@field style Rabbit.Message.Options.Single.Style Display style
---@field entries Rabbit.Message.Options.Plenty[]

---@class Rabbit.Message.Options.Plenty
---@field label Rabbit.Entry._.Label Entry label
---@field synopsis? string Entry description
---@field state boolean | 0 Entry state
---@field tri boolean
---| true # Enable tri-state (enabled, disabled, default)
---| false # Disable tri-state
---| 0 # Treat disabled state as floating state
---@field single boolean Whether to allow only one option

---@class (exact) Rabbit.Message.Options.Single.Style
---@field set string Enabled string (eg  or )
---@field float string Default state string (eg  or )
---@field reset string Disabled state string (eg  or )
