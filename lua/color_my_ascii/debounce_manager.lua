---@module 'color_my_ascii.debounce_manager'
---@brief Adaptive debouncing system for text change events
---@description
--- Implements smart debouncing with:
--- - File size-based adaptive delays
--- - Per-buffer timer management
--- - Automatic cleanup on buffer delete
--- - Configurable thresholds
---
--- Larger files get longer debounce delays to prevent performance issues.

local M = {}

--- Debounce configuration thresholds
---@class DebounceConfig
---@field small_file_threshold integer Line count threshold for small files
---@field medium_file_threshold integer Line count threshold for medium files
---@field small_delay integer Delay for small files (ms)
---@field medium_delay integer Delay for medium files (ms)
---@field large_delay integer Delay for large files (ms)
---@field min_delay integer Minimum debounce delay (ms)
---@field max_delay integer Maximum debounce delay (ms)
local config = {
  small_file_threshold = 500,
  medium_file_threshold = 2000,
  small_delay = 100,
  medium_delay = 200,
  large_delay = 500,
  min_delay = 50,
  max_delay = 1000,
}

--- Timer storage per buffer
---@type table<integer, table>
local timers = {}

--- Configure debounce behavior
---@param opts DebounceConfig Configuration options
---@return nil
function M.configure(opts)
  if type(opts) ~= 'table' then
    return
  end

  -- Update thresholds
  if type(opts.small_file_threshold) == 'number' and opts.small_file_threshold > 0 then
    config.small_file_threshold = opts.small_file_threshold
  end

  if type(opts.medium_file_threshold) == 'number' and opts.medium_file_threshold > 0 then
    config.medium_file_threshold = opts.medium_file_threshold
  end

  -- Update delays
  if type(opts.small_delay) == 'number' and opts.small_delay > 0 then
    config.small_delay = opts.small_delay
  end

  if type(opts.medium_delay) == 'number' and opts.medium_delay > 0 then
    config.medium_delay = opts.medium_delay
  end

  if type(opts.large_delay) == 'number' and opts.large_delay > 0 then
    config.large_delay = opts.large_delay
  end

  -- Update bounds
  if type(opts.min_delay) == 'number' and opts.min_delay > 0 then
    config.min_delay = opts.min_delay
  end

  if type(opts.max_delay) == 'number' and opts.max_delay > 0 then
    config.max_delay = opts.max_delay
  end
end

--- Calculate adaptive delay based on buffer size
---@param bufnr integer Buffer number
---@return integer delay Debounce delay in milliseconds
local function calculate_delay(bufnr)
  local safe_api = require('color_my_ascii.utils.safe_api')

  -- Get line count
  local success, line_count = safe_api.buf_line_count(bufnr)

  if not success or not line_count then
    -- Default to medium delay on error
    return config.medium_delay
  end

  -- Calculate delay based on file size
  local delay

  if line_count < config.small_file_threshold then
    delay = config.small_delay
  elseif line_count < config.medium_file_threshold then
    delay = config.medium_delay
  else
    -- For very large files, scale delay linearly
    local scale_factor = line_count / config.medium_file_threshold
    delay = math.floor(config.large_delay * math.min(scale_factor, 3))
  end

  -- Clamp to configured bounds
  delay = math.max(config.min_delay, math.min(config.max_delay, delay))

  return delay
end

--- Debounce a function call for a specific buffer
---@param bufnr integer Buffer number
---@param fn function Function to debounce
---@param custom_delay integer|nil Optional custom delay (overrides adaptive)
---@return nil
function M.debounce(bufnr, fn, custom_delay)
  -- Validate input
  if type(bufnr) ~= 'number' or bufnr < 0 then
    return
  end

  if type(fn) ~= 'function' then
    return
  end

  -- Clear existing timer
  if timers[bufnr] then
    timers[bufnr]:stop()
    timers[bufnr]:close()
    timers[bufnr] = nil
  end

  -- Calculate delay
  local delay = custom_delay or calculate_delay(bufnr)

  -- Create new timer
  timers[bufnr] = vim.defer_fn(function()
    -- Validate buffer before executing
    local safe_api = require('color_my_ascii.utils.safe_api')

    if safe_api.is_valid_buffer(bufnr) then
      -- Safe function execution
      local ok, err = pcall(fn)

      if not ok then
        vim.notify(
          string.format('color_my_ascii: Debounced function error: %s', err),
          vim.log.levels.WARN
        )
      end
    end

    -- Cleanup timer reference
    timers[bufnr] = nil
  end, delay)
end

--- Cancel pending debounced call for buffer
---@param bufnr integer Buffer number
---@return boolean cancelled True if timer was cancelled
function M.cancel(bufnr)
  if type(bufnr) ~= 'number' or bufnr < 0 then
    return false
  end

  if timers[bufnr] then
    timers[bufnr]:stop()
    timers[bufnr]:close()
    timers[bufnr] = nil
    return true
  end

  return false
end

--- Cancel all pending debounced calls
---@return integer count Number of cancelled timers
function M.cancel_all()
  local count = 0

  for bufnr, timer in pairs(timers) do
    timer:stop()
    timer:close()
    timers[bufnr] = nil
    count = count + 1
  end

  return count
end

--- Check if buffer has pending debounced call
---@param bufnr integer Buffer number
---@return boolean pending True if timer is pending
function M.is_pending(bufnr)
  return timers[bufnr] ~= nil
end

--- Get current delay for buffer
---@param bufnr integer Buffer number
---@return integer|nil delay Current calculated delay or nil
function M.get_delay(bufnr)
  if type(bufnr) ~= 'number' or bufnr < 0 then
    return nil
  end

  return calculate_delay(bufnr)
end

--- Get number of pending timers
---@return integer count Number of active timers
function M.get_pending_count()
  local count = 0

  for _ in pairs(timers) do
    count = count + 1
  end

  return count
end

--- Get debounce configuration
---@return DebounceConfig config Current configuration
function M.get_config()
  return vim.deepcopy(config)
end

--- Cleanup timers for deleted buffers
--- Should be called periodically or on BufDelete
---@return integer cleaned Number of cleaned timers
function M.cleanup()
  local safe_api = require('color_my_ascii.utils.safe_api')
  local cleaned = 0

  for bufnr, timer in pairs(timers) do
    if not safe_api.is_valid_buffer(bufnr) then
      timer:stop()
      timer:close()
      timers[bufnr] = nil
      cleaned = cleaned + 1
    end
  end

  return cleaned
end

--- Create debounced version of function
--- Returns a function that debounces calls per buffer
---@param fn function Function to debounce
---@param custom_delay integer|nil Optional fixed delay
---@return function debounced Debounced function
function M.create_debounced(fn, custom_delay)
  return function(bufnr, ...)
    local args = {...}

    M.debounce(bufnr, function()
      fn(bufnr, unpack(args))
    end, custom_delay)
  end
end

--- Setup automatic cleanup on buffer delete
---@return nil
function M.setup_auto_cleanup()
  local group = vim.api.nvim_create_augroup('ColorMyAsciiDebounce', { clear = true })

  vim.api.nvim_create_autocmd('BufDelete', {
    group = group,
    callback = function(args)
      M.cancel(args.buf)
    end,
    desc = 'Cleanup debounce timers on buffer delete',
  })
end

return M
