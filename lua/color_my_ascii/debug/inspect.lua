---@module 'color_my_ascii.debug.inspect'
---@brief Inspection utilities for debugging

local M = {}

---Inspect a single character and return all groups it belongs to
---@param char string Single character to inspect
---@return CharInspectResult
function M.inspect_char(char)
  local config = require('color_my_ascii.config')
  local cfg = config.get()

  ---@type CharInspectResult
  local result = {
    char = char,
    groups = {},
    highlight = nil,
    override = false,
  }

  -- Check overrides first
  if cfg.overrides[char] then
    result.highlight = cfg.overrides[char]
    result.override = true
  end

  -- Check which groups contain this character
  for group_name, group_data in pairs(cfg.groups) do
    if group_data.chars:find(vim.pesc(char), 1, true) then
      table.insert(result.groups, group_name)
      if not result.highlight then
        result.highlight = group_data.hl
      end
    end
  end

  -- Check char_lookup
  if not result.highlight then
    result.highlight = config.char_lookup[char]
  end

  return result
end

---Inspect all characters in a group
---@param group_name string Name of the group to inspect
---@return GroupInspectResult|nil
function M.inspect_group(group_name)
  local cfg = require('color_my_ascii.config').get()
  local group = cfg.groups[group_name]

  if not group then
    return nil
  end

  ---@type string[]
  local chars = {}

  -- Extract individual characters from the chars string
  local i = 1
  while i <= #group.chars do
    local byte = group.chars:byte(i)
    local char_len

    if byte < 128 then
      char_len = 1
    elseif byte < 224 then
      char_len = 2
    elseif byte < 240 then
      char_len = 3
    elseif byte < 248 then
      char_len = 4
    else
      char_len = 1
    end

    local char = group.chars:sub(i, i + char_len - 1)
    table.insert(chars, char)
    i = i + char_len
  end

  ---@type GroupInspectResult
  return {
    name = group_name,
    chars = chars,
    highlight = group.hl,
    count = #chars,
  }
end

---Get all groups that use a specific highlight
---@param highlight string Highlight group name
---@return string[] group_names
function M.groups_by_highlight(highlight)
  local cfg = require('color_my_ascii.config').get()
  ---@type string[]
  local groups = {}

  for group_name, group_data in pairs(cfg.groups) do
    if group_data.hl == highlight then
      table.insert(groups, group_name)
    end
  end

  table.sort(groups)
  return groups
end

---Inspect inline code parsing for a given line
---@param line string Line to parse
---@return table[]
function M.inspect_inline_code(line)
  local parser = require('color_my_ascii.parser')
  local config = require('color_my_ascii.config')

  ---@type table[]
  local results = {}
  local i = 1

  while i <= #line do
    local start_pos = line:find('`', i, true)
    if not start_pos then
      break
    end

    local end_pos = line:find('`', start_pos + 1, true)
    if not end_pos then
      break
    end

    local content = line:sub(start_pos + 1, end_pos - 1)

    ---@type table
    local code_result = {
      content = content,
      start_col = start_pos - 1,
      end_col = end_pos,
      chars = {},
      keywords = {},
    }

    -- Check each character
    local j = 1
    while j <= #content do
      local byte = content:byte(j)
      local char_len

      if byte < 128 then
        char_len = 1
      elseif byte < 224 then
        char_len = 2
      elseif byte < 240 then
        char_len = 3
      elseif byte < 248 then
        char_len = 4
      else
        char_len = 1
      end

      local char = content:sub(j, j + char_len - 1)
      local hl = config.get_char_highlight(char)

      if hl then
        table.insert(code_result.chars, {
          char = char,
          highlight = hl,
        })
      end

      j = j + char_len
    end

    -- Check keywords
    local tokens = parser.tokenize_line(content)
    for _, token in ipairs(tokens) do
      local kw_langs = config.get_keyword_languages(token)
      if kw_langs then
        table.insert(code_result.keywords, {
          token = token,
          languages = vim.tbl_map(function(lang_info)
            return {
              language = lang_info.language,
              highlight = lang_info.hl,
            }
          end, kw_langs),
        })
      end
    end

    table.insert(results, code_result)
    i = end_pos + 1
  end

  return results
end

---Get comprehensive statistics about current configuration
---@return table
function M.get_statistics()
  local cfg = require('color_my_ascii.config').get()
  local config = require('color_my_ascii.config')

  ---@type table
  local stats = {
    groups = {
      count = 0,
      by_highlight = {},
    },
    languages = {
      count = 0,
      by_keywords = {},
    },
    lookups = {
      char_count = vim.tbl_count(config.char_lookup),
      keyword_count = vim.tbl_count(config.keyword_lookup),
      unique_keyword_count = vim.tbl_count(config.unique_keyword_lookup),
    },
    overrides = vim.tbl_count(cfg.overrides),
  }

  -- Group statistics
  for group_name, group_data in pairs(cfg.groups) do
    stats.groups.count = stats.groups.count + 1
    local hl = group_data.hl
    stats.groups.by_highlight[hl] = stats.groups.by_highlight[hl] or {}
    table.insert(stats.groups.by_highlight[hl], group_name)
  end

  -- Language statistics
  for lang_name, lang_data in pairs(cfg.keywords) do
    stats.languages.count = stats.languages.count + 1
    stats.languages.by_keywords[lang_name] = #lang_data.words
  end

  return stats
end

return M
