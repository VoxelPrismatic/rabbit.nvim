---@class Rabbit.Message.Options: Rabbit.Message
---@field type "options"
---@field options Rabbit.Message.Options.Option[]

---@class (exact) Rabbit.Message.Options.Option
---@field type string
---@field label string Label
---@field synopsis string Description

---@class (exact) Rabbit.Message.Options.Radial: Rabbit.Message.Options.Option
---@field type "single"
---@field style
---| "radial" # Enabled:  | Disabled: 
---| "dropdown" # Use autocomplete to fill
---@field options table<string, boolean> Radial options. Will be sorted alphabetically
---@field opt_synopsis table<string, string> Option synopses

---@class (exact) Rabbit.Message.Options.Checkbox: Rabbit.Message.Options.Option
---@field type "checkbox"
---@field style
---| "box" # Enabled:  | Disabled: ; Default
---| "toggle" # Enabled:  | Disabled: ; Warning: Difficult to see at small font sizes
---@field options table<string, boolean> Checkbox options. Will be sorted alphabetically
---@field opt_synopsis table<string, string> Option synopses

---@class (exact) Rabbit.Message.Options.Reorder: Rabbit.Message.Options.Option
---@field type "reorder"
---@field options string[] Options in order
---@field opt_synopsis table<string, string> Option synopses

---@class (exact) Rabbit.Message.Options.Text: Rabbit.Message.Options.Option
---@field type "text"
---@field default string
