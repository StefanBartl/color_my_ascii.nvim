---@module 'color_my_ascii.parser'
--- Parser module for identifying ASCII code blocks and inline code in markdown buffers.
--- Finds fenced ASCII code blocks and inline code segments with safe error handling.

local M = {}

local safe_api = require('color_my_ascii.utils.safe_api')

--- Check if a line is an opening fence for an ASCII code block.
--- Supports fenced code blocks using ``` or ~~~.
--- Recognized forms:
---   ```ascii
---   ```ascii-c
---   ```ascii lua
---   ```ascii:python
--- Optionally treats empty fences (``` or ~~~ without language) as ASCII.
---@param line string Line content to check
---@param treat_empty_as_ascii boolean Whether to treat empty fences as ASCII
---@return boolean is_ascii_fence True if line opens an ASCII code block
local function is_ascii_fence_start(line, treat_empty_as_ascii)
  -- Validate input
  if type(line) ~= 'string' then
    return false
  end

  -- Detect fences explicitly marked as ASCII
  local has_ascii = line:match("^%s*```+%s*ascii") ~= nil
    or line:match("^%s*~~~+%s*ascii") ~= nil

  if has_ascii then
    return true
  end

  -- Optionally treat empty fences as ASCII blocks
  if treat_empty_as_ascii then
    if line:match("^%s*```+%s*$") ~= nil or line:match("^%s*~~~+%s*$") ~= nil then
      return true
    end
  end

  return false
end

--- Check if a line is a closing fence.
---@param line string Line content to check
---@return boolean is_fence True if line closes a code block
local function is_fence_end(line)
  if type(line) ~= 'string' then
    return false
  end

  -- Match ``` or ~~~ with optional surrounding whitespace
  return line:match("^%s*```+%s*$") ~= nil or line:match("^%s*~~~+%s*$") ~= nil
end

--- Find all ASCII code blocks in the buffer.
--- Uses safe API calls with error handling.
---@param bufnr integer Buffer number to search
---@return ColorMyAscii.Block[] blocks List of found ASCII blocks
---@return string|nil error Error message if operation failed
function M.find_ascii_blocks(bufnr)
  local cfg = require('color_my_ascii.config').get()

  ---@type ColorMyAscii.Block[]
  local blocks = {}

  -- Safe buffer line retrieval
  local success, lines, err = safe_api.buf_get_lines(bufnr, 0, -1, false)
  if not success or lines == nil then
    return blocks, string.format('Failed to read buffer %d: %s', bufnr, err or 'unknown error')
  end

  local line_count = #lines

  local i = 1
  while i <= line_count do
    local line = lines[i]

    -- Check if this line starts an ASCII block
    if is_ascii_fence_start(line, cfg.treat_empty_fence_as_ascii) then
      local start_line = i
      local fence_line = line
      ---@type string[]
      local block_lines = {}

      -- Scan forward to find the closing fence
      i = i + 1
      while i <= line_count do
        local content_line = lines[i]

        if is_fence_end(content_line) then
          table.insert(blocks, {
            start_line = start_line - 1,
            end_line = i - 1,
            lines = block_lines,
            fence_line = fence_line,
          })
          break
        end

        table.insert(block_lines, content_line)
        i = i + 1
      end
    end

    i = i + 1
  end

  return blocks, nil
end

--- Extract text segments from a line for keyword matching.
--- Splits on non-alphanumeric characters to isolate potential keywords.
--- Uses optimized pattern matching with error handling.
---@param line string Line to tokenize
---@return string[] tokens List of word tokens
---@return string|nil error Error message if tokenization failed
function M.tokenize_line(line)
  ---@type string[]
  local tokens = {}

  -- Validate input
  if type(line) ~= 'string' then
    return tokens, 'Invalid line type: expected string'
  end

  if line == '' then
    return tokens, nil
  end

  -- Safe pattern matching with pcall
  local success, err = pcall(function()
    -- Match sequences of alphanumeric characters and underscores
    for word in line:gmatch("[%w_]+") do
      table.insert(tokens, word)
    end

    -- Match common multi-character operators explicitly
    local operators = {
      ":=", "==", "!=", "<=", ">=", "&&", "||",
      "->", "<-", "++", "--", "...", "::",
      "+=", "-=", "*=", "/=", "%=",
      "&=", "|=", "^=", "<<", ">>", ">>=", "<<=",
    }

    for _, op in ipairs(operators) do
      -- Use plain search for safety
      if line:find(op, 1, true) then
        table.insert(tokens, op)
      end
    end
  end)

  if not success then
    return tokens, string.format('Tokenization failed: %s', tostring(err))
  end

  return tokens, nil
end

--- Get the byte offset of a specific column in a line (UTF-8 aware).
--- Handles multi-byte UTF-8 characters correctly.
---@param line string Line content
---@param col integer Column number (0-indexed, character-based)
---@return integer byte_offset Byte offset in the line
---@return string|nil error Error message if operation failed
function M.get_byte_offset(line, col)
  -- Validate input
  if type(line) ~= 'string' then
    return 0, 'Invalid line type: expected string'
  end

  if type(col) ~= 'number' or col < 0 then
    return 0, 'Invalid column: must be non-negative number'
  end

  if col == 0 then
    return 0, nil
  end

  local byte_offset = 0
  local char_count = 0

  -- Safe UTF-8 iteration with error handling
  local success, err = pcall(function()
    for _, char in vim.str_utf_pos(line) do
      if char_count >= col then
        return
      end
      byte_offset = byte_offset + #char
      char_count = char_count + 1
    end
  end)

  if not success then
    return byte_offset, string.format('Byte offset calculation failed: %s', tostring(err))
  end

  return byte_offset, nil
end

---@class ColorMyAscii.InlineCode
---@field line integer Line number (0-indexed)
---@field start_col integer Start column (0-indexed, byte offset)
---@field end_col integer End column (0-indexed, byte offset, exclusive)
---@field content string Content inside backticks

--- Find all inline code segments in a buffer.
--- Uses safe API calls and error handling.
---@param bufnr integer Buffer number
---@return ColorMyAscii.InlineCode[] inline_codes List of inline code segments
---@return string|nil error Error message if operation failed
function M.find_inline_codes(bufnr)
  local cfg = require('color_my_ascii.config').get()

  if not cfg.enable_inline_code then
    return {}, nil
  end

  ---@type ColorMyAscii.InlineCode[]
  local inline_codes = {}

  -- Safe buffer line retrieval
  local success, lines, err = safe_api.buf_get_lines(bufnr, 0, -1, false)
  if not success or lines == nil then
    return inline_codes, string.format('Failed to read buffer %d: %s', bufnr, err or 'unknown error')
  end

  for line_num, line in ipairs(lines) do
    if type(line) ~= 'string' then
      -- Skip invalid lines
      goto continue
    end

    local i = 1
    while i <= #line do
      -- Find opening backtick (plain search for safety)
      local start_pos = line:find("`", i, true)
      if not start_pos then
        break
      end

      -- Find closing backtick
      local end_pos = line:find("`", start_pos + 1, true)
      if not end_pos then
        break
      end

      -- Extract content
      local content = line:sub(start_pos + 1, end_pos - 1)

      if #content > 0 then
        table.insert(inline_codes, {
          line = line_num - 1,
          start_col = start_pos - 1,
          end_col = end_pos,
          content = content,
        })
      end

      i = end_pos + 1
    end

    ::continue::
  end

  return inline_codes, nil
end

return M
