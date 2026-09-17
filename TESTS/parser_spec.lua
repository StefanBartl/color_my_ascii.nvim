-- TESTS/parser_spec.lua — fence classification, the generic block scanner and
-- the dispatcher that chooses a backend.
--
-- `fences_spec.lua` covers the public API on top of this; what is pinned here
-- is the scanner itself: which fences open a block, which close it, which are
-- content, and what the dispatcher does when the treesitter backend is
-- unavailable or raises. The heuristic scanner is the fallback that has to
-- always produce a result, so its edge cases are the ones nobody sees fail.

return function(H)
  local eq, ok = H.eq, H.ok
  local config = require('color_my_ascii.config')
  local parser = require('color_my_ascii.parser')

  --- Run the heuristic scanner only, regardless of the treesitter defaults.
  ---@param lines string[]
  ---@param opts? { lines?: "none"|"ascii"|"all" }
  ---@return ColorMyAscii.FenceBlock[]
  local function scan(lines, opts)
    local buf = H.scratch('markdown', lines)
    local blocks = parser.scan_blocks_heuristic(buf, opts)
    vim.api.nvim_buf_delete(buf, { force = true })
    return blocks
  end

  -- ------------------------------------------------------ is_ascii_fence

  config.setup({ treat_empty_fence_as_ascii = true })
  ok(parser.is_ascii_fence('ascii'), 'a bare ascii tag is an ASCII fence')
  ok(parser.is_ascii_fence('ascii-c'), 'so is ascii-<lang>')
  ok(parser.is_ascii_fence(''), 'and an empty tag, while treat_empty_fence_as_ascii holds')
  ok(parser.is_ascii_fence('lua'), 'a tag in fence_language_map counts too')
  ok(not parser.is_ascii_fence('nosuchlang'), 'an unmapped tag does not')

  config.setup({ treat_empty_fence_as_ascii = false })
  ok(not parser.is_ascii_fence(''), 'an empty tag stops counting once the flag is off')
  ok(parser.is_ascii_fence('ascii'), 'the explicit marker is unaffected by the flag')

  -- The map is a merge target: a user entry extends it. (It cannot be emptied
  -- through `setup()` -- the merge is a deep extend and an empty table removes
  -- nothing.)
  config.setup({ fence_language_map = { zzcustomtag = 'lua' } })
  ok(parser.is_ascii_fence('zzcustomtag'), 'a user-added map entry makes that tag ASCII')

  config.setup({})

  -- -------------------------------------------------- scan_blocks_heuristic

  local blocks = scan({
    'intro', -- 0
    '```lua', -- 1
    'local x = 1', -- 2
    '```', -- 3
    '', -- 4
    '~~~~ascii', -- 5
    '+--+', -- 6
    '~~~~~', -- 7
  })

  eq(#blocks, 2, 'both fenced blocks are found')
  eq(blocks[1].open_row, 1, 'open_row is 0-indexed')
  eq(blocks[1].close_row, 3, 'close_row is the closing delimiter row')
  eq(blocks[1].content_start, 2, 'content_start is the first interior row')
  eq(blocks[1].content_end, 3, 'content_end is exclusive and equals close_row')
  eq(blocks[1].lang, 'lua', 'the language tag is trimmed off the fence line')
  eq(blocks[1].fence_char, '`', 'backtick fences report their delimiter character')
  eq(blocks[1].fence_len, 3, 'and its length')
  eq(blocks[1].start_line, 1, 'the ColorMyAscii.Block alias start_line is kept')
  eq(blocks[1].end_line, 3, 'and end_line too')
  ok(blocks[1].is_ascii, 'a lua fence is ASCII via fence_language_map')

  eq(blocks[2].fence_char, '~', 'tilde fences are recognised')
  eq(blocks[2].fence_len, 4, 'with their own length')
  ok(blocks[2].is_ascii, 'the ascii tag classifies the tilde block')

  -- A closing fence has to be at least as long as the opening one; a shorter
  -- run of delimiters is content, so the block stays open.
  eq(#scan({ '````ascii', 'x', '```', 'y', '````' }), 1, 'a too-short fence does not close the block')
  eq(scan({ '````ascii', 'x', '```', 'y', '````' })[1].close_row, 4, 'the long fence is what closes it')

  -- An unclosed block is not reported at all (no half-open block escapes).
  eq(#scan({ '```ascii', 'x' }), 0, 'a block still open at EOF is dropped')

  -- The closing fence of a NON-ascii block must not be mistaken for the
  -- opening fence of the next one -- the whole reason the scanner tracks every
  -- block rather than only the ASCII ones.
  local mixed = scan({ '```plaintext', '{}', '```', '```ascii', '+-+', '```' })
  eq(#mixed, 2, 'a non-ascii block does not desynchronise the scanner')
  eq(mixed[2].lang, 'ascii', 'the second block is the ascii one')

  -- Indented fences are still fences.
  local indented = scan({ '  ```ascii', '  +-+', '  ```' })
  eq(#indented, 1, 'an indented fence opens a block')
  eq(indented[1].fence_line, '  ```ascii', 'the raw fence line is kept, indentation included')

  -- --------------------------------------------------------- content lines

  local none = scan({ '```ascii', 'a', '```', '```plaintext', 'b', '```' })
  ok(none[1].lines == nil and none[2].lines == nil, 'lines = "none" is the default and collects nothing')

  local ascii_only = scan({ '```ascii', 'a', '```', '```plaintext', 'b', '```' }, { lines = 'ascii' })
  eq(ascii_only[1].lines[1], 'a', 'lines = "ascii" collects the ASCII block')
  ok(ascii_only[2].lines == nil, 'and leaves the plaintext block alone')

  local all = scan({ '```ascii', 'a', '```', '```plaintext', 'b', '```' }, { lines = 'all' })
  eq(all[2].lines[1], 'b', 'lines = "all" collects every block')

  eq(#scan({ '```ascii', '```' }, { lines = 'all' })[1].lines, 0, 'an empty block collects an empty list')

  -- ---------------------------------------------- find_ascii_blocks_heuristic

  local ascii_blocks
  do
    local buf = H.scratch('markdown', { '```plaintext', '{}', '```', '```ascii-lua', 'local', '```' })
    ascii_blocks = parser.find_ascii_blocks_heuristic(buf)
    vim.api.nvim_buf_delete(buf, { force = true })
  end
  eq(#ascii_blocks, 1, 'the ASCII filter drops the plaintext block')
  eq(ascii_blocks[1].lang, 'ascii-lua', 'and keeps the ascii one, with content')
  eq(ascii_blocks[1].lines[1], 'local', 'content is collected for it')

  -- ------------------------------------------------- dispatch: comment_ascii
  --
  -- A buffer whose filetype is in comment_ascii.filetypes goes to the marker
  -- scanner instead of markdown fence detection -- and inline `code` spans,
  -- being a prose concept, are skipped entirely for it.

  config.setup({ comment_ascii = { enable = true, filetypes = { 'lua' } } })
  local ca_buf = H.scratch('lua', { '-- ascii', '-- +-+', '-- /ascii', 'local s = `x`' })
  vim.bo[ca_buf].commentstring = '-- %s'
  local ca_blocks = parser.find_ascii_blocks(ca_buf)
  eq(#ca_blocks, 1, 'the comment marker scanner runs for a configured filetype')
  eq(ca_blocks[1].lines[1], '+-+', 'and returns prefix-stripped content')
  eq(#parser.find_inline_codes(ca_buf), 0, 'inline code is skipped for comment_ascii buffers')
  vim.api.nvim_buf_delete(ca_buf, { force = true })

  -- A filetype outside the list falls back to fence detection even with the
  -- feature enabled.
  local md_buf = H.scratch('markdown', { '-- ascii', '-- +-+', '-- /ascii' })
  eq(#parser.find_ascii_blocks(md_buf), 0, 'markdown buffers ignore comment markers')
  vim.api.nvim_buf_delete(md_buf, { force = true })
  config.setup({})

  -- ------------------------------------------------- dispatch: treesitter
  --
  -- The treesitter backend is optional in two different ways: its parser may
  -- not be installed at all, and a call into it may raise. Both must land on
  -- the heuristic scanner rather than on "this buffer has no fences" -- so the
  -- backend is replaced in `package.loaded` before the dispatcher requires it.

  local LINES = { '```ascii', '+-+', '```' }

  local unavailable = {
    markdown_available = function()
      return false
    end,
    find_ascii_blocks = function()
      error('must not be called')
    end,
    scan_blocks_ts = function()
      error('must not be called')
    end,
  }

  H.with_modules({ ['color_my_ascii.parser_ts'] = unavailable }, function()
    config.setup({ treesitter = { enabled = true, block_detection = true } })
    local buf = H.scratch('markdown', LINES)
    eq(#parser.find_ascii_blocks(buf), 1, 'no markdown parser -> heuristic scanner')
    eq(#parser.find_all_blocks(buf), 1, 'and the generic scan takes the same route')
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  local raising = {
    markdown_available = function()
      return true
    end,
    find_ascii_blocks = function()
      error('synthetic treesitter failure')
    end,
    scan_blocks_ts = function()
      error('synthetic treesitter failure')
    end,
  }

  H.with_modules({ ['color_my_ascii.parser_ts'] = raising }, function()
    config.setup({ treesitter = { enabled = true, block_detection = true }, debug_enabled = false })
    local buf = H.scratch('markdown', LINES)
    eq(#parser.find_ascii_blocks(buf), 1, 'a raising treesitter backend falls back silently')
    eq(#parser.find_all_blocks(buf), 1, 'for the generic scan as well')

    -- With debug_enabled the same failure is reported instead of swallowed.
    config.setup({ treesitter = { enabled = true, block_detection = true }, debug_enabled = true })
    local seen = H.capture_notify(function()
      parser.find_ascii_blocks(buf)
      parser.find_all_blocks(buf)
    end)
    ok(H.notified(seen, 'falling back to heuristic parser'), 'debug mode reports the fallback')
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  config.setup({ treesitter = { enabled = false, block_detection = false } })
  do
    local buf = H.scratch('markdown', LINES)
    eq(#parser.find_ascii_blocks(buf), 1, 'treesitter switched off entirely still finds the block')
    vim.api.nvim_buf_delete(buf, { force = true })
  end
  config.setup({})

  -- ---------------------------------------------------------- tokenize_line

  local tokens = parser.tokenize_line('local my_var = a ~= b and c')
  ok(vim.tbl_contains(tokens, 'local'), 'words are tokens')
  ok(vim.tbl_contains(tokens, 'my_var'), 'underscores stay inside a token')
  ok(not vim.tbl_contains(tokens, 'my'), 'and do not split it')

  local ops = parser.tokenize_line('a := b <= c && d')
  ok(vim.tbl_contains(ops, ':='), 'multi-character operators are added explicitly')
  ok(vim.tbl_contains(ops, '<='), 'including comparison operators')
  ok(vim.tbl_contains(ops, '&&'), 'and logical ones')
  eq(#parser.tokenize_line(''), 0, 'an empty line has no tokens')

  -- -------------------------------------------------------- find_inline_codes

  config.setup({ enable_inline_code = true })
  local inline_buf = H.scratch('markdown', { 'a `one` b `two` c', 'no backticks here', 'unclosed `tail' })
  local inline = parser.find_inline_codes(inline_buf)
  eq(#inline, 2, 'both spans on the first line are found')
  eq(inline[1].content, 'one', 'first span content')
  eq(inline[2].content, 'two', 'second span content')
  eq(inline[1].line, 0, 'rows are 0-indexed')
  ok(inline[1].end_col > inline[1].start_col, 'a span has a positive width')

  eq(#parser.find_inline_codes(H.scratch('markdown', { 'a `` b' })), 0, 'an empty span is not reported')

  config.setup({ enable_inline_code = false })
  eq(#parser.find_inline_codes(inline_buf), 0, 'the feature flag turns detection off wholesale')
  vim.api.nvim_buf_delete(inline_buf, { force = true })

  config.setup({})
end
