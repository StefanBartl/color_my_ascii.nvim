---@module 'color_my_ascii.debug'
---@brief Debug module for color_my_ascii.nvim
---@description
--- Provides debugging utilities for inspecting configuration, groups, and character mappings.
--- Only loaded when debug mode is enabled in configuration.

local M = {}

---@type DebugConfig|nil
local debug_state = nil

---Check if debug module is enabled
---@return boolean
local function is_enabled()
  local cfg = require('color_my_ascii.config').get()
  return cfg.debug_enabled == true
end

---Initialize debug module
---@param config DebugConfig
---@return nil
function M.setup(config)
  if not is_enabled() then
    return
  end

  debug_state = vim.tbl_deep_extend('force', {
    enabled = true,
    verbose = false,
    log_file = nil,
  }, config or {})

  -- Register commands only if enabled
  require('color_my_ascii.debug.commands').register()
end

---Print debug message if verbose mode enabled
---@param ... any
---@return nil
function M.log(...)
  if not debug_state or not debug_state.verbose then
    return
  end

  local msg = table.concat(vim.tbl_map(vim.inspect, {...}), ' ')
  print('[color_my_ascii.debug]', msg)

  if debug_state.log_file then
    local file = io.open(debug_state.log_file, 'a')
    if file then
      file:write(tostring(os.date('%Y-%m-%d %H:%M:%S ')), msg, '\n')
      file:close()
    end
  end
end

---Get current debug state
---@return DebugConfig|nil
function M.get_state()
  return debug_state
end

return M
