---@module 'color_my_ascii.commands.config'
--- Configuration display command

local M = {}

local tbl_insert = table.insert
local str_format = string.format

--- Show detailed configuration information
function M.show_config()
  local config = require('color_my_ascii.config')
  local cfg = config.get()

  local lines = {}

  tbl_insert(lines, '=== color_my_ascii.nvim Configuration ===')
  tbl_insert(lines, '')

  -- Features
  tbl_insert(lines, '## Features')
  tbl_insert(lines, str_format('  Keywords enabled: %s', cfg.enable_keywords))
  tbl_insert(lines, str_format('  Language detection: %s', cfg.enable_language_detection))
  tbl_insert(lines, str_format('  Function names: %s', cfg.enable_function_names))
  tbl_insert(lines, str_format('  Bracket highlighting: %s', cfg.enable_bracket_highlighting))
  tbl_insert(lines, str_format('  Inline code: %s', cfg.enable_inline_code))
  tbl_insert(lines, str_format('  Empty fence as ASCII: %s', cfg.treat_empty_fence_as_ascii))
  tbl_insert(lines, str_format('  Debug enabled: %s', cfg.debug_enabled))
  tbl_insert(lines, '')

  -- Languages
  local lang_count = 0
  local langs = {}
  for lang_name, _ in pairs(cfg.keywords) do
    lang_count = lang_count + 1
    tbl_insert(langs, lang_name)
  end
  table.sort(langs)

  tbl_insert(lines, '## Languages')
  tbl_insert(lines, str_format('  Total: %d', lang_count))
  tbl_insert(lines, str_format('  Languages: %s', table.concat(langs, ', ')))
  tbl_insert(lines, '')

  -- Groups
  local group_count = 0
  local groups = {}
  for group_name, _ in pairs(cfg.groups) do
    group_count = group_count + 1
    tbl_insert(groups, group_name)
  end
  table.sort(groups)

  tbl_insert(lines, '## Character Groups')
  tbl_insert(lines, str_format('  Total: %d', group_count))
  tbl_insert(lines, str_format('  Groups: %s', table.concat(groups, ', ')))
  tbl_insert(lines, '')

  -- Lookup statistics
  local char_count = vim.tbl_count(config.char_lookup)
  local keyword_count = vim.tbl_count(config.keyword_lookup)
  local unique_count = vim.tbl_count(config.unique_keyword_lookup)

  tbl_insert(lines, '## Lookup Tables')
  tbl_insert(lines, str_format('  Character mappings: %d', char_count))
  tbl_insert(lines, str_format('  Keyword mappings: %d', keyword_count))
  tbl_insert(lines, str_format('  Unique keywords: %d', unique_count))
  tbl_insert(lines, '')

  -- Highlights
  tbl_insert(lines, '## Highlights')
  tbl_insert(lines, str_format('  Default highlight: %s', cfg.default_hl))
  tbl_insert(lines, str_format('  Default text highlight: %s', cfg.default_text_hl or 'none'))
  tbl_insert(lines, str_format('  Custom overrides: %d', vim.tbl_count(cfg.overrides)))
  tbl_insert(lines, '')

  -- Detection
  if cfg.enable_language_detection then
    tbl_insert(lines, '## Language Detection')
    tbl_insert(lines, str_format('  Threshold: %d unique keywords', cfg.language_detection_threshold))
  end

  -- Print
  print(table.concat(lines, '\n'))
end

return M
