---@module 'color_my_ascii.highlighter'
--- Highlighter module for applying colors to ASCII art characters.
--- Uses extmarks for non-intrusive highlighting that doesn't modify buffer content.
--- Implements safe API calls and error recovery.

local M = {}

local config = require('color_my_ascii.config')
local parser = require('color_my_ascii.parser')
local language_detector = require('color_my_ascii.language_detector')
local safe_api = require('color_my_ascii.utils.safe_api')

--- Namespace ID for extmarks
---@type integer
local namespace = vim.api.nvim_create_namespace('ColorMyAscii')

--- Storage for extmark IDs per buffer for efficient cleanup
---@type table<integer, integer[]>
local buffer_extmarks = {}

--- Cache for parsed blocks to avoid redundant processing
---@type table<integer, {blocks: ColorMyAscii.Block[], timestamp: number}>
local parse_cache = setmetatable({}, { __mode = 'k' })

--- Cache invalidation timeout (milliseconds)
local CACHE_TIMEOUT = 5000

--- Clear all highlights in a buffer
--- Uses safe API with error handling
---@param bufnr integer Buffer number to clear
---@return boolean success True if clearing succeeded
---@return string|nil error Error message if failed
function M.clear_buffer(bufnr)
  -- Validate buffer first
  if not safe_api.is_valid_buffer(bufnr) then
    return false, string.format('Cannot clear invalid buffer %d', bufnr)
  end

  -- Clear namespace safely
  local success, _, err = safe_api.buf_clear_namespace(bufnr, namespace, 0, -1)
  if not success then
    return false, string.format('Failed to clear namespace in buffer %d: %s', bufnr, err or 'unknown')
  end

  -- Clear extmark tracking
  buffer_extmarks[bufnr] = nil

  -- Clear parse cache
  parse_cache[bufnr] = nil

  return true, nil
end

--- Apply highlighting to a single character range
--- Uses safe extmark creation with validation
---@param bufnr integer Buffer number
---@param line integer Line number (0-indexed)
---@param col_start integer Start column (0-indexed, byte offset)
---@param col_end integer End column (0-indexed, byte offset, exclusive)
---@param hl_group string|ColorMyAscii.CustomHighlight Highlight group name
---@return boolean success True if highlighting succeeded
---@return string|nil error Error message if failed
local function highlight_range(bufnr, line, col_start, col_end, hl_group)
  -- Validate buffer
  if not safe_api.is_valid_buffer(bufnr) then
    return false, string.format('Invalid buffer %d', bufnr)
  end

  -- Validate highlight group
  if type(hl_group) ~= 'string' or hl_group == '' then
    return false, 'Invalid highlight group'
  end

  -- Create extmark with safe API
  local success, extmark_id, err = safe_api.buf_set_extmark(
    bufnr,
    namespace,
    line,
    col_start,
    {
      end_col = col_end,
      hl_group = hl_group,
      priority = 100,
    }
  )

  if not success then
    return false, string.format('Failed to set extmark: %s', err or 'unknown')
  end

  -- Track extmark for cleanup
  buffer_extmarks[bufnr] = buffer_extmarks[bufnr] or {}
  table.insert(buffer_extmarks[bufnr], extmark_id)

  return true, nil
end

--- Detect and highlight function names (heuristic: word followed by '(')
--- Uses safe token extraction and error handling
---@param bufnr integer Buffer number
---@param line_num integer Line number (0-indexed)
---@param line_content string Content of the line
---@return boolean success True if processing succeeded
---@return string|nil error Error message if failed
local function highlight_function_names(bufnr, line_num, line_content)
  if not config.is_function_detection_enabled() then
    return true, nil
  end

  -- Validate input
  if type(line_content) ~= 'string' then
    return false, 'Invalid line content type'
  end

  local pattern = '([%w_]+)%s*%('
  local start_pos = 1
  local errors = {}

  while true do
    -- Safe pattern matching with pcall
    local ok, match_start, match_end, func_name = pcall(string.find, line_content, pattern, start_pos)

    if not ok then
      table.insert(errors, string.format('Pattern matching failed at position %d', start_pos))
      break
    end

    if not match_start then
      break
    end

    local func_end = match_start + #func_name - 1
    local keyword_langs = config.get_keyword_languages(func_name)

    -- Only highlight if not already a keyword
    if not keyword_langs then
      local success, err = highlight_range(bufnr, line_num, match_start - 1, func_end, 'Function')
      if not success then
        table.insert(errors, err)
      end
    end

    start_pos = match_end + 1
  end

  if #errors > 0 then
    return false, table.concat(errors, '; ')
  end

  return true, nil
end

--- Highlight keywords in a line
--- Uses optimized token extraction with error recovery
---@param bufnr integer Buffer number
---@param line_num integer Line number (0-indexed)
---@param line_content string Content of the line
---@param detected_language string|nil Detected language for this block (nil = all languages)
---@return boolean success True if processing succeeded
---@return string|nil error Error message if failed
local function highlight_keywords(bufnr, line_num, line_content, detected_language)
  local user_config = config.get()

  if not user_config.enable_keywords then
    return true, nil
  end

  -- Validate input
  if type(line_content) ~= 'string' then
    return false, 'Invalid line content type'
  end

  -- Safe token extraction
  local tokens, parse_err = parser.tokenize_line(line_content)
  if parse_err then
    return false, string.format('Token extraction failed: %s', parse_err)
  end

  local errors = {}

  for _, token in ipairs(tokens) do
    local keyword_langs = config.get_keyword_languages(token)

    if keyword_langs then
      local hl_group = nil

      -- Select appropriate highlight group
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
          -- Safe string search
          local ok, match_start, match_end = pcall(string.find, line_content, token, start_pos, true)

          if not ok or not match_start then
            break
          end

          -- Validate word boundaries
          local before_char = match_start > 1 and line_content:sub(match_start - 1, match_start - 1) or ' '
          local after_char = match_end < #line_content and line_content:sub(match_end + 1, match_end + 1) or ' '

          local is_whole_word = not before_char:match('[%w_]') and not after_char:match('[%w_]')

          if is_whole_word then
            local col_start = match_start - 1
            local col_end = match_end
            if not col_end then col_end = col_start + #token end

            local success, err = highlight_range(bufnr, line_num, col_start, col_end, hl_group)
            if not success then
              table.insert(errors, err)
            end
          end

          start_pos = match_end + 1
        end
      end
    end
  end

  if #errors > 0 then
    return false, table.concat(errors, '; ')
  end

  return true, nil
end

--- Highlight individual characters in a line based on character groups
--- Uses optimized UTF-8 iteration with error handling
---@param bufnr integer Buffer number
---@param line_num integer Line number (0-indexed)
---@param line_content string Content of the line
---@return boolean success True if processing succeeded
---@return string|nil error Error message if failed
local function highlight_characters(bufnr, line_num, line_content)
  -- Validate input
  if type(line_content) ~= 'string' then
    return false, 'Invalid line content type'
  end

  -- Safe character splitting
  local ok, chars = pcall(vim.fn.split, line_content, '\\zs')
  if not ok then
    return false, 'Failed to split line into characters'
  end

  local byte_pos = 0
  local errors = {}

  for _, char in ipairs(chars) do
    local hl_group = config.get_char_highlight(char)

    if hl_group then
      local char_len = #char
      local success, err = highlight_range(bufnr, line_num, byte_pos, byte_pos + char_len, hl_group)

      if not success then
        table.insert(errors, string.format('char "%s" at pos %d: %s', char, byte_pos, err))
      end
    end

    byte_pos = byte_pos + #char
  end

  if #errors > 0 then
    return false, table.concat(errors, '; ')
  end

  return true, nil
end

--- Check if cache is still valid for buffer
---@param bufnr integer Buffer number
---@return boolean valid True if cache is valid
local function is_cache_valid(bufnr)
  local cached = parse_cache[bufnr]
  if not cached then
    return false
  end

  local now = vim.loop.now()
  return (now - cached.timestamp) < CACHE_TIMEOUT
end

--- Highlight an entire ASCII block with error recovery
---@param bufnr integer Buffer number
---@param block ColorMyAscii.Block Block to highlight
---@return boolean success True if highlighting succeeded
---@return string|nil error Error message if failed
function M.highlight_block(bufnr, block)
  -- Validate buffer
  if not safe_api.is_valid_buffer(bufnr) then
    return false, string.format('Invalid buffer %d', bufnr)
  end

  local user_config = config.get()
  local detected_language = language_detector.detect_language(bufnr, block, block.fence_line)
  local content_start = block.start_line + 1

  local errors = {}

  for i, line_content in ipairs(block.lines) do
    local line_num = content_start + i - 1

    -- Pass 1: Apply default text highlight to entire line (lowest priority)
    if user_config.default_text_hl then
      local success, err = highlight_range(bufnr, line_num, 0, #line_content, user_config.default_text_hl)
      if not success then
        table.insert(errors, string.format('line %d default: %s', line_num, err))
      end
    end

    -- Pass 2: Highlight special characters (will override default_text_hl)
    local success, err = highlight_characters(bufnr, line_num, line_content)
    if not success then
      table.insert(errors, string.format('line %d chars: %s', line_num, err))
    end

    -- Pass 3: Highlight function names (higher priority)
    success, err = highlight_function_names(bufnr, line_num, line_content)
    if not success then
      table.insert(errors, string.format('line %d functions: %s', line_num, err))
    end

    -- Pass 4: Highlight keywords (highest priority)
    success, err = highlight_keywords(bufnr, line_num, line_content, detected_language)
    if not success then
      table.insert(errors, string.format('line %d keywords: %s', line_num, err))
    end
  end

  if #errors > 0 then
    return false, table.concat(errors, '\n')
  end

  return true, nil
end

--- Highlight inline code segments with error recovery
---@param bufnr integer Buffer number
---@return boolean success True if highlighting succeeded
---@return string|nil error Error message if failed
function M.highlight_inline_codes(bufnr)
  -- Validate buffer
  if not safe_api.is_valid_buffer(bufnr) then
    return false, string.format('Invalid buffer %d', bufnr)
  end

  local inline_codes, parse_err = parser.find_inline_codes(bufnr)
  if parse_err then
    return false, string.format('Failed to find inline codes: %s', parse_err)
  end

  local user_config = config.get()
  local errors = {}

  for _, inline in ipairs(inline_codes) do
    local line_content = inline.content
    local content_start_col = inline.start_col + 1  -- After opening backtick

    -- Pass 1: Apply default text highlight if configured
    if user_config.default_text_hl then
      local success, err = highlight_range(
        bufnr,
        inline.line,
        content_start_col,
        inline.end_col,
        user_config.default_text_hl
      )
      if not success then
        table.insert(errors, string.format('inline %d default: %s', inline.line, err))
      end
    end

    -- Pass 2: Highlight special characters
    local ok, chars = pcall(vim.fn.split, line_content, '\\zs')
    if ok then
      local rel_byte_pos = 0

      for _, char in ipairs(chars) do
        local hl_group = config.get_char_highlight(char)

        if hl_group then
          local char_len = #char
          local abs_start = content_start_col + rel_byte_pos
          local abs_end = abs_start + char_len

          local success, err = highlight_range(bufnr, inline.line, abs_start, abs_end, hl_group)
          if not success then
            table.insert(errors, string.format('inline %d char: %s', inline.line, err))
          end
        end

        rel_byte_pos = rel_byte_pos + #char
      end
    end

    -- Pass 3: Highlight function names
    if config.is_function_detection_enabled() then
      local pattern = '([%w_]+)%s*%('
      local start_pos = 1

      while true do
        local ok_match, match_start, match_end, func_name = pcall(
          string.find,
          line_content,
          pattern,
          start_pos
        )

        if not ok_match or not match_start then
          break
        end

        local func_end = match_start + #func_name - 1
        local keyword_langs = config.get_keyword_languages(func_name)

        if not keyword_langs then
          local abs_start = content_start_col + match_start - 1
          local abs_end = content_start_col + func_end

          local success, err = highlight_range(bufnr, inline.line, abs_start, abs_end, 'Function')
          if not success then
            table.insert(errors, string.format('inline %d func: %s', inline.line, err))
          end
        end

        start_pos = match_end + 1
      end
    end

    -- Pass 4: Highlight keywords
    if user_config.enable_keywords then
      local tokens, token_err = parser.tokenize_line(line_content)

      if not token_err then
        for _, token in ipairs(tokens) do
          local keyword_langs = config.get_keyword_languages(token)

          if keyword_langs then
            local hl_group = keyword_langs[1].hl
            local start_pos = 1

            while true do
              local ok_find, match_start, match_end = pcall(
                string.find,
                line_content,
                token,
                start_pos,
                true
              )

              if not ok_find or not match_start then
                break
              end

              local before_char = match_start > 1
                and line_content:sub(match_start - 1, match_start - 1)
                or ' '
              local after_char = match_end < #line_content
                and line_content:sub(match_end + 1, match_end + 1)
                or ' '

              local is_whole_word = not before_char:match('[%w_]')
                and not after_char:match('[%w_]')

              if is_whole_word then
                local abs_start = content_start_col + match_start - 1
                local abs_end = content_start_col + match_end

                local success, err = highlight_range(bufnr, inline.line, abs_start, abs_end, hl_group)
                if not success then
                  table.insert(errors, string.format('inline %d keyword: %s', inline.line, err))
                end
              end

              start_pos = match_end + 1
            end
          end
        end
      end
    end
  end

  if #errors > 0 then
    return false, table.concat(errors, '\n')
  end

  return true, nil
end

--- Highlight buffer with caching and error recovery
---@param bufnr integer Buffer number
---@return boolean success True if highlighting succeeded
---@return string|nil error Error message if failed
function M.highlight_buffer_cached(bufnr)
  -- Check cache first
  if is_cache_valid(bufnr) then
    local cached = parse_cache[bufnr]

    for _, block in ipairs(cached.blocks) do
      local success, err = M.highlight_block(bufnr, block)
      if not success then
        return false, err
      end
    end

    return M.highlight_inline_codes(bufnr)
  end

  -- Parse and cache
  local blocks, parse_err = parser.find_ascii_blocks(bufnr)
  if parse_err then
    return false, string.format('Failed to parse blocks: %s', parse_err)
  end

  -- Update cache
  parse_cache[bufnr] = {
    blocks = blocks,
    timestamp = vim.loop.now(),
  }

  -- Highlight
  for _, block in ipairs(blocks) do
    local success, err = M.highlight_block(bufnr, block)
    if not success then
      return false, err
    end
  end

  return M.highlight_inline_codes(bufnr)
end

return M
