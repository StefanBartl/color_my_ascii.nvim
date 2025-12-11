---@module 'color_my_ascii.highlighter'
--- Highlighter module for applying colors to ASCII art characters.
--- Uses extmarks for non-intrusive highlighting that doesn't modify buffer content.

local M = {}

local config = require('color_my_ascii.config')
local parser = require('color_my_ascii.parser')
local language_detector = require('color_my_ascii.language_detector')

--- Namespace ID for extmarks
---@type integer
local namespace = vim.api.nvim_create_namespace('ColorMyAscii')

--- Storage for extmark IDs per buffer for efficient cleanup
---@type table<integer, integer[]>
local buffer_extmarks = {}

--- Clear all highlights in a buffer
---@param bufnr integer Buffer number to clear
function M.clear_buffer(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
  buffer_extmarks[bufnr] = nil
end

--- Apply highlighting to a single character
---@param bufnr integer Buffer number
---@param line integer Line number (0-indexed)
---@param col_start integer Start column (0-indexed, byte offset)
---@param col_end integer End column (0-indexed, byte offset, exclusive)
---@param hl_group string|ColorMyAscii.CustomHighlight Highlight group name
local function highlight_range(bufnr, line, col_start, col_end, hl_group)
  local extmark_id = vim.api.nvim_buf_set_extmark(bufnr, namespace, line, col_start, {
    end_col = col_end,
    hl_group = hl_group,
    priority = 100,
  })

  buffer_extmarks[bufnr] = buffer_extmarks[bufnr] or {}
  table.insert(buffer_extmarks[bufnr], extmark_id)
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

  -- Tokenize line to find potential keywords
  local tokens = parser.tokenize_line(line_content)

  for _, token in ipairs(tokens) do
    local keyword_langs = config.get_keyword_languages(token)

    if keyword_langs then
      -- Determine which language to use
      local hl_group = nil

      if detected_language then
        -- Use detected language if keyword exists in it
        for _, lang_info in ipairs(keyword_langs) do
          if lang_info.language == detected_language then
            hl_group = lang_info.hl
            break
          end
        end
      else
        -- No language detected: use first match
        hl_group = keyword_langs[1].hl
      end

      if hl_group then
        -- Find all occurrences of this keyword in the line
        local start_pos = 1

        while true do
          local match_start, match_end = line_content:find(token, start_pos, true)

          if not match_start then
            break
          end

          -- Check if this is a whole word (not part of a larger identifier)
          local before_char = match_start > 1 and line_content:sub(match_start - 1, match_start - 1) or ' '
          local after_char = match_end < #line_content and line_content:sub(match_end + 1, match_end + 1) or ' '

          local is_whole_word = not before_char:match('[%w_]') and not after_char:match('[%w_]')

          if is_whole_word then
            -- Convert string positions to byte offsets (Lua string positions are already byte-based)
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
  -- Use vim.fn.split with '\zs' to split into UTF-8 characters
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

  -- Detect language for this block
  local detected_language = language_detector.detect_language(bufnr, block, block.fence_line)

  -- Highlight each line in the block
  -- Note: block.start_line is the fence line, content starts at start_line + 1
  local content_start = block.start_line + 1

  for i, line_content in ipairs(block.lines) do
    local line_num = content_start + i - 1

    -- Optional: Apply default text highlight to entire line first
    if user_config.default_text_hl then
      highlight_range(bufnr, line_num, 0, #line_content, user_config.default_text_hl)
    end

    -- First pass: highlight special characters (will override default_text_hl)
    highlight_characters(bufnr, line_num, line_content)

    -- Second pass: highlight keywords (highest priority, will override everything)
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

    -- Apply default text highlight if configured
    if user_config.default_text_hl then
      highlight_range(bufnr, inline.line, inline.start_col, inline.end_col, user_config.default_text_hl)
    end

    -- Highlight special characters in inline code
    local chars = vim.fn.split(line_content, '\\zs')
    local rel_byte_pos = 0

    for _, char in ipairs(chars) do
      local hl_group = config.get_char_highlight(char)

      if hl_group then
        local char_len = #char
        -- Adjust position: inline.start_col is the backtick, content starts at +1
        local abs_start = inline.start_col + 1 + rel_byte_pos
        local abs_end = abs_start + char_len
        highlight_range(bufnr, inline.line, abs_start, abs_end, hl_group)
      end

      rel_byte_pos = rel_byte_pos + #char
    end

    -- Highlight keywords in inline code
    local tokens = parser.tokenize_line(line_content)
    for _, token in ipairs(tokens) do
      local keyword_langs = config.get_keyword_languages(token)

      if keyword_langs then
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
            -- Adjust position for inline code
            local abs_start = inline.start_col + 1 + match_start - 1
            local abs_end = inline.start_col + 1 + match_end
            highlight_range(bufnr, inline.line, abs_start, abs_end, hl_group)
          end

          start_pos = match_end + 1
        end
      end
    end
  end
end

return M
