---@module 'color_my_ascii.config'
--- Configuration management for color_my_ascii.nvim plugin.
--- Handles user configuration, defaults, and provides access to settings.
--- Supports modular language and group definitions, custom highlights, dynamic highlight groups,
--- and simplified scheme loading via string identifiers.

local M = {}

local notify = vim.notify
local fn = vim.fn

--- Cache for dynamically created highlight groups
---@type table<string, boolean>
local created_highlight_groups = {}

--- Load all language definitions from the languages/ directory
--- Implements safe loading with error recovery and validation
---@return table<string, ColorMyAscii.KeywordGroup> languages Map of language name to keyword group
---@return string[] errors List of loading errors (non-fatal)
local function load_languages()
  local languages = {}
  local errors = {}

  -- Safe path resolution
  local ok1, source = pcall(function()
    return debug.getinfo(1, "S").source:sub(2)
  end)

  if not ok1 then
    table.insert(errors, 'Failed to determine plugin path')
    return languages, errors
  end

  local dir = fn.fnamemodify(source, ":h")
  local lang_path = dir .. '/languages'

  -- Check directory existence
  if fn.isdirectory(lang_path) == 0 then
    table.insert(errors, string.format('Languages directory not found: %s', lang_path))
    notify(
      'color_my_ascii: CRITICAL - languages/ directory not found at: ' .. lang_path,
      vim.log.levels.ERROR
    )
    return languages, errors
  end

  -- Safe file globbing
  local glob_ok, files = pcall(fn.globpath, lang_path, '*.lua', false, true)
  if not glob_ok then
    table.insert(errors, 'Failed to list language files')
    return languages, errors
  end

  if #files == 0 then
    table.insert(errors, 'No language files found')
    notify(
      'color_my_ascii: WARNING - No language files found in: ' .. lang_path,
      vim.log.levels.WARN
    )
    return languages, errors
  end

  -- Load each language file with error recovery
  for _, file in ipairs(files) do
    local lang_name = fn.fnamemodify(file, ':t:r')
    local ok2, lang_module = pcall(require, 'color_my_ascii.languages.' .. lang_name)

    if ok2 and type(lang_module) == 'table' then
      -- Validate language module structure
      if type(lang_module.words) == 'table' and type(lang_module.hl) ~= 'nil' then
        languages[lang_name] = lang_module
      else
        local err = string.format('Language "%s" has invalid structure', lang_name)
        table.insert(errors, err)
        notify('color_my_ascii: ' .. err, vim.log.levels.WARN)
      end
    else
      local err = string.format('Failed to load language "%s": %s', lang_name, tostring(lang_module))
      table.insert(errors, err)
      notify('color_my_ascii: ' .. err, vim.log.levels.WARN)
    end
  end

  return languages, errors
end

--- Load all character group definitions from the groups/ directory
--- Implements safe loading with error recovery and validation
---@return table<string, ColorMyAscii.CharGroup> groups Map of group name to character group
---@return string[] errors List of loading errors (non-fatal)
local function load_groups()
  local groups = {}
  local errors = {}

  -- Safe path resolution
  local ok3, source = pcall(function()
    return debug.getinfo(1, "S").source:sub(2)
  end)

  if not ok3 then
    table.insert(errors, 'Failed to determine plugin path')
    return groups, errors
  end

  local dir = fn.fnamemodify(source, ":h")
  local group_path = dir .. '/groups'

  -- Check directory existence
  if fn.isdirectory(group_path) == 0 then
    table.insert(errors, string.format('Groups directory not found: %s', group_path))
    notify(
      'color_my_ascii: CRITICAL - groups/ directory not found at: ' .. group_path,
      vim.log.levels.ERROR
    )
    return groups, errors
  end

  -- Safe file globbing
  local glob_ok, files = pcall(fn.globpath, group_path, '*.lua', false, true)
  if not glob_ok then
    table.insert(errors, 'Failed to list group files')
    return groups, errors
  end

  if #files == 0 then
    table.insert(errors, 'No group files found')
    notify(
      'color_my_ascii: WARNING - No group files found in: ' .. group_path,
      vim.log.levels.WARN
    )
    return groups, errors
  end

  -- Load each group file with error recovery
  for _, file in ipairs(files) do
    local group_name = fn.fnamemodify(file, ':t:r')
    local ok4, group_module = pcall(require, 'color_my_ascii.groups.' .. group_name)

    if ok4 and type(group_module) == 'table' then
      -- Validate group module structure
      if type(group_module.chars) == 'string' and type(group_module.hl) ~= 'nil' then
        groups[group_name] = group_module
      else
        local err = string.format('Group "%s" has invalid structure', group_name)
        table.insert(errors, err)
        notify('color_my_ascii: ' .. err, vim.log.levels.WARN)
      end
    else
      local err = string.format('Failed to load group "%s": %s', group_name, tostring(group_module))
      table.insert(errors, err)
      notify('color_my_ascii: ' .. err, vim.log.levels.WARN)
    end
  end

  return groups, errors
end

--- Default configuration
---@type ColorMyAscii.Config
local defaults = {
  debug_enabled = false,
  scheme = 'default',
  groups = {},
  keywords = {},
  overrides = {},
  default_hl = 'Normal',
  default_text_hl = nil,
  enable_keywords = true,
  enable_language_detection = true,
  language_detection_threshold = 2,
  enable_treesitter = false,
  treat_empty_fence_as_ascii = true,
  enable_inline_code = true,
  enable_function_names = true,
  enable_bracket_highlighting = true,
}

--- Current configuration
---@type ColorMyAscii.Config
local current_config = vim.deepcopy(defaults)

--- Create or get a custom highlight group
---@param spec string|ColorMyAscii.CustomHighlight Highlight specification
---@return string highlight_group_name Name of the highlight group to use
local function resolve_highlight(spec)
  if type(spec) == 'string' then
    return spec
  end

  local hl_def = spec
  local name = string.format(
    'ColorMyAsciiCustom_%s_%s_%s_%s_%s_%s_%s',
    hl_def.fg or 'none',
    hl_def.bg or 'none',
    hl_def.bold and 'b' or '',
    hl_def.italic and 'i' or '',
    hl_def.underline and 'u' or '',
    hl_def.undercurl and 'c' or '',
    hl_def.strikethrough and 's' or ''
  ):gsub('#', '')  -- Remove # from hex colors for group name

  if not created_highlight_groups[name] then
    vim.api.nvim_set_hl(0, name, {
      fg = hl_def.fg,
      bg = hl_def.bg,
      bold = hl_def.bold,
      italic = hl_def.italic,
      underline = hl_def.underline,
      undercurl = hl_def.undercurl,
      strikethrough = hl_def.strikethrough,
    })
    created_highlight_groups[name] = true
  end

  return name
end

--- Build a lookup table for fast character-to-highlight-group resolution
---@return table<string, string> Map of character to highlight group name
local function build_char_lookup()
  local lookup = {}

  -- Step 1: Add all group characters
  for _, group in pairs(current_config.groups) do
    local hl_group = resolve_highlight(group.hl)
    local chars = fn.split(group.chars, '\\zs')
    for _, char in ipairs(chars) do
      lookup[char] = hl_group
    end
  end

  -- Step 2: Add brackets if bracket highlighting is enabled AND not already in groups
  if current_config.enable_bracket_highlighting then
    local bracket_hl = resolve_highlight('Operator')
    local brackets = { '(', ')', '[', ']', '{', '}' }
    for _, bracket in ipairs(brackets) do
      -- Only add if not already defined (groups have priority)
      if not lookup[bracket] then
        lookup[bracket] = bracket_hl
      end
    end
  end

  -- Step 3: Apply overrides (highest priority)
  for char, hl in pairs(current_config.overrides) do
    lookup[char] = resolve_highlight(hl)
  end

  return lookup
end

--- Build a lookup table for keywords across all languages
---@return table<string, table<integer, {language: string, hl: string}>> Map of keyword to list of {language, hl_group}
local function build_keyword_lookup()
  if not current_config.enable_keywords then
    return {}
  end

  local lookup = {}

  for lang_name, lang_config in pairs(current_config.keywords) do
    local hl_group = resolve_highlight(lang_config.hl)
    for _, word in ipairs(lang_config.words) do
      lookup[word] = lookup[word] or {}
      table.insert(lookup[word], {
        language = lang_name,
        hl = hl_group,
      })
    end
  end

  return lookup
end

--- Build a lookup table for unique keywords per language (for heuristic detection)
---@return table<string, string> Map of unique keyword to language name
local function build_unique_keyword_lookup()
  if not current_config.enable_language_detection then
    return {}
  end

  local lookup = {}

  for lang_name, lang_config in pairs(current_config.keywords) do
    if lang_config.unique_words then
      for _, word in ipairs(lang_config.unique_words) do
        lookup[word] = lang_name
      end
    end
  end

  return lookup
end

--- Setup the configuration with user options
---@param opts? ColorMyAscii.Config|{scheme: string} User configuration to merge with defaults
function M.setup(opts)
  -- Load modular definitions
  local loaded_groups = load_groups()
  local loaded_languages = load_languages()

  defaults.groups = loaded_groups
  defaults.keywords = loaded_languages

  -- Handle scheme parameter
  local config_to_merge = opts
  if opts and opts.scheme then
    local scheme_loader = require('color_my_ascii.scheme_loader')
    local scheme_config, err = scheme_loader.load_scheme(opts.scheme)

    if not scheme_config then
      notify(
        string.format('color_my_ascii: %s', err),
        vim.log.levels.ERROR
      )
      config_to_merge = vim.tbl_extend('force', {}, opts)
      config_to_merge.scheme = nil  -- Remove invalid scheme parameter
    else
      -- Merge user opts with scheme config (user opts take precedence)
      local user_opts = vim.tbl_extend('force', {}, opts)
      user_opts.scheme = nil  -- Remove scheme key from merge
      config_to_merge = vim.tbl_deep_extend('force', scheme_config, user_opts)
    end
  end

  if config_to_merge then
    current_config = vim.tbl_deep_extend('force', defaults, config_to_merge)
  else
    current_config = vim.deepcopy(defaults)
  end

  -- Resolve default_text_hl if it's a custom highlight
  if current_config.default_text_hl then
    current_config.default_text_hl = resolve_highlight(current_config.default_text_hl)
  end

  -- Rebuild lookup tables after configuration change
  M.char_lookup = build_char_lookup()
  M.keyword_lookup = build_keyword_lookup()
  M.unique_keyword_lookup = build_unique_keyword_lookup()

  -- Initialize debug module if enabled
  if current_config.debug_enabled then
    local debug = require('color_my_ascii.debug')
    debug.setup({
      enabled = true,
      verbose = current_config.debug_verbose or false,
    })
  end
end

--- Get the current configuration
---@return ColorMyAscii.Config
function M.get()
  return current_config
end

--- Get the highlight group for a specific character
---@param char string Single character to look up
---@return string? highlight_group Highlight group name, or nil if using default
function M.get_char_highlight(char)
  return M.char_lookup[char]
end

--- Get possible languages for a keyword
---@param word string Keyword to look up
---@return table<integer, {language: string, hl: string}>? languages List of possible languages with their hl groups
function M.get_keyword_languages(word)
  return M.keyword_lookup[word]
end

--- Get language from unique keyword
---@param word string Keyword to check
---@return string? language Language name if keyword is unique to that language
function M.get_unique_language(word)
  return M.unique_keyword_lookup[word]
end

--- Get all available languages
---@return string[] languages List of language names
function M.get_available_languages()
  local langs = {}
  for lang_name, _ in pairs(current_config.keywords) do
    table.insert(langs, lang_name)
  end
  table.sort(langs)
  return langs
end

--- Check if function name detection is enabled
---@return boolean enabled True if function name detection is enabled
function M.is_function_detection_enabled()
  return current_config.enable_function_names
end

-- Initialize lookup tables (will be empty until setup() is called)
M.char_lookup = {}
M.keyword_lookup = {}
M.unique_keyword_lookup = {}

return M
