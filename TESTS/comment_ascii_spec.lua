-- TESTS/comment_ascii_spec.lua — comment_ascii.find_blocks() + parser dispatch.
---@diagnostic disable: missing-fields

return function(H)
  local eq, ok = H.eq, H.ok
  local api = vim.api
  local comment_ascii = require('color_my_ascii.comment_ascii')

  --- Scratch buffer with an explicit commentstring, bypassing real ftplugins.
  ---@param lines string[]
  ---@param cs string
  ---@return integer bufnr
  local function buf_with_cs(lines, cs)
    local buf = H.scratch(nil, lines)
    vim.bo[buf].commentstring = cs
    return buf
  end

  -- ---- basic block: found, content stripped of the comment prefix ----------
  do
    local buf = buf_with_cs({
      'local function foo()',
      '  -- ascii',
      '  -- +---+',
      '  -- | x |',
      '  -- +---+',
      '  -- /ascii',
      '  return 1',
      'end',
    }, '-- %s')

    local blocks = comment_ascii.find_blocks(buf)
    eq(#blocks, 1, 'one block found')
    local b = blocks[1]
    eq(b.start_line, 1, 'start_line is the marker row (0-indexed)')
    eq(b.end_line, 5, 'end_line is the /ascii row (0-indexed)')
    eq(#b.lines, 3, 'three content lines')
    eq(b.lines[1], '+---+', 'content line 1 stripped of comment prefix')
    eq(b.lines[2], '| x |', 'content line 2 stripped of comment prefix')
    eq(b.lines[3], '+---+', 'content line 3 stripped of comment prefix')
    eq(b.fence_line, 'ascii', 'fence_line carries the trimmed marker text')
    api.nvim_buf_delete(buf, { force = true })
  end

  -- ---- ascii-<lang> marker: forwarded verbatim for language detection -----
  do
    local buf = buf_with_cs({
      '-- ascii-python',
      '-- def f(): pass',
      '-- /ascii',
    }, '-- %s')
    local blocks = comment_ascii.find_blocks(buf)
    eq(#blocks, 1, 'ascii-lang: one block found')
    eq(blocks[1].fence_line, 'ascii-python', 'ascii-lang: fence_line keeps the language suffix')
    api.nvim_buf_delete(buf, { force = true })
  end

  -- ---- unclosed block: not returned (no crash) ------------------------------
  do
    local buf = buf_with_cs({
      '-- ascii',
      '-- +---+',
      'local x = 1', -- non-comment line ends the scan without a close marker
    }, '-- %s')
    local blocks = comment_ascii.find_blocks(buf)
    eq(#blocks, 0, 'unclosed block: nothing returned')
    api.nvim_buf_delete(buf, { force = true })
  end

  -- ---- no commentstring: returns empty, no error ----------------------------
  do
    local buf = buf_with_cs({ '-- ascii', '-- x', '-- /ascii' }, '')
    local ok_run, blocks = pcall(comment_ascii.find_blocks, buf)
    ok(ok_run, 'empty commentstring: does not error')
    eq(#blocks, 0, 'empty commentstring: nothing detected')
    api.nvim_buf_delete(buf, { force = true })
  end

  -- ---- different comment syntax (# for python/bash-style) ------------------
  do
    local buf = buf_with_cs({
      '# ascii',
      '# +--+',
      '# /ascii',
    }, '# %s')
    local blocks = comment_ascii.find_blocks(buf)
    eq(#blocks, 1, 'hash comments: one block found')
    eq(blocks[1].lines[1], '+--+', 'hash comments: content stripped correctly')
    api.nvim_buf_delete(buf, { force = true })
  end

  -- ---- non-marker comments elsewhere are ignored ----------------------------
  do
    local buf = buf_with_cs({
      '-- just a regular comment',
      '-- ascii',
      '-- +--+',
      '-- /ascii',
      '-- another regular comment',
    }, '-- %s')
    local blocks = comment_ascii.find_blocks(buf)
    eq(#blocks, 1, 'only the marked region is detected')
    eq(blocks[1].start_line, 1, 'starts at the actual marker, not line 0')
    api.nvim_buf_delete(buf, { force = true })
  end

  -- ---- parser.find_ascii_blocks dispatches to comment_ascii when enabled ---
  do
    require('color_my_ascii.config').setup({
      comment_ascii = { enable = true, filetypes = { 'lua' } },
    })
    local buf = buf_with_cs({ '-- ascii', '-- +--+', '-- /ascii' }, '-- %s')
    vim.bo[buf].filetype = 'lua'
    local blocks = require('color_my_ascii.parser').find_ascii_blocks(buf)
    eq(#blocks, 1, 'dispatch: parser.find_ascii_blocks finds the comment block')
    api.nvim_buf_delete(buf, { force = true })
  end

  -- ---- disabled by default: parser does not scan comments -------------------
  do
    require('color_my_ascii.config').setup({}) -- comment_ascii.enable defaults false
    local buf = buf_with_cs({ '-- ascii', '-- +--+', '-- /ascii' }, '-- %s')
    vim.bo[buf].filetype = 'lua'
    local blocks = require('color_my_ascii.parser').find_ascii_blocks(buf)
    eq(
      #blocks,
      0,
      'disabled: comment blocks not detected (falls through to markdown scanner, which finds nothing here)'
    )
    api.nvim_buf_delete(buf, { force = true })
  end

  require('color_my_ascii.config').setup({})
end
