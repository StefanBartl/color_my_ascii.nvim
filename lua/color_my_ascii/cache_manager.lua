---@module 'color_my_ascii.cache_manager'
---@brief Caching system for parsed blocks and highlighting data
---@description
--- Implements a memory-efficient caching system with:
--- - Weak table for automatic memory reclamation
--- - Timestamp-based cache invalidation
--- - Per-buffer cache management
--- - Cache statistics for monitoring
---
--- The cache stores parsed ASCII blocks to avoid redundant parsing operations.
--- Invalidation occurs on text changes or after a timeout period.

local M = {}

--- Cache entry structure
---@class CacheEntry
---@field blocks ColorMyAscii.Block[] Parsed ASCII blocks
---@field inline_codes ColorMyAscii.InlineCode[] Parsed inline code segments
---@field timestamp number Cache creation timestamp (ms)
---@field changedtick number Buffer changedtick at cache time
---@field line_count integer Number of lines in buffer at cache time

--- Cache storage with weak keys for automatic cleanup
---@type table<integer, CacheEntry>
local cache = setmetatable({}, { __mode = 'k' })

--- Cache configuration
---@class CacheConfig
---@field timeout integer Cache validity timeout in milliseconds
---@field max_size integer Maximum number of cached buffers
---@field enable_stats boolean Whether to collect statistics
local config = {
  timeout = 5000,        -- 5 seconds
  max_size = 50,         -- Maximum 50 buffers
  enable_stats = false,  -- Disabled by default
}

--- Cache statistics
---@class CacheStats
---@field hits integer Number of cache hits
---@field misses integer Number of cache misses
---@field invalidations integer Number of cache invalidations
---@field evictions integer Number of cache evictions
local stats = {
  hits = 0,
  misses = 0,
  invalidations = 0,
  evictions = 0,
}

--- Configure cache behavior
---@param opts CacheConfig Configuration options
---@return nil
function M.configure(opts)
  if type(opts) ~= 'table' then
    return
  end

  if type(opts.timeout) == 'number' and opts.timeout > 0 then
    config.timeout = opts.timeout
  end

  if type(opts.max_size) == 'number' and opts.max_size > 0 then
    config.max_size = opts.max_size
  end

  if type(opts.enable_stats) == 'boolean' then
    config.enable_stats = opts.enable_stats
  end
end

--- Get buffer metadata for cache validation
---@param bufnr integer Buffer number
---@return integer|nil changedtick Buffer changedtick
---@return integer|nil line_count Number of lines
local function get_buffer_metadata(bufnr)
  local safe_api = require('color_my_ascii.utils.safe_api')

  -- Get changedtick
  local ok, changedtick = pcall(vim.api.nvim_buf_get_changedtick, bufnr)
  if not ok then
    return nil, nil
  end

  -- Get line count
  local success, count = safe_api.buf_line_count(bufnr)
  if not success then
    return changedtick, nil
  end

  return changedtick, count
end

--- Check if cache entry is still valid
---@param bufnr integer Buffer number
---@param entry CacheEntry Cache entry to validate
---@return boolean valid True if cache is valid
---@return string|nil reason Reason for invalidation
local function is_valid(bufnr, entry)
  -- Check timestamp
  local now = vim.loop.now()
  if (now - entry.timestamp) > config.timeout then
    return false, 'timeout'
  end

  -- Check buffer metadata
  local changedtick, line_count = get_buffer_metadata(bufnr)

  if not changedtick then
    return false, 'buffer_invalid'
  end

  if changedtick ~= entry.changedtick then
    return false, 'content_changed'
  end

  if line_count and line_count ~= entry.line_count then
    return false, 'line_count_changed'
  end

  return true, nil
end

--- Get cached data for buffer
---@param bufnr integer Buffer number
---@return ColorMyAscii.Block[]|nil blocks Cached blocks or nil
---@return ColorMyAscii.InlineCode[]|nil inline_codes Cached inline codes or nil
---@return boolean hit True if cache hit
function M.get(bufnr)
  -- Validate buffer
  if type(bufnr) ~= 'number' or bufnr < 0 then
    return nil, nil, false
  end

  local entry = cache[bufnr]

  -- Cache miss
  if not entry then
    if config.enable_stats then
      stats.misses = stats.misses + 1
    end
    return nil, nil, false
  end

  -- Validate entry
  local valid, _ = is_valid(bufnr, entry)

  if not valid then
    -- Invalidate
    cache[bufnr] = nil

    if config.enable_stats then
      stats.invalidations = stats.invalidations + 1
      stats.misses = stats.misses + 1
    end

    return nil, nil, false
  end

  -- Cache hit
  if config.enable_stats then
    stats.hits = stats.hits + 1
  end

  return entry.blocks, entry.inline_codes, true
end

--- Store data in cache
---@param bufnr integer Buffer number
---@param blocks ColorMyAscii.Block[] Parsed blocks
---@param inline_codes ColorMyAscii.InlineCode[] Parsed inline codes
---@return boolean success True if data was cached
function M.set(bufnr, blocks, inline_codes)
  -- Validate input
  if type(bufnr) ~= 'number' or bufnr < 0 then
    return false
  end

  if type(blocks) ~= 'table' or type(inline_codes) ~= 'table' then
    return false
  end

  -- Check cache size and evict if needed
  local cache_size = 0
  for _ in pairs(cache) do
    cache_size = cache_size + 1
  end

  if cache_size >= config.max_size then
    -- Evict oldest entry
    local oldest_bufnr = nil
    local oldest_timestamp = math.huge

    for buf, entry in pairs(cache) do
      if entry.timestamp < oldest_timestamp then
        oldest_timestamp = entry.timestamp
        oldest_bufnr = buf
      end
    end

    if oldest_bufnr then
      cache[oldest_bufnr] = nil

      if config.enable_stats then
        stats.evictions = stats.evictions + 1
      end
    end
  end

  -- Get buffer metadata
  local changedtick, line_count = get_buffer_metadata(bufnr)

  if not changedtick then
    return false
  end

  -- Store entry
  cache[bufnr] = {
    blocks = blocks,
    inline_codes = inline_codes,
    timestamp = vim.loop.now(),
    changedtick = changedtick,
    line_count = line_count or 0,
  }

  return true
end

--- Invalidate cache for specific buffer
---@param bufnr integer Buffer number
---@return boolean success True if cache was invalidated
function M.invalidate(bufnr)
  if type(bufnr) ~= 'number' or bufnr < 0 then
    return false
  end

  local had_entry = cache[bufnr] ~= nil
  cache[bufnr] = nil

  if had_entry and config.enable_stats then
    stats.invalidations = stats.invalidations + 1
  end

  return had_entry
end

--- Clear all cache entries
---@return integer count Number of entries cleared
function M.clear_all()
  local count = 0

  for bufnr in pairs(cache) do
    cache[bufnr] = nil
    count = count + 1
  end

  if config.enable_stats then
    stats.invalidations = stats.invalidations + count
  end

  return count
end

--- Get cache statistics
---@return CacheStats stats Cache statistics
function M.get_stats()
  return vim.deepcopy(stats)
end

--- Reset cache statistics
---@return nil
function M.reset_stats()
  stats.hits = 0
  stats.misses = 0
  stats.invalidations = 0
  stats.evictions = 0
end

--- Get cache hit rate
---@return number hit_rate Hit rate as percentage (0-100)
function M.get_hit_rate()
  local total = stats.hits + stats.misses

  if total == 0 then
    return 0
  end

  return (stats.hits / total) * 100
end

--- Get current cache size
---@return integer size Number of cached buffers
function M.get_size()
  local size = 0

  for _ in pairs(cache) do
    size = size + 1
  end

  return size
end

--- Get cache configuration
---@return CacheConfig config Current configuration
function M.get_config()
  return vim.deepcopy(config)
end

--- Clean up expired entries
--- Should be called periodically to free memory
---@return integer cleaned Number of entries cleaned
function M.cleanup()
  local cleaned = 0
  local now = vim.loop.now()

  for bufnr, entry in pairs(cache) do
    -- Check if buffer is still valid
    local safe_api = require('color_my_ascii.utils.safe_api')

    if not safe_api.is_valid_buffer(bufnr) then
      cache[bufnr] = nil
      cleaned = cleaned + 1
    else
      -- Check timeout
      if (now - entry.timestamp) > config.timeout then
        cache[bufnr] = nil
        cleaned = cleaned + 1
      end
    end
  end

  if config.enable_stats and cleaned > 0 then
    stats.evictions = stats.evictions + cleaned
  end

  return cleaned
end

--- Setup periodic cleanup timer
--- Automatically cleans expired entries every interval
---@param interval integer|nil Cleanup interval in milliseconds
---@return uv.uv_timer_t|nil timer Timer handle or nil on failure
function M.setup_auto_cleanup(interval)
  interval = interval or 30000  -- Default 30 seconds

  local timer = vim.loop.new_timer()
  if timer == nil then
    return nil
  end

  timer:start(interval, interval, vim.schedule_wrap(function()
    M.cleanup()
  end))

  return timer
end

return M
