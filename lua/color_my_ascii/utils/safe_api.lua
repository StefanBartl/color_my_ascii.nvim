---@module 'color_my_ascii.utils.safe_api'
--- Safe wrapper around Neovim API calls with error handling.
---
--- Re-exports lib.nvim.safe_api, which this module's own implementation was
--- upstreamed into (identical function set). All functions return a success
--- boolean and either result or error message.
--- Format: (success: boolean, result: any|nil, error: string|nil)

return require('lib.nvim.safe_api')
