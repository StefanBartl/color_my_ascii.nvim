---@module 'color_my_ascii.commands.debug'
--- Debug information command

local M = {}

local str_format = string.format

--- Show debug information
function M.show_debug_info()
  local config = require('color_my_ascii.config')
  local cfg = config.get()

  print('=== color_my_ascii.nvim Debug Info ===')
  print('')

  -- Languages
  local langs = {}
  for lang_name, _ in pairs(cfg.keywords) do
    table.insert(langs, lang_name)
  end
  table.sort(langs)

  print(str_format('Languages loaded: %d', #langs))
  print('  ' .. table.concat(langs, ', '))
  print('')

  -- Groups
  local groups = {}
  for group_name, _ in pairs(cfg.groups) do
    table.insert(groups, group_name)
  end
  table.sort(groups)

  print(str_format('Groups loaded: %d', #groups))
  print('  ' .. table.concat(groups, ', '))
  print('')

  -- Lookup statistics
  local char_count = vim.tbl_count(config.char_lookup)
  local keyword_count = vim.tbl_count(config.keyword_lookup)

  print(str_format('Character lookup entries: %d', char_count))
  print(str_format('Keyword lookup entries: %d', keyword_count))
  print('')

  -- Feature status
  print('Features:')
  print(str_format('  Language detection: %s', tostring(cfg.enable_language_detection)))
  print(str_format('  Keywords enabled: %s', tostring(cfg.enable_keywords)))
  print(str_format('  Function names enabled: %s', tostring(cfg.enable_function_names)))
  print(str_format('  Bracket highlighting enabled: %s', tostring(cfg.enable_bracket_highlighting)))
  print(str_format('  Inline code enabled: %s', tostring(cfg.enable_inline_code)))
  print(str_format('  Empty fence as ASCII: %s', tostring(cfg.treat_empty_fence_as_ascii)))
  print(str_format('  Debug enabled: %s', tostring(cfg.debug_enabled)))
end

return M
