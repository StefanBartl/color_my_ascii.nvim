---@module 'color_my_ascii.parser'
--- Parser module for identifying ASCII code blocks and inline code in markdown buffers.
--- Finds fenced ASCII code blocks and inline code segments.

local M = {}

local api = vim.api

--- Decide whether a fence's language tag should be treated as an ASCII block.
--- Shared classification rule used by both the heuristic line-scanner below and
--- the treesitter-backed parser (parser_ts.lua), so both backends agree on which
--- blocks count as ASCII regardless of how they detected the fence.
---@param lang string Fence language tag, already trimmed (e.g. "ascii-c", "vim", "")
---@return boolean is_ascii
function M.is_ascii_fence(lang)
  local cfg = require("color_my_ascii.config").get()

  local is_ascii = lang:match("^ascii") ~= nil
  local is_empty = lang == ""
  local is_mapped = cfg.fence_language_map ~= nil and cfg.fence_language_map[lang] ~= nil

  return is_ascii or is_mapped or (is_empty and cfg.treat_empty_fence_as_ascii) or false
end

--- Scan a buffer for ALL fenced code blocks (ASCII or not) via a manual
--- line-by-line state machine. This is the generic foundation shared by the
--- ASCII-only heuristic (M.find_ascii_blocks_heuristic) and the public fence
--- API (color_my_ascii.api.fences); it tracks every code block so closing
--- fences of non-ASCII blocks are never misinterpreted.
---
--- Content-line collection is opt-in to keep the common range-only callers
--- (fence highlighting, markdown scope) cheap:
---   - "none"  → never collect `lines` (default)
---   - "ascii" → collect `lines` only for ASCII blocks (highlighter path)
---   - "all"   → collect `lines` for every block
---
--- Fence close semantics deliberately match the original ASCII scanner: a
--- closing fence only needs length >= the opening fence (no delimiter-char
--- check), so existing block detection is unchanged.
---@param bufnr integer Buffer number to search
---@param opts? { lines?: "none"|"ascii"|"all" }
---@return ColorMyAscii.FenceBlock[] blocks Every closed fenced block, in order
function M.scan_blocks_heuristic(bufnr, opts)
  local cfg = require("color_my_ascii.config").get()
  local lines_mode = (opts and opts.lines) or "none"

  ---@type ColorMyAscii.FenceBlock[]
  local blocks = {}

  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local line_count = #lines

  --- State: are we currently inside ANY code block?
  local in_block = false

  --- Information about currently open fence (nil if not in block).
  ---@type table?
  local open_fence_info = nil

  local function wants_lines(is_ascii)
    return lines_mode == "all" or (lines_mode == "ascii" and is_ascii)
  end

  for i = 1, line_count do
    local line = lines[i]

    -- Try to match a fence line (backtick or tilde)
    local fence_char = "`"
    local fence, lang = line:match("^%s*(```+)%s*(.*)$")
    if not fence then
      fence, lang = line:match("^%s*(~~~+)%s*(.*)$")
      fence_char = "~"
    end

    if fence then
      -- Normalize language (trim whitespace)
      lang = vim.trim(lang or "")

      if not in_block then
        -- We're OUTSIDE any block: this fence opens a new block
        local track_as_ascii = M.is_ascii_fence(lang)

        -- Start tracking this block (ASCII or not)
        in_block = true
        open_fence_info = {
          start_line = i,
          fence_line = line,
          fence_length = #fence,
          fence_char = fence_char,
          lang = lang,
          is_ascii = track_as_ascii,
          block_lines = {},
        }

      else
        -- We're INSIDE a block: this fence closes it
        -- Check fence length (closing must be >= opening)
        if open_fence_info and #fence >= open_fence_info.fence_length then
          -- Valid closing fence
          local of = open_fence_info
          table.insert(blocks, {
            open_row      = of.start_line - 1, -- 0-indexed
            close_row     = i - 1,             -- 0-indexed
            content_start = of.start_line,     -- 0-indexed first content row (open_row + 1)
            content_end   = i - 1,             -- 0-indexed exclusive end (== close_row)
            lang          = of.lang,
            fence_char    = of.fence_char,
            fence_len     = of.fence_length,
            is_ascii      = of.is_ascii,
            lines         = wants_lines(of.is_ascii) and of.block_lines or nil,
            fence_line    = of.fence_line,
            -- ColorMyAscii.Block aliases (backward compat):
            start_line    = of.start_line - 1,
            end_line      = i - 1,
          })

          -- Reset state
          in_block = false
          open_fence_info = nil
        end
        -- else: fence too short, treat as content
      end

    elseif in_block and open_fence_info then
      -- Not a fence, and we're in a block: collect line if requested
      if wants_lines(open_fence_info.is_ascii) then
        table.insert(open_fence_info.block_lines, line)
      end
    end
  end

  -- If block is still open at EOF, log warning only for ASCII blocks and only in debug mode
  if in_block and open_fence_info and open_fence_info.is_ascii and cfg.debug_enabled then
    vim.notify(
      string.format("Unclosed ASCII block at line %d", open_fence_info.start_line),
      vim.log.levels.WARN
    )
  end

  return blocks
end

--- Find all ASCII code blocks in the buffer using the heuristic line scanner.
--- Thin filter over M.scan_blocks_heuristic. This is the fallback parser used
--- when treesitter-based detection is disabled, unavailable, or fails (see
--- M.find_ascii_blocks). Returned blocks satisfy ColorMyAscii.Block.
---@param bufnr integer Buffer number to search
---@return ColorMyAscii.Block[] blocks List of found ASCII blocks
function M.find_ascii_blocks_heuristic(bufnr)
  local blocks = {}
  for _, b in ipairs(M.scan_blocks_heuristic(bufnr, { lines = "ascii" })) do
    if b.is_ascii then
      table.insert(blocks, b)
    end
  end
  return blocks
end

--- Find all ASCII code blocks in the buffer.
--- Dispatches to the treesitter-backed parser (parser_ts.lua) when
--- config.treesitter.{enabled,block_detection} are both true and a markdown
--- parser is available; falls back to the heuristic line scanner otherwise
--- (including when the treesitter path errors), so this always returns a result.
---@param bufnr integer Buffer number to search
---@return ColorMyAscii.Block[] blocks List of found ASCII blocks
function M.find_ascii_blocks(bufnr)
  local cfg = require("color_my_ascii.config").get()
  local ts_cfg = cfg.treesitter

  if ts_cfg and ts_cfg.enabled and ts_cfg.block_detection then
    local parser_ts = require("color_my_ascii.parser_ts")

    if parser_ts.markdown_available() then
      local ok, blocks = pcall(parser_ts.find_ascii_blocks, bufnr)
      if ok then
        return blocks
      end

      if cfg.debug_enabled then
        vim.notify(
          string.format("color_my_ascii: Treesitter block detection failed, falling back to heuristic parser: %s", tostring(blocks)),
          vim.log.levels.WARN
        )
      end
    end
  end

  return M.find_ascii_blocks_heuristic(bufnr)
end

--- Find ALL fenced code blocks in the buffer (ASCII or not), with precise
--- ranges + metadata. Mirrors M.find_ascii_blocks' dispatch: treesitter when
--- available and enabled, heuristic scanner otherwise (and on TS error), so it
--- always returns a result. This is the generic entry point consumed by the
--- public fence API (color_my_ascii.api.fences).
---@param bufnr integer Buffer number to search
---@param opts? { lines?: "none"|"ascii"|"all" }
---@return ColorMyAscii.FenceBlock[] blocks Every closed fenced block, in order
function M.find_all_blocks(bufnr, opts)
  local cfg = require("color_my_ascii.config").get()
  local ts_cfg = cfg.treesitter

  if ts_cfg and ts_cfg.enabled and ts_cfg.block_detection then
    local parser_ts = require("color_my_ascii.parser_ts")

    if parser_ts.markdown_available() then
      local ok, blocks = pcall(parser_ts.scan_blocks_ts, bufnr, opts)
      if ok then
        return blocks
      end

      if cfg.debug_enabled then
        vim.notify(
          string.format("color_my_ascii: Treesitter block scan failed, falling back to heuristic parser: %s", tostring(blocks)),
          vim.log.levels.WARN
        )
      end
    end
  end

  return M.scan_blocks_heuristic(bufnr, opts)
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
