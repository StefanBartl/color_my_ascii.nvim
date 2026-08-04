---@module 'color_my_ascii.parser_ts'
--- Treesitter-backed block detection, used as an alternative to parser.lua's
--- heuristic line scanner when config.treesitter.block_detection is enabled.
--- Verified against tree-sitter-markdown's actual grammar: a `fenced_code_block`
--- node has two `fenced_code_block_delimiter` children (open/close), an optional
--- `info_string` > `language` child holding the fence's language tag, and a
--- `code_fence_content` child spanning the content rows between the delimiters.

local M = {}

local api = vim.api

--- Check whether a markdown treesitter parser is installed and loadable.
---@return boolean available
function M.markdown_available()
  local ok = pcall(vim.treesitter.language.add, 'markdown')
  return ok
end

--- Collect all `fenced_code_block` nodes in the tree (they don't nest, so we
--- don't need to recurse further once one is found).
---@internal
---@param node TSNode
---@param results TSNode[]
local function collect_fenced_blocks(node, results)
  if node:type() == 'fenced_code_block' then
    table.insert(results, node)
    return
  end
  for child in node:iter_children() do
    collect_fenced_blocks(child, results)
  end
end

--- Extract the language tag, content node, and delimiter rows from a
--- `fenced_code_block` node.
---@internal
---@param bufnr integer Buffer number the node belongs to
---@param node TSNode
---@return string lang Trimmed language tag (empty string if none)
---@return TSNode|nil content_node The `code_fence_content` child, if present
---@return integer|nil open_row 0-indexed row of the opening delimiter (nil if none found)
---@return integer|nil close_row 0-indexed row of the closing delimiter (nil if none found)
---@return integer delimiter_count Number of delimiter children found (should be 2 for a closed block)
local function inspect_fenced_block(bufnr, node)
  local lang = ''
  local content_node = nil
  local open_row, close_row = nil, nil
  local delimiter_count = 0

  for child in node:iter_children() do
    local ctype = child:type()

    if ctype == 'info_string' then
      for gc in child:iter_children() do
        if gc:type() == 'language' then
          local lsr, lsc, ler, lec = gc:range()
          local ok, text = pcall(api.nvim_buf_get_text, bufnr, lsr, lsc, ler, lec, {})
          if ok and text[1] then
            lang = vim.trim(text[1])
          end
        end
      end
    elseif ctype == 'code_fence_content' then
      content_node = child
    elseif ctype == 'fenced_code_block_delimiter' then
      local dsr = child:range()
      if delimiter_count == 0 then
        open_row = dsr
      end
      close_row = dsr
      delimiter_count = delimiter_count + 1
    end
  end

  return lang, content_node, open_row, close_row, delimiter_count
end

--- Scan a buffer for ALL fenced code blocks (ASCII or not) using treesitter's
--- markdown grammar. Generic foundation shared by M.find_ascii_blocks and the
--- public fence API (color_my_ascii.api.fences). Callers should wrap this in
--- pcall - it errors out (rather than degrading silently) if the buffer has no
--- markdown parser, so the dispatcher in parser.lua can fall back to the
--- heuristic scanner.
---
--- Content-line collection is opt-in (see parser.scan_blocks_heuristic for the
--- "none"|"ascii"|"all" semantics) to keep range-only callers cheap.
---@param bufnr integer Buffer number to search
---@param opts? { lines?: "none"|"ascii"|"all" }
---@return ColorMyAscii.FenceBlock[] blocks Every closed fenced block, in order
function M.scan_blocks_ts(bufnr, opts)
  local is_ascii_fence = require('color_my_ascii.parser').is_ascii_fence
  local lines_mode = (opts and opts.lines) or 'none'

  local ts_parser = vim.treesitter.get_parser(bufnr, 'markdown')
  local root = ts_parser:parse()[1]:root()

  ---@type TSNode[]
  local fenced_nodes = {}
  collect_fenced_blocks(root, fenced_nodes)

  ---@type ColorMyAscii.FenceBlock[]
  local blocks = {}

  for _, node in ipairs(fenced_nodes) do
    local lang, content_node, open_row, close_row, delimiter_count = inspect_fenced_block(bufnr, node)

    -- Only trust properly closed fences (matches the heuristic scanner's behavior
    -- of ignoring a block that's still open at EOF).
    if delimiter_count == 2 and open_row and close_row then
      local is_ascii = is_ascii_fence(lang)
      local fence_line = api.nvim_buf_get_lines(bufnr, open_row, open_row + 1, false)[1] or ''
      local seq = fence_line:match('^%s*([`~]+)')
      local fence_char = fence_line:match('^%s*([`~])') or '`'

      local want = lines_mode == 'all' or (lines_mode == 'ascii' and is_ascii)
      local content_lines = nil
      if want then
        content_lines = {}
        if content_node then
          local csr, _, cer = content_node:range()
          content_lines = api.nvim_buf_get_lines(bufnr, csr, cer, false)
        end
      end

      table.insert(blocks, {
        open_row = open_row,
        close_row = close_row,
        content_start = open_row + 1,
        content_end = close_row,
        lang = lang,
        fence_char = fence_char,
        fence_len = seq and #seq or 3,
        is_ascii = is_ascii,
        lines = content_lines,
        fence_line = fence_line,
        -- ColorMyAscii.Block aliases (backward compat):
        start_line = open_row,
        end_line = close_row,
      })
    end
  end

  return blocks
end

--- Find all ASCII code blocks in the buffer using treesitter's markdown grammar.
--- Thin filter over M.scan_blocks_ts. Callers should wrap this in pcall (same
--- rationale as M.scan_blocks_ts).
---@param bufnr integer Buffer number to search
---@return ColorMyAscii.Block[] blocks List of found ASCII blocks
function M.find_ascii_blocks(bufnr)
  local blocks = {}
  for _, b in ipairs(M.scan_blocks_ts(bufnr, { lines = 'ascii' })) do
    if b.is_ascii then
      table.insert(blocks, b)
    end
  end
  return blocks
end

return M
