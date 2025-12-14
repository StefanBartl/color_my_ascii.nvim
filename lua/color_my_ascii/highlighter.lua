---@module 'color_my_ascii.highlighter'
--- Highlighter module for applying colors to ASCII art characters.
--- Uses extmarks for non-intrusive highlighting that doesn't modify buffer content.

local M = {}

local config = require('color_my_ascii.config')
local parser = require('color_my_ascii.parser')
local language_detector = require('color_my_ascii.language_detector')

local api = vim.api

--- Namespace ID for extmarks
---@type integer
local namespace = api.nvim_create_namespace('ColorMyAscii')

--- Storage for extmark IDs per buffer for efficient cleanup
---@type table<integer, integer[]>
local buffer_extmarks = {}

--- Clear all highlights in a buffer
---@param bufnr integer Buffer number to clear
function M.clear_buffer(bufnr)
  api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
  buffer_extmarks[bufnr] = nil
end

--- Apply highlighting to a single character range
---@param bufnr integer Buffer number
---@param line integer Line number (0-indexed)
---@param col_start integer Start column (0-indexed, byte offset)
---@param col_end integer End column (0-indexed, byte offset, exclusive)
---@param hl_group string|ColorMyAscii.CustomHighlight Highlight group name
local function highlight_range(bufnr, line, col_start, col_end, hl_group)
  local extmark_id = api.nvim_buf_set_extmark(bufnr, namespace, line, col_start, {
    end_col = col_end,
    hl_group = hl_group,
    priority = 100,
  })

  buffer_extmarks[bufnr] = buffer_extmarks[bufnr] or {}
  table.insert(buffer_extmarks[bufnr], extmark_id)
end

--- Detect and highlight function names (heuristic: word followed by '(')
---@param bufnr integer Buffer number
---@param line_num integer Line number (0-indexed)
---@param line_content string Content of the line
local function highlight_function_names(bufnr, line_num, line_content)
  if not config.is_function_detection_enabled() then
    return
  end

  local pattern = '([%w_]+)%s*%('
  local start_pos = 1

  while true do
    local match_start, match_end, func_name = line_content:find(pattern, start_pos)

    if not match_start then
      break
    end

    local func_end = match_start + #func_name - 1
    local keyword_langs = config.get_keyword_languages(func_name)

    if not keyword_langs then
      highlight_range(bufnr, line_num, match_start - 1, func_end, 'Function')
    end

    start_pos = match_end + 1
  end
end

--- Highlight keywords in a line
---@param bufnr integer Buffer number
---@param line_num integer Line number (0-indexed)
---@param line_content string Content of the line
---@param detected_language? string Detected language for this block (nil = all languages)
local function highlight_keywords(bufnr, line_num, line_content, detected_language)
  local user_config = config.get()

  if not user_config.enable_keywords then
    return
  end

  local tokens = parser.tokenize_line(line_content)

  for _, token in ipairs(tokens) do
    local keyword_langs = config.get_keyword_languages(token)

    if keyword_langs then
      local hl_group = nil

      if detected_language then
        for _, lang_info in ipairs(keyword_langs) do
          if lang_info.language == detected_language then
            hl_group = lang_info.hl
            break
          end
        end
      else
        hl_group = keyword_langs[1].hl
      end

      if hl_group then
        local start_pos = 1

        while true do
          local match_start, match_end = line_content:find(token, start_pos, true)

          if not match_start then
            break
          end

          local before_char = match_start > 1 and line_content:sub(match_start - 1, match_start - 1) or ' '
          local after_char = match_end < #line_content and line_content:sub(match_end + 1, match_end + 1) or ' '

          local is_whole_word = not before_char:match('[%w_]') and not after_char:match('[%w_]')

          if is_whole_word then
            local col_start = match_start - 1
            local col_end = match_end
            if not col_end then
              col_end = col_start + #token
            end

            highlight_range(bufnr, line_num, col_start, col_end, hl_group)
          end

          start_pos = match_end + 1
        end
      end
    end
  end
end

--- Highlight individual characters in a line based on character groups
---@param bufnr integer Buffer number
---@param line_num integer Line number (0-indexed)
---@param line_content string Content of the line
local function highlight_characters(bufnr, line_num, line_content)
  local chars = vim.fn.split(line_content, '\\zs')
  local byte_pos = 0

  for _, char in ipairs(chars) do
    local hl_group = config.get_char_highlight(char)

    if hl_group then
      local char_len = #char
      highlight_range(bufnr, line_num, byte_pos, byte_pos + char_len, hl_group)
    end

    byte_pos = byte_pos + #char
  end
end

--- Highlight an entire ASCII block
---@param bufnr integer Buffer number
---@param block ColorMyAscii.Block Block to highlight
function M.highlight_block(bufnr, block)
  local user_config = config.get()

  local detected_language = language_detector.detect_language(bufnr, block, block.fence_line)

  local content_start = block.start_line + 1

  for i, line_content in ipairs(block.lines) do
    local line_num = content_start + i - 1

    -- Pass 1: Apply default text highlight to entire line (lowest priority)
    if user_config.default_text_hl then
      highlight_range(bufnr, line_num, 0, #line_content, user_config.default_text_hl)
    end

    -- Pass 2: Highlight special characters (will override default_text_hl)
    highlight_characters(bufnr, line_num, line_content)

    -- Pass 3: Highlight function names (higher priority)
    highlight_function_names(bufnr, line_num, line_content)

    -- Pass 4: Highlight keywords (highest priority, will override everything)
    highlight_keywords(bufnr, line_num, line_content, detected_language)
  end
end

--- Highlight inline code segments
---@param bufnr integer Buffer number
function M.highlight_inline_codes(bufnr)
  local inline_codes = parser.find_inline_codes(bufnr)
  local user_config = config.get()

  for _, inline in ipairs(inline_codes) do
    local line_content = inline.content
    local content_start_col = inline.start_col + 1  -- After opening backtick

    -- Pass 1: Apply default text highlight if configured
    if user_config.default_text_hl then
      highlight_range(bufnr, inline.line, content_start_col, inline.end_col, user_config.default_text_hl)
    end

    -- Pass 2: Highlight special characters in inline code
    local chars = vim.fn.split(line_content, '\\zs')
    local rel_byte_pos = 0

    for _, char in ipairs(chars) do
      local hl_group = config.get_char_highlight(char)

      if hl_group then
        local char_len = #char
        local abs_start = content_start_col + rel_byte_pos
        local abs_end = abs_start + char_len
        highlight_range(bufnr, inline.line, abs_start, abs_end, hl_group)
      end

      rel_byte_pos = rel_byte_pos + #char
    end

    -- Pass 3: Highlight function names in inline code
    if config.is_function_detection_enabled() then
      local pattern = '([%w_]+)%s*%('
      local start_pos = 1

      while true do
        local match_start, match_end, func_name = line_content:find(pattern, start_pos)

        if not match_start then
          break
        end

        local func_end = match_start + #func_name - 1
        local keyword_langs = config.get_keyword_languages(func_name)

        if not keyword_langs then
          local abs_start = content_start_col + match_start - 1
          local abs_end = content_start_col + func_end
          highlight_range(bufnr, inline.line, abs_start, abs_end, 'Function')
        end

        start_pos = match_end + 1
      end
    end

    -- Pass 4: Highlight keywords in inline code (ALL keywords from ALL languages)
    if user_config.enable_keywords then
      local tokens = parser.tokenize_line(line_content)

      for _, token in ipairs(tokens) do
        local keyword_langs = config.get_keyword_languages(token)

        if keyword_langs then
          -- Use first matching language (no language detection for inline code)
          local hl_group = keyword_langs[1].hl

          local start_pos = 1
          while true do
            local match_start, match_end = line_content:find(token, start_pos, true)
            if not match_start then
              break
            end

            local before_char = match_start > 1 and line_content:sub(match_start - 1, match_start - 1) or ' '
            local after_char = match_end < #line_content and line_content:sub(match_end + 1, match_end + 1) or ' '
            local is_whole_word = not before_char:match('[%w_]') and not after_char:match('[%w_]')

            if is_whole_word then
              local abs_start = content_start_col + match_start - 1
              local abs_end = content_start_col + match_end
              highlight_range(bufnr, inline.line, abs_start, abs_end, hl_group)
            end

            start_pos = match_end + 1
          end
        end
      end
    end
  end
end

return M
