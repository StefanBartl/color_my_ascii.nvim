---@module 'color_my_ascii.commands.debug'
--- Debug information command

local M = {}

local tbl_insert = table.insert
local str_format = string.format
local notify = require('lib.nvim.notify').create('[color_my_ascii]')

--- Show debug information
function M.show_debug_info()
  local config = require('color_my_ascii.config')
  local cfg = config.get()

  local lines = {}
  tbl_insert(lines, '=== color_my_ascii.nvim Debug Info ===')
  tbl_insert(lines, '')

  -- Languages
  local langs = {}
  for lang_name, _ in pairs(cfg.keywords) do
    table.insert(langs, lang_name)
  end
  table.sort(langs)

  tbl_insert(lines, str_format('Languages loaded: %d', #langs))
  tbl_insert(lines, '  ' .. table.concat(langs, ', '))
  tbl_insert(lines, '')

  -- Groups
  local groups = {}
  for group_name, _ in pairs(cfg.groups) do
    table.insert(groups, group_name)
  end
  table.sort(groups)

  tbl_insert(lines, str_format('Groups loaded: %d', #groups))
  tbl_insert(lines, '  ' .. table.concat(groups, ', '))
  tbl_insert(lines, '')

  -- Lookup statistics
  local char_count = vim.tbl_count(config.char_lookup)
  local keyword_count = vim.tbl_count(config.keyword_lookup)

  tbl_insert(lines, str_format('Character lookup entries: %d', char_count))
  tbl_insert(lines, str_format('Keyword lookup entries: %d', keyword_count))
  tbl_insert(lines, '')

  -- Feature status
  tbl_insert(lines, 'Features:')
  tbl_insert(lines, str_format('  Language detection: %s', tostring(cfg.enable_language_detection)))
  tbl_insert(lines, str_format('  Keywords enabled: %s', tostring(cfg.enable_keywords)))
  tbl_insert(lines, str_format('  Function names enabled: %s', tostring(cfg.enable_function_names)))
  tbl_insert(lines, str_format('  Bracket highlighting enabled: %s', tostring(cfg.enable_bracket_highlighting)))
  tbl_insert(lines, str_format('  Inline code enabled: %s', tostring(cfg.enable_inline_code)))
  tbl_insert(lines, str_format('  Empty fence as ASCII: %s', tostring(cfg.treat_empty_fence_as_ascii)))
  tbl_insert(lines, str_format('  Debug enabled: %s', tostring(cfg.debug_enabled)))

  notify.info(table.concat(lines, '\n'))
end

return M
