---@module 'color_my_ascii'
--- Main entry point for color_my_ascii.nvim plugin.
--- This module provides the public API for highlighting ASCII art in markdown files.
--- Implements safe error handling, caching, and adaptive debouncing.

local M = {}

local api = vim.api
local notify = require('lib.nvim.notify').create('[color_my_ascii]')
local autocmd = require('lib.nvim.bindings.autocmd')

---@type ColorMyAscii.State
local state = {
  enabled = true,
  buffers = {},
}

local config = require('color_my_ascii.config')
local parser = require('color_my_ascii.parser')
local fence_hl = require('color_my_ascii.fence_hl')

--- Public fenced-block API for other plugins (e.g. markdown.nvim) to consume.
--- Language-agnostic block detection with precise ranges + metadata; see
--- `color_my_ascii.api.fences`. Available without calling M.setup().
M.fences = require('color_my_ascii.api.fences')
local highlighter = require('color_my_ascii.highlighter')
local cache_manager = require('color_my_ascii.cache_manager')
local debounce_manager = require('color_my_ascii.debounce_manager')
local safe_api = require('color_my_ascii.utils.safe_api')

--- Initialize the plugin with user configuration
---@param opts? ColorMyAscii.Config User configuration options
---@return boolean success True if initialization succeeded
---@return string|nil error Error message if initialization failed
function M.setup(opts)
  -- Safe config setup with error recovery
  local ok, err = pcall(config.setup, opts)
  local cfg = require('color_my_ascii.config').get()

  if not ok and cfg.debug_enabled then
    notify.error(string.format('Failed to initialize configuration: %s', err))
    return false, tostring(err)
  end

  -- Setup cache / debouncing (user-overridable via cfg.cache / cfg.debounce).
  --
  -- `or {}`, not a fallback table repeating the defaults: both `configure`
  -- functions already merge field by field over the module's own defaults, so
  -- a copy of those defaults here was a second place for them to live -- and
  -- the two were already one edit away from disagreeing without anything
  -- noticing.
  cache_manager.configure(cfg.cache or {})
  debounce_manager.configure(cfg.debounce or {})

  -- Setup automatic cleanup
  debounce_manager.setup_auto_cleanup()

  -- Start cache cleanup timer (every 30 seconds)
  cache_manager.setup_auto_cleanup(30000)

  -- Attach optional user keymaps (disabled by default)
  if cfg.keymaps then
    require('color_my_ascii.bindings.keymaps').attach(cfg.keymaps)
  end

  -- Re-register static autocommands so a comment_ascii.filetypes list
  -- supplied here takes effect: the plugin/ bootstrap's own call to this
  -- happens with only the default config (before this setup() call, if any,
  -- has run). Re-callable: the augroup is cleared and rebuilt each time.
  require('color_my_ascii.bindings.autocmds').enable()

  -- Optional fence-line highlighting: resolve its highlight groups now and keep
  -- them in sync with colorscheme changes.
  fence_hl.setup_hl(cfg)
  autocmd.create('ColorScheme', function()
    fence_hl.setup_hl(require('color_my_ascii.config').get())
  end, {
    group = autocmd.augroup.create.clear('ColorMyAsciiFenceLineHl'),
    desc = 'Re-resolve color_my_ascii fence-line highlight groups after colorscheme change',
  })

  -- ASCII-art highlight groups (fixed-hex scheme colors) get wiped by
  -- :colorscheme's implicit `hi clear` too; re-apply them so highlighting
  -- doesn't go stale after a colorscheme switch.
  autocmd.create('ColorScheme', function()
    require('color_my_ascii.config').reapply_custom_highlights()
  end, {
    group = autocmd.augroup.create.clear('ColorMyAsciiHl'),
    desc = 'Re-apply color_my_ascii ASCII-art highlight groups after colorscheme change',
  })

  -- fence_*_highlight.right_pad insets the fence background from the window's
  -- text width, so it has to be recomputed when a window is resized.
  autocmd.create({ 'WinResized', 'VimResized' }, function()
    local c = require('color_my_ascii.config').get()
    local flh, fch = c.fence_line_highlight, c.fence_content_highlight
    if ((flh and flh.right_pad) or 0) <= 0 and ((fch and fch.right_pad) or 0) <= 0 then
      return
    end
    for _, win in ipairs(api.nvim_list_wins()) do
      local b = api.nvim_win_get_buf(win)
      if state.enabled and state.buffers[b] then
        pcall(fence_hl.apply, b, c)
      end
    end
  end, {
    group = autocmd.augroup.create.clear('ColorMyAsciiFenceResize'),
    desc = 'Recompute fence right-edge padding after a window resize',
  })

  -- Hot-reload: calling setup() again (e.g. after adding/editing a
  -- config.languages entry) invalidates the stale per-buffer parse cache and
  -- immediately re-highlights every already-managed buffer, so a changed
  -- definition takes effect without touching the buffer or restarting.
  if next(state.buffers) ~= nil then
    cache_manager.clear_all()
    for bufnr, _ in pairs(state.buffers) do
      if safe_api.is_valid_buffer(bufnr) then
        M.highlight_buffer(bufnr)
      end
    end
  end

  return true, nil
end

--- Setup highlighting for a specific buffer
---@param bufnr integer Buffer number to setup
---@return boolean success True if setup succeeded
---@return string|nil error Error message if setup failed
function M.setup_buffer(bufnr)
  if not state.enabled then
    return false, 'Plugin is disabled'
  end

  local cfg = require('color_my_ascii.config').get()

  -- Validate buffer
  if not safe_api.is_valid_buffer(bufnr) then
    return false, string.format('Invalid buffer: %d', bufnr)
  end

  -- Mark buffer as managed
  state.buffers[bufnr] = true

  -- Initial highlight
  local success, err = pcall(M.highlight_buffer, bufnr)
  if not success and cfg.debug_enabled then
    notify.warn(string.format('Initial highlighting failed: %s', err))
  end

  -- Setup autocommands for this buffer. Both are buffer-scoped; these used to
  -- call the raw API with a comment saying lib.nvim.bindings.autocmd.create did not
  -- support `opts.buffer`. It does, so they go through the wrapper like
  -- everything else -- which also gets them the wrapper's error reporting.
  local group = autocmd.augroup.create.clear('ColorMyAsciiBuffer_' .. bufnr)

  -- Re-highlight on text change with adaptive debouncing
  autocmd.create({ 'TextChanged', 'TextChangedI' }, function()
    debounce_manager.debounce(bufnr, function()
      M.highlight_buffer(bufnr)
    end)
  end, {
    group = group,
    buffer = bufnr,
    desc = 'Re-highlight ASCII art on text change with debouncing',
  })

  -- Cleanup on buffer delete
  autocmd.create('BufDelete', function()
    state.buffers[bufnr] = nil
    highlighter.clear_buffer(bufnr)
    fence_hl.clear(bufnr)
    cache_manager.invalidate(bufnr)
    debounce_manager.cancel(bufnr)
  end, {
    group = group,
    buffer = bufnr,
    desc = 'Cleanup ASCII art highlighting on buffer delete',
  })

  return true, nil
end

--- Highlight all ASCII blocks in the specified buffer with caching
---@param bufnr? integer Buffer number (defaults to current buffer)
---@return boolean success True if highlighting succeeded
---@return string|nil error Error message if highlighting failed
function M.highlight_buffer(bufnr)
  local cfg = require('color_my_ascii.config').get()
  bufnr = bufnr or api.nvim_get_current_buf()

  if not state.enabled or not state.buffers[bufnr] then
    return false, 'Buffer not managed or plugin disabled'
  end

  -- Validate buffer
  if not safe_api.is_valid_buffer(bufnr) then
    return false, string.format('Invalid buffer: %d', bufnr)
  end

  -- Try cache first
  local cached_blocks, _, cache_hit = cache_manager.get(bufnr)

  if cache_hit then
    -- Use cached data
    local success, err = pcall(highlighter.clear_buffer, bufnr)
    if not success then
      return false, string.format(('Failed to clear buffer (cache hit): %s'):format(), err)
    end

    -- Check if cached_blocks is valid
    if type(cached_blocks) ~= 'table' or vim.tbl_isempty(cached_blocks) and cfg.debug_enabled then
      notify.warn(string.format('Cache for buffer %d is empty or invalid, skipping block highlighting', bufnr))
    else
      -- Highlight cached blocks safely
      for _, block in ipairs(cached_blocks) do
        if type(block) == 'table' then
          success, err = pcall(highlighter.highlight_block, bufnr, block)
          if not success then
            notify.error(string.format('Failed to highlight block: %s', err))
          end
        else
          notify.warn('Skipped invalid block in cache (not a table)')
        end
      end
    end

    -- Highlight inline codes
    success, err = pcall(highlighter.highlight_inline_codes, bufnr)
    if not success then
      return false, string.format('Failed to highlight inline codes: %s', err)
    end

    pcall(fence_hl.apply, bufnr, cfg)
    return true, nil
  end

  -- Cache miss - parse and highlight
  local success, err = pcall(highlighter.clear_buffer, bufnr)
  if not success then
    return false, string.format('Failed to clear buffer (cache miss): %s', err)
  end

  -- Parse blocks
  local parse_ok, blocks = pcall(parser.find_ascii_blocks, bufnr)
  if not parse_ok then
    return false, string.format('Failed to parse blocks: %s', blocks)
  end

  -- Parse inline codes
  local inline_ok, inline_codes = pcall(parser.find_inline_codes, bufnr)
  if not inline_ok then
    return false, string.format('Failed to parse inline codes: %s', inline_codes)
  end

  -- Cache parsed data
  cache_manager.set(bufnr, blocks, inline_codes)

  -- Highlight each block
  for _, block in ipairs(blocks) do
    success, err = pcall(highlighter.highlight_block, bufnr, block)
    if not success and cfg.debug_enabled then
      -- Log error but continue with other blocks
      notify.warn(string.format('Block highlighting error: %s', err))
    end
  end

  -- Highlight inline codes
  success, err = pcall(highlighter.highlight_inline_codes, bufnr)
  if not success and cfg.debug_enabled then
    notify.warn(string.format(('Inline code highlighting error: %s'):format(), err))
  end

  pcall(fence_hl.apply, bufnr, cfg)
  return true, nil
end

--- Toggle highlighting for one buffer, leaving the global switch alone.
---
--- `M.toggle()` has always been global — a single `state.enabled` flag applied
--- across every managed buffer — so "turn it off just here" had no expression
--- at all. This is that: it flips whether the buffer is *managed*, reusing the
--- existing `state.buffers` model rather than adding a second one.
---
--- Note it does not survive a re-attach: the FileType/BufReadPost autocmds
--- call `setup_buffer` again, which re-marks the buffer as managed. Toggling
--- off is for the buffer as it is open now, not a persistent per-file opt-out
--- (`filetypes`/`disable` config is that).
---@param bufnr? integer Buffer number (defaults to current buffer)
---@return boolean managed New state (true = highlighted, false = cleared)
function M.toggle_buffer(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()

  if not safe_api.is_valid_buffer(bufnr) then
    notify.warn(string.format('Invalid buffer: %d', bufnr))
    return false
  end

  if state.buffers[bufnr] then
    state.buffers[bufnr] = nil
    highlighter.clear_buffer(bufnr)
    fence_hl.clear(bufnr)
    notify.info('disabled for this buffer')
    return false
  end

  -- Honour the global switch: enabling one buffer while the plugin is off
  -- would mark it managed and then highlight nothing, which reads as a bug.
  if not state.enabled then
    notify.warn('plugin is disabled globally — :ColorMyAscii toggle first')
    return false
  end

  state.buffers[bufnr] = true
  M.highlight_buffer(bufnr)
  notify.info('enabled for this buffer')
  return true
end

--- Toggle the plugin on/off
---@return boolean enabled New state (true = enabled, false = disabled)
function M.toggle()
  state.enabled = not state.enabled

  if state.enabled then
    -- Re-enable: highlight all managed buffers
    for bufnr, _ in pairs(state.buffers) do
      if safe_api.is_valid_buffer(bufnr) then
        M.highlight_buffer(bufnr)
      end
    end
    notify.info('enabled')
  else
    -- Disable: clear all highlights
    for bufnr, _ in pairs(state.buffers) do
      if safe_api.is_valid_buffer(bufnr) then
        highlighter.clear_buffer(bufnr)
        fence_hl.clear(bufnr)
      end
    end
    notify.info('disabled')
  end

  return state.enabled
end

--- Get current plugin state
---@return ColorMyAscii.State
function M.get_state()
  return vim.deepcopy(state)
end

--- Get cache statistics
---@return CacheStats stats Cache statistics
function M.get_cache_stats()
  return cache_manager.get_stats()
end

--- Get cache hit rate
---@return number hit_rate Hit rate as percentage (0-100)
function M.get_cache_hit_rate()
  return cache_manager.get_hit_rate()
end

--- Clear all caches
---@return integer count Number of cleared entries
function M.clear_caches()
  return cache_manager.clear_all()
end

--- Get debounce configuration
---@return DebounceConfig config Debounce configuration
function M.get_debounce_config()
  return debounce_manager.get_config()
end

--- Configure cache behavior
---@param opts CacheConfig Cache configuration
---@return nil
function M.configure_cache(opts)
  cache_manager.configure(opts)
end

--- Configure debounce behavior
---@param opts DebounceConfig Debounce configuration
---@return nil
function M.configure_debounce(opts)
  debounce_manager.configure(opts)
end

return M
