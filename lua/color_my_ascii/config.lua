---@module 'color_my_ascii.config'
--- Configuration management for color_my_ascii.nvim plugin.
--- Handles user configuration, defaults, and provides access to settings.
--- Supports modular language and group definitions.

local M = {}

--- Load all language definitions from the languages/ directory
---@return table<string, ColorMyAscii.KeywordGroup> languages Map of language name to keyword group
local function load_languages()
  local languages = {}

  -- Get the directory of this config file
  local source = debug.getinfo(1, "S").source:sub(2)
  local dir = vim.fn.fnamemodify(source, ":h")
  local lang_path = dir .. '/languages'

  -- Check if directory exists
  if vim.fn.isdirectory(lang_path) == 0 then
    vim.notify(
      'color_my_ascii: CRITICAL - languages/ directory not found at: ' .. lang_path,
      vim.log.levels.ERROR
    )
    return languages
  end

  -- Iterate through all .lua files in languages directory
  local files = vim.fn.globpath(lang_path, '*.lua', false, true)

  if #files == 0 then
    vim.notify(
      'color_my_ascii: WARNING - No language files found in: ' .. lang_path,
      vim.log.levels.WARN
    )
    return languages
  end

  for _, file in ipairs(files) do
    local lang_name = vim.fn.fnamemodify(file, ':t:r')
    local ok, lang_module = pcall(require, 'color_my_ascii.languages.' .. lang_name)

    if ok and type(lang_module) == 'table' then
      languages[lang_name] = lang_module
    else
      vim.notify(
        string.format('color_my_ascii: Failed to load language "%s": %s',
          lang_name,
          tostring(lang_module)
        ),
        vim.log.levels.WARN
      )
    end
  end

  return languages
end

--- Load all character group definitions from the groups/ directory
---@return table<string, ColorMyAscii.CharGroup> groups Map of group name to character group
local function load_groups()
  local groups = {}

  -- Get the directory of this config file
  local source = debug.getinfo(1, "S").source:sub(2)
  local dir = vim.fn.fnamemodify(source, ":h")
  local group_path = dir .. '/groups'

  -- Check if directory exists
  if vim.fn.isdirectory(group_path) == 0 then
    vim.notify(
      'color_my_ascii: CRITICAL - groups/ directory not found at: ' .. group_path,
      vim.log.levels.ERROR
    )
    return groups
  end

  -- Iterate through all .lua files in groups directory
  local files = vim.fn.globpath(group_path, '*.lua', false, true)

  if #files == 0 then
    vim.notify(
      'color_my_ascii: WARNING - No group files found in: ' .. group_path,
      vim.log.levels.WARN
    )
    return groups
  end

  for _, file in ipairs(files) do
    local group_name = vim.fn.fnamemodify(file, ':t:r')
    local ok, group_module = pcall(require, 'color_my_ascii.groups.' .. group_name)

    if ok and type(group_module) == 'table' then
      groups[group_name] = group_module
    else
      vim.notify(
        string.format('color_my_ascii: Failed to load group "%s": %s',
          group_name,
          tostring(group_module)
        ),
        vim.log.levels.WARN
      )
    end
  end

  return groups
end

--- Default configuration
---@type ColorMyAscii.Config
local defaults = {
  groups = {},
  keywords = {},
  overrides = {},
  default_hl = 'Normal',
  default_text_hl = nil,
  enable_keywords = true,
  enable_language_detection = true,
  language_detection_threshold = 2,
  enable_treesitter = false,
  treat_empty_fence_as_ascii = false,
  enable_inline_code = false,
}

--- Current configuration (starts with defaults)
---@type ColorMyAscii.Config
local current_config = vim.deepcopy(defaults)

--- Build a lookup table for fast character-to-highlight-group resolution
---@return table<string, string> Map of character to highlight group name
local function build_char_lookup()
  local lookup = {}

  -- Step 1: Add all group characters
  for _, group in pairs(current_config.groups) do
    -- Use vim.str_utf_pos for proper UTF-8 iteration
    local char_list = vim.fn.split(group.chars, '\\zs')
    for _, char in ipairs(char_list) do
      lookup[char] = group.hl
    end
  end

  -- Step 2: Apply overrides (highest priority)
  for char, hl in pairs(current_config.overrides) do
    lookup[char] = hl
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
    for _, word in ipairs(lang_config.words) do
      lookup[word] = lookup[word] or {}
      table.insert(lookup[word], {
        language = lang_name,
        hl = lang_config.hl,
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
---@param opts? ColorMyAscii.Config User configuration to merge with defaults
function M.setup(opts)
  -- Load modular definitions
  local loaded_groups = load_groups()
  local loaded_languages = load_languages()

  -- Merge with defaults
  defaults.groups = loaded_groups
  defaults.keywords = loaded_languages

  if opts then
    current_config = vim.tbl_deep_extend('force', defaults, opts)
  else
    current_config = vim.deepcopy(defaults)
  end

  -- Rebuild lookup tables after configuration change
  M.char_lookup = build_char_lookup()
  M.keyword_lookup = build_keyword_lookup()
  M.unique_keyword_lookup = build_unique_keyword_lookup()
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

-- Initialize lookup tables (will be empty until setup() is called)
M.char_lookup = {}
M.keyword_lookup = {}
M.unique_keyword_lookup = {}

return M
