-- TESTS/highlighter_spec.lua — the four heuristic passes and the treesitter
-- addition on top of them.
--
-- `byte_offsets_spec.lua` pins where the extmarks land; this file pins which
-- ones exist at all: the feature flags that switch a pass off, the precedence
-- between passes, the whole-word rule, and the way a rejected extmark is
-- reported (or deliberately not) rather than raised.

return function(H)
  local eq, ok = H.eq, H.ok
  local config = require('color_my_ascii.config')
  local parser = require('color_my_ascii.parser')
  local highlighter = require('color_my_ascii.highlighter')

  local NS = 'ColorMyAscii'

  ---@param lines string[]
  ---@return { row: integer, col: integer, end_col: integer|nil, hl: string|nil }[] marks
  ---@return integer bufnr
  local function paint(lines)
    local buf = H.scratch('markdown', lines)
    highlighter.clear_buffer(buf)
    for _, block in ipairs(parser.find_ascii_blocks(buf)) do
      highlighter.highlight_block(buf, block)
    end
    return H.marks(buf, NS), buf
  end

  ---@param marks { hl: string|nil }[]
  ---@param hl string
  ---@return integer
  local function count_hl(marks, hl)
    local n = 0
    for _, m in ipairs(marks) do
      if m.hl == hl then
        n = n + 1
      end
    end
    return n
  end

  local NO_TS = { enabled = false, block_detection = false, syntax_highlight = false }

  -- ----------------------------------------------------------- clear_buffer

  config.setup({ default_text_hl = 'Comment', treesitter = NO_TS })
  local marks, buf = paint({ '```ascii', 'abc', '```' })
  ok(#marks > 0, 'a block produces extmarks')
  highlighter.clear_buffer(buf)
  eq(#H.marks(buf, NS), 0, 'clear_buffer removes every mark in the namespace')
  -- Idempotent, and harmless on a buffer it never touched.
  highlighter.clear_buffer(buf)
  eq(#H.marks(buf, NS), 0, 'clearing twice is a no-op')
  vim.api.nvim_buf_delete(buf, { force = true })

  -- --------------------------------------------------- pass 1: default text

  config.setup({ default_text_hl = nil, treesitter = NO_TS })
  marks, buf = paint({ '```ascii', 'abc', '```' })
  eq(count_hl(marks, 'Comment'), 0, 'no default_text_hl means no whole-line mark')
  vim.api.nvim_buf_delete(buf, { force = true })

  -- A custom highlight table is resolved to a generated group name once, at
  -- setup time -- the highlighter only ever sees a string.
  config.setup({ default_text_hl = { fg = '#ff0000', bold = true }, treesitter = NO_TS })
  eq(type(config.get().default_text_hl), 'string', 'a table default_text_hl is resolved to a group name')
  marks, buf = paint({ '```ascii', 'abc', '```' })
  ok(H.has_mark(marks, 1, 0, 3, config.get().default_text_hl), 'and that group is what gets applied')
  vim.api.nvim_buf_delete(buf, { force = true })

  -- ------------------------------------------------------ pass 2: characters

  config.setup({
    default_text_hl = nil,
    overrides = { ['+'] = 'ErrorMsg' },
    enable_bracket_highlighting = true,
    treesitter = NO_TS,
  })
  marks, buf = paint({ '```ascii', '+(x)+', '```' })
  eq(count_hl(marks, 'ErrorMsg'), 2, 'an override applies to every occurrence of the character')
  ok(H.has_mark(marks, 1, 1, 2, 'Operator'), 'the parentheses are painted')
  vim.api.nvim_buf_delete(buf, { force = true })

  -- FINDING: `enable_bracket_highlighting` cannot switch bracket highlighting
  -- off in the shipped configuration. The lookup adds the six brackets in a
  -- step that skips any character a *group* already claims -- and the bundled
  -- `groups/operators.lua` claims all six (its own comment there says they are
  -- "optional, can be controlled by enable_bracket_highlighting"; they are
  -- not). The flag only has an effect once the groups stop covering them.
  config.setup({ default_text_hl = nil, enable_bracket_highlighting = false, treesitter = NO_TS })
  marks, buf = paint({ '```ascii', '(x)', '```' })
  eq(count_hl(marks, 'Operator'), 2, 'FINDING: brackets stay painted with the flag off — groups claimed them')
  vim.api.nvim_buf_delete(buf, { force = true })

  -- With a groups table that does not contain them, the flag behaves as
  -- documented in both positions.
  local bare_groups = { operators = { chars = '+', hl = 'Operator' } }
  config.setup({
    default_text_hl = nil,
    groups = bare_groups,
    enable_bracket_highlighting = false,
    treesitter = NO_TS,
  })
  marks, buf = paint({ '```ascii', '(x)', '```' })
  eq(count_hl(marks, 'Operator'), 0, 'brackets go unpainted once no group claims them')
  vim.api.nvim_buf_delete(buf, { force = true })

  config.setup({
    default_text_hl = nil,
    groups = bare_groups,
    enable_bracket_highlighting = true,
    treesitter = NO_TS,
  })
  marks, buf = paint({ '```ascii', '(x)', '```' })
  eq(count_hl(marks, 'Operator'), 2, 'and are painted again when the flag turns them back on')
  vim.api.nvim_buf_delete(buf, { force = true })

  -- ------------------------------------------------- pass 3: function names

  config.setup({
    default_text_hl = nil,
    enable_function_names = true,
    enable_keywords = false,
    enable_bracket_highlighting = false,
    treesitter = NO_TS,
  })
  marks, buf = paint({ '```ascii', 'zzfn(a) zzfn2 ()', '```' })
  eq(count_hl(marks, 'Function'), 2, 'a name followed by "(" is a function, whitespace allowed between')
  vim.api.nvim_buf_delete(buf, { force = true })

  config.setup({ default_text_hl = nil, enable_function_names = false, treesitter = NO_TS })
  marks, buf = paint({ '```ascii', 'zzfn(a)', '```' })
  eq(count_hl(marks, 'Function'), 0, 'the flag switches the pass off')
  vim.api.nvim_buf_delete(buf, { force = true })

  -- A word that is a known keyword is NOT re-labelled as a function, even when
  -- a "(" follows it -- `if (x)` must stay a keyword.
  config.setup({
    default_text_hl = nil,
    enable_function_names = true,
    enable_keywords = true,
    enable_bracket_highlighting = false,
    languages = { probe = { words = { 'zzkw' }, hl = 'Keyword' } },
    treesitter = NO_TS,
  })
  marks, buf = paint({ '```ascii', 'zzkw(a)', '```' })
  eq(count_hl(marks, 'Function'), 0, 'a keyword followed by "(" is not a function name')
  eq(count_hl(marks, 'Keyword'), 1, 'it stays a keyword')
  vim.api.nvim_buf_delete(buf, { force = true })

  -- ------------------------------------------------------- pass 4: keywords

  config.setup({
    default_text_hl = nil,
    enable_keywords = false,
    languages = { probe = { words = { 'zzkw' }, hl = 'Keyword' } },
    treesitter = NO_TS,
  })
  marks, buf = paint({ '```ascii', 'zzkw', '```' })
  eq(count_hl(marks, 'Keyword'), 0, 'enable_keywords = false empties the keyword lookup entirely')
  vim.api.nvim_buf_delete(buf, { force = true })

  -- The same word in two languages: without a detected language the first
  -- entry wins; with one, the matching language's highlight is used.
  config.setup({
    default_text_hl = nil,
    enable_function_names = false,
    enable_bracket_highlighting = false,
    enable_language_detection = true,
    language_detection_threshold = 1,
    languages = {
      zzalpha = { words = { 'zzshared' }, unique_words = { 'zzonlyalpha' }, hl = 'Keyword' },
      zzbeta = { words = { 'zzshared' }, unique_words = { 'zzonlybeta' }, hl = 'Identifier' },
    },
    treesitter = NO_TS,
  })

  marks, buf = paint({ '```ascii-zzbeta', 'zzshared', '```' })
  eq(count_hl(marks, 'Identifier'), 1, "an explicit ascii-<lang> fence picks that language's highlight")
  eq(count_hl(marks, 'Keyword'), 0, "and not the other language's")
  vim.api.nvim_buf_delete(buf, { force = true })

  -- A word appearing twice is highlighted at both positions; an occurrence
  -- embedded in a longer word is not highlighted at all (whole-word rule, both
  -- boundaries).
  marks, buf = paint({ '```ascii', 'zzshared zzshared xzzsharedx', '```' })
  local spans, total = {}, 0
  for _, m in ipairs(marks) do
    if m.hl == 'Keyword' or m.hl == 'Identifier' then
      spans[('%d-%d'):format(m.col, m.end_col)] = true
      total = total + 1
    end
  end
  ok(spans['0-8'] and spans['9-17'], 'both whole-word occurrences are highlighted')
  ok(not spans['19-27'], 'the occurrence inside xzzsharedx is not')
  eq(vim.tbl_count(spans), 2, 'and nothing else is')
  -- Noted, not a defect: `tokenize_line` does not deduplicate, so a keyword
  -- occurring N times is scanned N times and each position ends up with N
  -- stacked extmarks. Visually identical, quadratic in a repetitive line.
  eq(total, 4, 'each of the two positions carries one mark per occurrence of the token')
  vim.api.nvim_buf_delete(buf, { force = true })

  -- -------------------------------------------------- rejected extmarks
  --
  -- `safe_api.set_extmark` validates the requested columns against the line
  -- content the caller passes. A block whose recorded content is longer than
  -- the buffer line it points at (a stale cache entry is exactly that) is
  -- therefore refused, not raised -- and reported only in debug mode.

  config.setup({ default_text_hl = 'Comment', debug_enabled = false, treesitter = NO_TS })
  local stale_buf = H.scratch('markdown', { '```ascii', 'ab', '```' })
  ---@type ColorMyAscii.Block
  local stale = { start_line = 0, end_line = 2, lines = { 'a much longer line than the buffer has' }, fence_line = '' }

  ok(pcall(highlighter.highlight_block, stale_buf, stale), 'an out-of-range range is refused, not raised')

  -- `highlighter.lua` binds `local notify = vim.notify` at load time, so a
  -- later swap of `vim.notify` would never be seen: the module has to be
  -- re-required while the capture is installed. Same seam rule as everywhere
  -- else in this suite -- replace the dependency before the require.
  local quiet = H.reload_notify({ 'color_my_ascii.highlighter' }, function(mods)
    mods['color_my_ascii.highlighter'].highlight_block(stale_buf, stale)
  end)
  eq(#quiet, 0, 'and stays quiet outside debug mode')

  config.setup({ default_text_hl = 'Comment', debug_enabled = true, treesitter = NO_TS })
  local loud = H.reload_notify({ 'color_my_ascii.highlighter' }, function(mods)
    mods['color_my_ascii.highlighter'].highlight_block(stale_buf, stale)
  end)
  ok(H.notified(loud, 'Failed to set extmark'), 'debug mode reports the refusal')
  vim.api.nvim_buf_delete(stale_buf, { force = true })

  -- ------------------------------------------------------------ inline code

  config.setup({
    default_text_hl = nil,
    debug_enabled = false,
    enable_inline_code = true,
    enable_keywords = true,
    enable_function_names = true,
    enable_bracket_highlighting = false,
    languages = { probe = { words = { 'zzkw' }, hl = 'Keyword' } },
    treesitter = NO_TS,
  })

  local inline_buf = H.scratch('markdown', { 'text `zzkw` and `zzfn()` here' })
  highlighter.clear_buffer(inline_buf)
  highlighter.highlight_inline_codes(inline_buf)
  local inline_marks = H.marks(inline_buf, NS)
  eq(count_hl(inline_marks, 'Keyword'), 1, 'keywords are highlighted inside inline code')
  eq(count_hl(inline_marks, 'Function'), 1, 'and so are function names')
  vim.api.nvim_buf_delete(inline_buf, { force = true })

  config.setup({ enable_inline_code = false, treesitter = NO_TS })
  local off_buf = H.scratch('markdown', { 'text `zzkw` here' })
  highlighter.clear_buffer(off_buf)
  highlighter.highlight_inline_codes(off_buf)
  eq(#H.marks(off_buf, NS), 0, 'the feature flag switches inline highlighting off')
  vim.api.nvim_buf_delete(off_buf, { force = true })

  -- --------------------------------------------------- treesitter addition
  --
  -- Best-effort and additive: an unmapped language, an empty block or a
  -- missing grammar all answer `false` without touching the buffer. The lua
  -- grammar ships with Neovim, so the success path is real rather than mocked.

  local hl_ts = require('color_my_ascii.highlighter_ts')
  local ts_ns = vim.api.nvim_create_namespace('ColorMyAsciiTestTs')
  local ts_buf = H.scratch('markdown', { '```ascii-lua', 'local x = 1', '```' })
  ---@type ColorMyAscii.Block
  local ts_block = { start_line = 0, end_line = 2, lines = { 'local x = 1' }, fence_line = '```ascii-lua' }

  eq(hl_ts.highlight_block(ts_buf, ts_block, nil, ts_ns), false, 'no detected language -> no treesitter pass')
  eq(hl_ts.highlight_block(ts_buf, ts_block, 'llvm', ts_ns), false, 'a language with no grammar mapping -> false')
  eq(
    hl_ts.highlight_block(ts_buf, { start_line = 0, end_line = 1, lines = {}, fence_line = '' }, 'lua', ts_ns),
    false,
    'an empty block -> false'
  )

  if pcall(vim.treesitter.language.add, 'lua') then
    eq(hl_ts.highlight_block(ts_buf, ts_block, 'lua', ts_ns), true, 'the lua grammar produces a real pass')
    local ts_marks = H.marks(ts_buf, 'ColorMyAsciiTestTs')
    ok(#ts_marks > 0, 'and writes capture extmarks')
    local captured = false
    for _, m in ipairs(ts_marks) do
      if type(m.hl) == 'string' and m.hl:sub(1, 1) == '@' then
        captured = true
      end
      eq(m.row, 1, "every capture lands on the block's single content row")
    end
    ok(captured, 'the highlight groups are treesitter capture names')
  end
  vim.api.nvim_buf_delete(ts_buf, { force = true })

  config.setup({})
end
