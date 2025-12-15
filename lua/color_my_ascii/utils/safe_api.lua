---@module 'color_my_ascii.utils.safe_api'
---@brief Safe API wrapper for Neovim API calls with error handling
---@description
--- This module provides safe wrappers around Neovim API functions with:
--- - Automatic error handling via pcall
--- - Type validation for arguments
--- - Handle validation for buffers and windows
--- - Consistent error return format
--- - Logging support for debugging
---
--- All functions return a success boolean and either result or error message.
--- Format: (success: boolean, result: any|nil, error: string|nil)

local M = {}

local api = vim.api

--- Safe call wrapper for any function
--- Wraps function call in pcall and returns consistent result format
---@param fn function Function to call safely
---@param ... any Arguments to pass to function
---@return boolean success True if function executed without error
---@return any|nil result Function result if successful, nil otherwise
---@return string|nil error Error message if function failed
local function safe_call(fn, ...)
  local ok, result = pcall(fn, ...)
  if ok then
    return true, result, nil
  else
    return false, nil, tostring(result)
  end
end

--- Validate buffer handle
--- Checks if buffer number is valid and buffer exists
---@param bufnr integer Buffer number to validate
---@return boolean valid True if buffer is valid
---@return string|nil error Error message if validation failed
local function validate_buffer(bufnr)
  if type(bufnr) ~= 'number' then
    return false, string.format('Invalid buffer type: expected number, got %s', type(bufnr))
  end

  if bufnr < 0 then
    return false, string.format('Invalid buffer number: %d (must be >= 0)', bufnr)
  end

  local is_valid = api.nvim_buf_is_valid(bufnr)
  if not is_valid then
    return false, string.format('Buffer %d is not valid or has been deleted', bufnr)
  end

  return true, nil
end

--- Validate window handle
--- Checks if window number is valid and window exists
---@param winnr integer Window number to validate
---@return boolean valid True if window is valid
---@return string|nil error Error message if validation failed
local function validate_window(winnr)
  if type(winnr) ~= 'number' then
    return false, string.format('Invalid window type: expected number, got %s', type(winnr))
  end

  if winnr < 0 then
    return false, string.format('Invalid window number: %d (must be >= 0)', winnr)
  end

  local is_valid = api.nvim_win_is_valid(winnr)
  if not is_valid then
    return false, string.format('Window %d is not valid or has been closed', winnr)
  end

  return true, nil
end

--- Safe buffer line getter
--- Get lines from buffer with validation and error handling
---@param bufnr integer Buffer number
---@param start integer Start line (0-indexed, inclusive)
---@param end_ integer End line (0-indexed, exclusive), -1 for end of buffer
---@param strict_indexing boolean Whether to use strict indexing
---@return boolean success
---@return string[]|nil lines Buffer lines if successful
---@return string|nil error Error message if failed
function M.buf_get_lines(bufnr, start, end_, strict_indexing)
  -- Validate buffer
  local valid, err = validate_buffer(bufnr)
  if not valid then
    return false, nil, err
  end

  -- Validate line numbers
  if type(start) ~= 'number' or type(end_) ~= 'number' then
    return false, nil, 'Start and end must be numbers'
  end

  -- Safe API call
  return safe_call(api.nvim_buf_get_lines, bufnr, start, end_, strict_indexing)
end

--- Safe buffer line count getter
--- Get number of lines in buffer with validation
---@param bufnr integer Buffer number
---@return boolean success
---@return integer|nil count Line count if successful
---@return string|nil error Error message if failed
function M.buf_line_count(bufnr)
  local valid, err = validate_buffer(bufnr)
  if not valid then
    return false, nil, err
  end

  return safe_call(api.nvim_buf_line_count, bufnr)
end

--- Safe buffer option getter
--- Get buffer option value with validation
---@param bufnr integer Buffer number
---@param name string Option name
---@return boolean success
---@return any|nil value Option value if successful
---@return string|nil error Error message if failed
function M.buf_get_option(bufnr, name)
  local valid, err = validate_buffer(bufnr)
  if not valid then
    return false, nil, err
  end

  if type(name) ~= 'string' or name == '' then
    return false, nil, 'Option name must be a non-empty string'
  end

  return safe_call(api.nvim_get_option_value, name, { buf = bufnr })
end

--- Safe buffer option setter
--- Set buffer option value with validation
---@param bufnr integer Buffer number
---@param name string Option name
---@param value any Option value
---@return boolean success
---@return nil result Always nil
---@return string|nil error Error message if failed
function M.buf_set_option(bufnr, name, value)
  local valid, err = validate_buffer(bufnr)
  if not valid then
    return false, nil, err
  end

  if type(name) ~= 'string' or name == '' then
    return false, nil, 'Option name must be a non-empty string'
  end

  return safe_call(api.nvim_set_option_value, name, value, { buf = bufnr })
end

--- Safe extmark setter
--- Create extmark with validation and error handling
---@param bufnr integer Buffer number
---@param ns_id integer Namespace ID
---@param line integer Line number (0-indexed)
---@param col integer Column number (0-indexed)
---@param opts table Extmark options
---@return boolean success
---@return integer|nil id Extmark ID if successful
---@return string|nil error Error message if failed
function M.buf_set_extmark(bufnr, ns_id, line, col, opts)
  local valid, err = validate_buffer(bufnr)
  if not valid then
    return false, nil, err
  end

  -- Validate arguments
  if type(ns_id) ~= 'number' then
    return false, nil, 'Namespace ID must be a number'
  end

  if type(line) ~= 'number' or line < 0 then
    return false, nil, 'Line must be a non-negative number'
  end

  if type(col) ~= 'number' or col < 0 then
    return false, nil, 'Column must be a non-negative number'
  end

  if type(opts) ~= 'table' then
    return false, nil, 'Options must be a table'
  end

  return safe_call(api.nvim_buf_set_extmark, bufnr, ns_id, line, col, opts)
end

--- Safe namespace clear
--- Clear all extmarks in namespace with validation
---@param bufnr integer Buffer number
---@param ns_id integer Namespace ID
---@param line_start integer Start line (0-indexed, inclusive)
---@param line_end integer End line (0-indexed, exclusive)
---@return boolean success
---@return nil result Always nil
---@return string|nil error Error message if failed
function M.buf_clear_namespace(bufnr, ns_id, line_start, line_end)
  local valid, err = validate_buffer(bufnr)
  if not valid then
    return false, nil, err
  end

  if type(ns_id) ~= 'number' then
    return false, nil, 'Namespace ID must be a number'
  end

  return safe_call(api.nvim_buf_clear_namespace, bufnr, ns_id, line_start, line_end)
end

--- Safe window option getter
--- Get window option value with validation
---@param winnr integer Window number
---@param name string Option name
---@return boolean success
---@return any|nil value Option value if successful
---@return string|nil error Error message if failed
function M.win_get_option(winnr, name)
  local valid, err = validate_window(winnr)
  if not valid then
    return false, nil, err
  end

  if type(name) ~= 'string' or name == '' then
    return false, nil, 'Option name must be a non-empty string'
  end

  return safe_call(api.nvim_get_option_value, name, { win = winnr })
end

--- Safe window option setter
--- Set window option value with validation
---@param winnr integer Window number
---@param name string Option name
---@param value any Option value
---@return boolean success
---@return nil result Always nil
---@return string|nil error Error message if failed
function M.win_set_option(winnr, name, value)
  local valid, err = validate_window(winnr)
  if not valid then
    return false, nil, err
  end

  if type(name) ~= 'string' or name == '' then
    return false, nil, 'Option name must be a non-empty string'
  end

  return safe_call(api.nvim_set_option_value, name, value, { win = winnr })
end

--- Safe window buffer getter
--- Get buffer associated with window
---@param winnr integer Window number
---@return boolean success
---@return integer|nil bufnr Buffer number if successful
---@return string|nil error Error message if failed
function M.win_get_buf(winnr)
  local valid, err = validate_window(winnr)
  if not valid then
    return false, nil, err
  end

  return safe_call(api.nvim_win_get_buf, winnr)
end

--- Safe window close
--- Close window with validation
---@param winnr integer Window number
---@param force boolean Force close even if modified
---@return boolean success
---@return nil result Always nil
---@return string|nil error Error message if failed
function M.win_close(winnr, force)
  local valid, err = validate_window(winnr)
  if not valid then
    return false, nil, err
  end

  return safe_call(api.nvim_win_close, winnr, force)
end

--- Safe buffer delete
--- Delete buffer with validation
---@param bufnr integer Buffer number
---@param opts table Delete options (force, unload)
---@return boolean success
---@return nil result Always nil
---@return string|nil error Error message if failed
function M.buf_delete(bufnr, opts)
  local valid, err = validate_buffer(bufnr)
  if not valid then
    return false, nil, err
  end

  opts = opts or {}
  if type(opts) ~= 'table' then
    return false, nil, 'Options must be a table'
  end

  return safe_call(api.nvim_buf_delete, bufnr, opts)
end

--- Check if buffer is valid (without pcall overhead)
--- Fast validation check for performance-critical paths
---@param bufnr integer Buffer number
---@return boolean valid True if buffer is valid
function M.is_valid_buffer(bufnr)
  if type(bufnr) ~= 'number' or bufnr < 0 then
    return false
  end
  return api.nvim_buf_is_valid(bufnr)
end

--- Check if window is valid (without pcall overhead)
--- Fast validation check for performance-critical paths
---@param winnr integer Window number
---@return boolean valid True if window is valid
function M.is_valid_window(winnr)
  if type(winnr) ~= 'number' or winnr < 0 then
    return false
  end
  return api.nvim_win_is_valid(winnr)
end

--- Safe execution with automatic retry
--- Retries operation if it fails due to invalid handle
---@param fn function Function to execute
---@param max_retries integer Maximum number of retries
---@param ... any Arguments to pass to function
---@return boolean success
---@return any|nil result
---@return string|nil error
function M.with_retry(fn, max_retries, ...)
  local args = {...}

  for attempt = 1, max_retries do
    local success, result, err = safe_call(fn, unpack(args))

    if success then
      return true, result, nil
    end

    -- Don't retry if error is not handle-related
    if err and not err:match('invalid') and not err:match('closed') then
      return false, nil, err
    end

    -- Small delay before retry
    if attempt < max_retries then
      vim.wait(10)
    end
  end

  return false, nil, 'Max retries exceeded'
end

return M
