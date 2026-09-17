-- TESTS/byte_offsets_spec.lua — highlight positions in multibyte text.
--
-- Extmark columns are BYTE offsets. Every position this plugin computes is
-- derived from Lua string arithmetic (`#char`, `string.find`, `%s*(.*)$`),
-- which is byte-based too -- so the failure mode here is never a crash, it is
-- a highlight that lands three columns to the left, or an extmark that splits
-- a codepoint. These checks therefore assert the RESULTING extmark positions
-- against hand-counted byte offsets, not that a call returned true.
--
-- The content is real: umlauts (2 bytes), arrows/box-drawing (3), CJK (3) and
-- an emoji (4), so a char-vs-byte confusion cannot pass by accident the way it
-- can with a single 2-byte character.

return function(H)
  local eq, ok = H.eq, H.ok
  local config = require('color_my_ascii.config')
  local parser = require('color_my_ascii.parser')
  local highlighter = require('color_my_ascii.highlighter')

  local NS = 'ColorMyAscii'

  --- Highlight every ASCII block of a fresh markdown buffer and return its marks.
  ---@param lines string[]
  ---@return { row: integer, col: integer, end_col: integer|nil, hl: string|nil }[] marks
  ---@return integer bufnr
  local function highlight_markdown(lines)
    local buf = H.scratch('markdown', lines)
    highlighter.clear_buffer(buf)
    for _, block in ipairs(parser.find_ascii_blocks(buf)) do
      highlighter.highlight_block(buf, block)
    end
    return H.marks(buf, NS), buf
  end

  -- ------------------------------------------------- per-character positions
  --
  -- "äöü→ß": 2+2+2+3+2 = 11 bytes, 5 characters. A character-indexed
  -- implementation would put the override for "ß" at 4..5 instead of 9..11.

  config.setup({
    default_text_hl = 'Comment',
    overrides = { ['→'] = 'Todo', ['ß'] = 'Special' },
    enable_keywords = false,
    enable_function_names = false,
    treesitter = { enabled = false, block_detection = false, syntax_highlight = false },
  })

  local marks, buf = highlight_markdown({ '```ascii', 'äöü→ß', '```' })
  eq(#'äöü→ß', 11, 'fixture really is 11 bytes wide')
  ok(H.has_mark(marks, 1, 0, 11, 'Comment'), 'default_text_hl spans the line in bytes, not characters')
  ok(H.has_mark(marks, 1, 6, 9, 'Todo'), 'the 3-byte arrow sits at bytes 6..9')
  ok(H.has_mark(marks, 1, 9, 11, 'Special'), 'the trailing sharp-s sits at bytes 9..11')
  for _, m in ipairs(marks) do
    ok(m.col ~= 1 and m.col ~= 3 and m.col ~= 5, 'no extmark starts in the middle of a codepoint')
  end
  vim.api.nvim_buf_delete(buf, { force = true })

  -- ------------------------------------------------------------ CJK + emoji
  --
  -- "漢字🎯ok": 3+3+4+1+1 = 12 bytes for 5 characters.

  config.setup({
    default_text_hl = 'Comment',
    overrides = { ['🎯'] = 'Special' },
    enable_keywords = false,
    enable_function_names = false,
    treesitter = { enabled = false, block_detection = false, syntax_highlight = false },
  })

  marks, buf = highlight_markdown({ '```ascii', '漢字🎯ok', '```' })
  eq(#'漢字🎯ok', 12, 'fixture really is 12 bytes wide')
  ok(H.has_mark(marks, 1, 0, 12, 'Comment'), 'default_text_hl covers all 12 bytes')
  ok(H.has_mark(marks, 1, 6, 10, 'Special'), 'the 4-byte emoji sits at bytes 6..10')
  vim.api.nvim_buf_delete(buf, { force = true })

  -- ------------------------------------- keywords behind a multibyte prefix
  --
  -- A keyword is located with a plain `string.find`, so its match index is a
  -- byte index; what this pins is that nothing re-measures it in characters on
  -- the way to the extmark.

  config.setup({
    default_text_hl = nil,
    languages = { probe = { words = { 'ZETA' }, hl = 'Keyword' } },
    enable_function_names = false,
    enable_bracket_highlighting = false,
    treesitter = { enabled = false, block_detection = false, syntax_highlight = false },
  })

  marks, buf = highlight_markdown({ '```ascii', 'äöü ZETA', '```' })
  ok(H.has_mark(marks, 1, 7, 11, 'Keyword'), 'keyword after three umlauts starts at byte 7, not character 4')
  vim.api.nvim_buf_delete(buf, { force = true })

  -- A keyword must still be a whole word: "ZETAX" is not one.
  marks, buf = highlight_markdown({ '```ascii', 'äöü ZETAX', '```' })
  ok(not H.has_mark(marks, 1, 7, 11, 'Keyword'), 'ZETAX is not a whole-word match')
  vim.api.nvim_buf_delete(buf, { force = true })

  -- ------------------------------- function names behind a multibyte prefix

  config.setup({
    default_text_hl = nil,
    enable_keywords = false,
    enable_bracket_highlighting = false,
    treesitter = { enabled = false, block_detection = false, syntax_highlight = false },
  })

  marks, buf = highlight_markdown({ '```ascii', 'äöü zzfn()', '```' })
  ok(H.has_mark(marks, 1, 7, 11, 'Function'), 'function name after three umlauts spans bytes 7..11')
  vim.api.nvim_buf_delete(buf, { force = true })

  -- ------------------------------------------------ inline code, multibyte
  --
  -- `find_inline_codes` reports byte columns straight from `string.find`, and
  -- `highlight_inline_codes` offsets into the *content* string relative to
  -- them. Both halves have to agree in bytes or the span drifts.

  config.setup({
    default_text_hl = 'Comment',
    overrides = { ['→'] = 'Todo' },
    enable_keywords = false,
    enable_function_names = false,
    enable_inline_code = true,
    treesitter = { enabled = false, block_detection = false, syntax_highlight = false },
  })

  local inline_buf = H.scratch('markdown', { 'äöü `→x` tail' })
  local inline = parser.find_inline_codes(inline_buf)
  eq(#inline, 1, 'one inline code span')
  eq(inline[1].start_col, 7, 'opening backtick sits at byte 7')
  eq(inline[1].end_col, 13, 'end_col is the byte past the closing backtick')
  eq(inline[1].content, '→x', 'content is the span between the backticks')

  highlighter.clear_buffer(inline_buf)
  highlighter.highlight_inline_codes(inline_buf)
  local inline_marks = H.marks(inline_buf, NS)
  ok(H.has_mark(inline_marks, 0, 8, 11, 'Todo'), 'the arrow inside the inline span sits at bytes 8..11')
  -- Documented asymmetry rather than a defect: the default-text span starts
  -- after the opening backtick but ends past the closing one (`end_col` is the
  -- closing delimiter's own byte range end, not the content's).
  ok(H.has_mark(inline_marks, 0, 8, 13, 'Comment'), 'default_text_hl covers content plus the closing backtick')
  vim.api.nvim_buf_delete(inline_buf, { force = true })

  -- ------------------------------------------------------------------- BUG
  --
  -- `parser.get_byte_offset` is the module's own character-column -> byte-offset
  -- converter, and it cannot convert anything: `vim.str_utf_pos` answers with a
  -- TABLE of byte positions, and the function drives it as a generic-for
  -- iterator ("attempt to call a table value"). Only `col == 0` survives, via
  -- the early return above the loop. Nothing in the plugin calls it today --
  -- which is the only reason this has never been seen -- but it is a public,
  -- documented function on a module other code requires.

  eq(parser.get_byte_offset('äbc', 0), 0, 'get_byte_offset(0) short-circuits before the loop')
  local conv_ok, conv_err = pcall(parser.get_byte_offset, 'äbc', 1)
  ok(not conv_ok, 'BUG: get_byte_offset raises for every column > 0')
  ok(
    tostring(conv_err):find('attempt to call a table value', 1, true) ~= nil,
    'BUG: because vim.str_utf_pos returns a table, not an iterator'
  )
  eq(type(vim.str_utf_pos('äbc')), 'table', 'vim.str_utf_pos really is a table')

  -- ------------------------------------------------------------------- BUG
  --
  -- comment_ascii strips the buffer's comment prefix from every content line
  -- before handing the block to the highlighter -- but the highlighter uses
  -- those stripped strings both as the text to scan AND as the coordinate
  -- system for the extmark it writes into the *unstripped* buffer line. Every
  -- highlight inside a `-- ascii` block therefore lands #prefix+1 bytes too far
  -- left: below, the arrow is at byte 9 of the real line but is painted at 6.

  config.setup({
    default_text_hl = 'Comment',
    overrides = { ['→'] = 'Todo' },
    comment_ascii = { enable = true, filetypes = { 'lua' } },
    enable_keywords = false,
    enable_function_names = false,
    treesitter = { enabled = false, block_detection = false, syntax_highlight = false },
  })

  local ca_buf = H.scratch('lua', { '-- ascii', '-- ┌─→┐', '-- /ascii' })
  vim.bo[ca_buf].commentstring = '-- %s'

  local ca_blocks = parser.find_ascii_blocks(ca_buf)
  eq(#ca_blocks, 1, 'the comment_ascii scanner finds the marked block')
  eq(ca_blocks[1].lines[1], '┌─→┐', 'and hands the highlighter the prefix-stripped text')

  local real_line = vim.api.nvim_buf_get_lines(ca_buf, 1, 2, false)[1]
  eq(real_line:find('→', 1, true) - 1, 9, 'the arrow really sits at byte 9 of the buffer line')

  highlighter.clear_buffer(ca_buf)
  highlighter.highlight_block(ca_buf, ca_blocks[1])
  local ca_marks = H.marks(ca_buf, NS)
  ok(H.has_mark(ca_marks, 1, 6, 9, 'Todo'), 'BUG: the arrow is highlighted at bytes 6..9 (the "- ┌" run)')
  ok(not H.has_mark(ca_marks, 1, 9, 12, 'Todo'), 'BUG: and not at bytes 9..12 where it actually is')
  ok(H.has_mark(ca_marks, 1, 0, 12, 'Comment'), 'BUG: the default text span starts on the comment prefix too')
  eq(#real_line, 15, 'BUG: and stops 3 bytes short of the line it is supposed to cover')

  vim.api.nvim_buf_delete(ca_buf, { force = true })

  config.setup({})
end
