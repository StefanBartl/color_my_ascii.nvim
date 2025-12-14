---@module 'color_my_ascii.health'
--- Health check module for color_my_ascii.nvim
--- Provides diagnostic information via :checkhealth

local M = {}

--- Check if a module can be loaded
---@param module_name string Name of the module to check
---@return boolean success True if module can be loaded
---@return string? error_msg Error message if loading failed
local function check_module(module_name)
  local ok, result = pcall(require, module_name)
  if not ok then
    return false, tostring(result)
  end
  return true, nil
end

--- Count files in a directory
---@param path string Path to directory
---@param pattern string File pattern (e.g., '*.lua')
---@return integer count Number of files found
local function count_files(path, pattern)
  local files = vim.fn.globpath(path, pattern, false, true)
  return #files
end

--- Main health check function
function M.check()
  local health = vim.health or require('health')

  health.start('color_my_ascii.nvim')

  -- Check core modules
  health.info('Checking core modules...')

  local core_modules = {
    'color_my_ascii',
    'color_my_ascii.config',
    'color_my_ascii.parser',
    'color_my_ascii.highlighter',
    'color_my_ascii.language_detector',
  }

  local all_core_ok = true
  for _, module in ipairs(core_modules) do
    local ok, err = check_module(module)
    if ok then
      health.ok(string.format('Module "%s" loaded successfully', module))
    else
      health.error(string.format('Module "%s" failed to load: %s', module, err))
      all_core_ok = false
    end
  end

  -- Check configuration
  health.info('Checking configuration...')

  local ok, config = pcall(require, 'color_my_ascii.config')
  if ok then
    local cfg = config.get()

    -- Check languages
    local lang_count = 0
    for _ in pairs(cfg.keywords) do
      lang_count = lang_count + 1
    end

    if lang_count > 0 then
      health.ok(string.format('%d language(s) loaded', lang_count))
    else
      health.warn('No languages loaded - keywords will not be highlighted')
    end

    -- Check groups
    local group_count = 0
    for _ in pairs(cfg.groups) do
      group_count = group_count + 1
    end

    if group_count > 0 then
      health.ok(string.format('%d character group(s) loaded', group_count))
    else
      health.warn('No character groups loaded - special characters will not be highlighted')
    end

    -- Check lookup tables
    local char_count = vim.tbl_count(config.char_lookup)
    local keyword_count = vim.tbl_count(config.keyword_lookup)

    if char_count > 0 then
      health.ok(string.format('%d character(s) in lookup table', char_count))
    else
      health.warn('Character lookup table is empty')
    end

    if keyword_count > 0 then
      health.ok(string.format('%d keyword(s) in lookup table', keyword_count))
    else
      health.info('Keyword lookup table is empty (keywords disabled or no languages loaded)')
    end

    -- Check feature flags
    health.info('Feature status:')
    health.info(string.format('  Keywords: %s', cfg.enable_keywords and 'enabled' or 'disabled'))
    health.info(string.format('  Language detection: %s', cfg.enable_language_detection and 'enabled' or 'disabled'))
    health.info(string.format('  Function names: %s', cfg.enable_function_names and 'enabled' or 'disabled'))
    health.info(string.format('  Bracket highlighting: %s', cfg.enable_bracket_highlighting and 'enabled' or 'disabled'))
    health.info(string.format('  Inline code: %s', cfg.enable_inline_code and 'enabled' or 'disabled'))
    health.info(string.format('  Empty fence as ASCII: %s', cfg.treat_empty_fence_as_ascii and 'enabled' or 'disabled'))
    health.info(string.format('  Default text highlight: %s', cfg.default_text_hl or 'none'))

  else
    health.error('Failed to load configuration module')
  end

  -- Check file structure
  health.info('Checking file structure...')

  local source = debug.getinfo(1, "S").source:sub(2)
  local dir = vim.fn.fnamemodify(source, ":h")

  -- Check languages directory
  local lang_path = dir .. '/languages'
  if vim.fn.isdirectory(lang_path) == 1 then
    local lang_file_count = count_files(lang_path, '*.lua')
    health.ok(string.format('Languages directory found with %d file(s)', lang_file_count))
  else
    health.error(string.format('Languages directory not found at: %s', lang_path))
  end

  -- Check groups directory
  local group_path = dir .. '/groups'
  if vim.fn.isdirectory(group_path) == 1 then
    local group_file_count = count_files(group_path, '*.lua')
    health.ok(string.format('Groups directory found with %d file(s)', group_file_count))
  else
    health.error(string.format('Groups directory not found at: %s', group_path))
  end

  -- Check for color schemes
  local schemes_path = dir .. '/schemes'
  if vim.fn.isdirectory(schemes_path) == 1 then
    local scheme_file_count = count_files(schemes_path, '*.lua')
    health.ok(string.format('Color schemes directory found with %d scheme(s)', scheme_file_count))
  else
    health.info('Color schemes directory not found (optional)')
  end

  -- Check plugin initialization
  health.info('Checking plugin initialization...')

  if vim.g.loaded_color_my_ascii == 1 then
    health.ok('Plugin initialized successfully')
  else
    health.warn('Plugin not initialized - may not be loaded yet')
  end

  -- Check current buffer
  local bufnr = vim.api.nvim_get_current_buf()
  local filetype = vim.bo[bufnr].filetype

  health.info('Current buffer information:')
  health.info(string.format('  Filetype: %s', filetype))

  if filetype == 'markdown' then
    health.ok('Current buffer is markdown - plugin should be active')
  else
    health.info('Current buffer is not markdown - plugin will not activate')
  end

  -- Check for common issues
  health.info('Checking for common issues...')

  -- Check if treesitter is enabled but not available
  if ok and config.get().enable_treesitter then
    local ts_ok = pcall(require, 'nvim-treesitter')
    if not ts_ok then
      health.warn('Treesitter integration enabled but nvim-treesitter not found')
    end
  end

  -- Summary
  if all_core_ok then
    health.ok('All core modules loaded successfully')
  else
    health.error('Some core modules failed to load - plugin may not function correctly')
  end
end

return M
