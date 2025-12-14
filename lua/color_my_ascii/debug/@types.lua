---@module 'color_my_ascii.debug.types'

---@class DebugConfig
---@field enabled boolean Whether debug module is active
---@field verbose boolean Enable verbose output
---@field log_file string|nil Optional log file path

---@class CharInspectResult
---@field char string The character being inspected
---@field groups string[] Groups this character belongs to
---@field highlight string|ColorMyAscii.CustomHighlight|nil Current highlight group
---@field override boolean Whether this is an override

---@class GroupInspectResult
---@field name string Group name
---@field chars string[]|ColorMyAscii.CharGroup Characters in this group
---@field highlight string|ColorMyAscii.CustomHighlight Highlight group
---@field count integer Number of characters
