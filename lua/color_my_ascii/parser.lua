---@module 'color_my_ascii.parser'
--- Parser module for identifying ASCII code blocks and inline code in markdown buffers.
--- Finds fenced ASCII code blocks and inline code segments.

local M = {}

local api = vim.api

--- Find all ASCII code blocks in the buffer.
--- Uses a state machine: outside block -> inside block -> outside block.
--- A fence with language is always opening. An empty fence is opening if outside block, closing if inside.
---@param bufnr integer Buffer number to search
---@return ColorMyAscii.Block[] blocks List of found ASCII blocks
function M.find_ascii_blocks(bufnr)
  local cfg = require("color_my_ascii.config").get()

  ---@type ColorMyAscii.Block[]
  local blocks = {}

  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local line_count = #lines

  --- State: are we currently inside an ASCII block?
  local in_block = false

  --- Information about currently open fence (nil if not in block).
  ---@type OpenFenceInfo?
  local open_fence_info = nil

  for i = 1, line_count do
    local line = lines[i]

    -- Try to match a fence line
    local fence, lang = line:match("^%s*(```+)%s*(.*)$")

    -- Also try tilde fences
    if not fence then
      fence, lang = line:match("^%s*(~~~+)%s*(.*)$")
    end

    if fence then
      -- Normalize language (trim whitespace)
      lang = vim.trim(lang or "")

      if not in_block then
        -- We're OUTSIDE a block: check if this fence should start an ASCII block
        local is_ascii = lang:match("^ascii") ~= nil
        local is_empty = lang == ""

        if is_ascii or (is_empty and cfg.treat_empty_fence_as_ascii) then
          -- Start ASCII block
          in_block = true
          open_fence_info = {
            start_line = i,
            fence_line = line,
            fence_length = #fence,
            block_lines = {},
          }
        end
        -- else: fence with other language, ignore

      else
        -- We're INSIDE a block: this fence closes the block
        -- Check fence length (closing must be >= opening)
        if open_fence_info and #fence >= open_fence_info.fence_length then
          -- Valid closing fence
          table.insert(blocks, {
            start_line = open_fence_info.start_line - 1,  -- 0-indexed
            end_line = i - 1,                              -- 0-indexed
            lines = open_fence_info.block_lines,
            fence_line = open_fence_info.fence_line,
          })

          in_block = false
          open_fence_info = nil
        end
        -- else: fence too short, treat as content
      end

    elseif in_block and open_fence_info then
      -- Not a fence, and we're in a block: add line to block content
      table.insert(open_fence_info.block_lines, line)
    end
  end

  -- If block is still open at EOF, discard it silently
  -- (or optionally log a warning)
  if in_block and open_fence_info then
    vim.notify(
      string.format("Unclosed ASCII block at line %d", open_fence_info.start_line),
      vim.log.levels.WARN
    )
  end

  return blocks
end

--- Extract text segments from a line for keyword matching.
--- Splits on non-alphanumeric characters to isolate potential keywords.
---@param line string Line to tokenize
---@return string[] tokens List of word tokens
function M.tokenize_line(line)
  ---@type string[]
  local tokens = {}

  -- Match sequences of alphanumeric characters and underscores
  for word in line:gmatch("[%w_]+") do
    table.insert(tokens, word)
  end

  -- Match common multi-character operators explicitly
  local operators = {
    ":=", "==", "!=", "<=", ">=", "&&", "||",
    "->", "<-", "++", "--", "...", "::",
    "+=", "-=", "*=", "/=", "%=", "&=", "|=", "^=",
    "<<", ">>", ">>=", "<<=",
  }

  for _, op in ipairs(operators) do
    if line:find(op, 1, true) then
      table.insert(tokens, op)
    end
  end

  return tokens
end

--- Get the byte offset of a specific column in a line (UTF-8 aware).
---@param line string Line content
---@param col integer Column number (0-indexed, character-based)
---@return integer byte_offset Byte offset in the line
function M.get_byte_offset(line, col)
  if col == 0 then
    return 0
  end

  local byte_offset = 0
  local char_count = 0

  for _, char in vim.str_utf_pos(line) do
    if char_count >= col then
      break
    end
    byte_offset = byte_offset + #char
    char_count = char_count + 1
  end

  return byte_offset
end

--- Find all inline code segments in a buffer.
---@param bufnr integer Buffer number
---@return ColorMyAscii.InlineCode[] inline_codes List of inline code segments
function M.find_inline_codes(bufnr)
  local cfg = require("color_my_ascii.config").get()

  if not cfg.enable_inline_code then
    return {}
  end

  ---@type ColorMyAscii.InlineCode[]
  local inline_codes = {}

  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for line_num, line in ipairs(lines) do
    local i = 1
    while i <= #line do
      local start_pos = line:find("`", i, true)
      if not start_pos then
        break
      end

      local end_pos = line:find("`", start_pos + 1, true)
      if not end_pos then
        break
      end

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
  end

  return inline_codes
end

return M
