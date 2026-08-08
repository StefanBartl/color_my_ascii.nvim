-- TESTS/fence_actions_spec.lua — :Fence yank/lang/import/wrap/unwrap/select/open.
---@diagnostic disable: missing-fields

return function(H)
  local eq, ok = H.eq, H.ok
  local api = vim.api
  require('color_my_ascii.config').setup({})

  local function md_buf()
    return H.scratch('markdown', {
      '# Doc', -- 1
      '', -- 2
      '```javascript', -- 3
      'let a = 0;', -- 4
      'log(a);', -- 5
      '```', -- 6
      'after', -- 7
    })
  end

  -- ---- yank ----------------------------------------------------------------
  do
    local buf = md_buf()
    api.nvim_win_set_cursor(0, { 4, 0 })
    require('color_my_ascii.commands.fence.yank').run({ 'z' })
    eq(vim.fn.getreg('z'), 'let a = 0;\nlog(a);', 'yank: register content (no markers)')
    api.nvim_buf_delete(buf, { force = true })
  end

  -- ---- yank --ansi -----------------------------------------------------------
  do
    local buf = md_buf()
    local cma = require('color_my_ascii')
    cma.setup({})
    cma.setup_buffer(buf)
    api.nvim_win_set_cursor(0, { 4, 0 })
    require('color_my_ascii.commands.fence.yank').run({ 'z', '--ansi' })
    local ESC = string.char(27)
    local reg_text = vim.fn.getreg('z')
    ok(reg_text:find(ESC, 1, true) ~= nil, 'yank --ansi: register holds ANSI escape codes')
    local stripped = reg_text:gsub(ESC .. '%[[%d;]*m', '')
    eq(stripped, 'let a = 0;\nlog(a);', 'yank --ansi: stripped of escapes matches plain content')
    api.nvim_buf_delete(buf, { force = true })
  end

  -- ---- lang ----------------------------------------------------------------
  do
    local buf = md_buf()
    api.nvim_win_set_cursor(0, { 4, 0 })
    require('color_my_ascii.commands.fence.lang').run({ 'typescript' })
    eq(api.nvim_buf_get_lines(buf, 2, 3, false)[1], '```typescript', 'lang: retagged opening fence')
    eq(api.nvim_buf_get_lines(buf, 5, 6, false)[1], '```', 'lang: closing fence untouched')
    api.nvim_buf_delete(buf, { force = true })
  end

  -- ---- import --------------------------------------------------------------
  do
    local buf = md_buf()
    local tmp = vim.fn.tempname() .. '.js'
    vim.fn.writefile({ 'const x = 42;', 'export default x;' }, tmp)
    api.nvim_win_set_cursor(0, { 4, 0 })
    require('color_my_ascii.commands.fence.import').run({ tmp })
    local L = api.nvim_buf_get_lines(buf, 0, -1, false)
    eq(L[4], 'const x = 42;', 'import: interior replaced (line 1)')
    eq(L[5], 'export default x;', 'import: interior replaced (line 2)')
    eq(L[3], '```javascript', 'import: opening fence kept')
    ok(vim.tbl_contains(L, '```'), 'import: closing fence kept')
    vim.fn.delete(tmp)
    api.nvim_buf_delete(buf, { force = true })
  end

  -- ---- wrap (current line) + unwrap ---------------------------------------
  do
    local buf = H.scratch('markdown', { 'plain one', 'plain two' })
    api.nvim_win_set_cursor(0, { 1, 0 })
    require('color_my_ascii.commands.fence.wrap').wrap({ 'lua' }, nil)
    local L = api.nvim_buf_get_lines(buf, 0, -1, false)
    eq(L[1], '```lua', 'wrap: opening fence with lang')
    eq(L[2], 'plain one', 'wrap: content between fences')
    eq(L[3], '```', 'wrap: closing fence')
    -- now unwrap it
    api.nvim_win_set_cursor(0, { 2, 0 })
    require('color_my_ascii.commands.fence.wrap').unwrap({})
    local U = api.nvim_buf_get_lines(buf, 0, -1, false)
    eq(U[1], 'plain one', 'unwrap: content preserved')
    ok(not vim.tbl_contains(U, '```lua'), 'unwrap: fence removed')
    api.nvim_buf_delete(buf, { force = true })
  end

  -- ---- wrap (visual range via ctx) ----------------------------------------
  do
    local buf = H.scratch('markdown', { 'a', 'b', 'c' })
    require('color_my_ascii.commands.fence.wrap').wrap({ '' }, { range = 2, line1 = 1, line2 = 3 })
    local L = api.nvim_buf_get_lines(buf, 0, -1, false)
    eq(L[1], '```', 'wrap range: open before line1')
    eq(L[5], '```', 'wrap range: close after line3')
    eq(L[2], 'a', 'wrap range: content start')
    eq(L[4], 'c', 'wrap range: content end')
    api.nvim_buf_delete(buf, { force = true })
  end

  -- ---- select --------------------------------------------------------------
  do
    local buf = md_buf()
    api.nvim_win_set_cursor(0, { 4, 0 })
    require('color_my_ascii.commands.fence.select').run({})
    eq(api.nvim_win_get_cursor(0)[1], 5, 'select: cursor at last interior line')
    ok(vim.fn.mode():match('[vV]') ~= nil, 'select: in visual mode')
    vim.cmd('normal! \27') -- leave visual mode
    api.nvim_buf_delete(buf, { force = true })
  end

  -- ---- open (edit-in-split + sync back) -----------------------------------
  do
    local buf = md_buf()
    api.nvim_win_set_cursor(0, { 4, 0 })
    local open = require('color_my_ascii.commands.fence.open')
    open.run({ '--split' })
    local tbuf = api.nvim_get_current_buf()
    ok(tbuf ~= buf, 'open: opened a new buffer')
    -- edit the temp buffer and sync back
    api.nvim_buf_set_lines(tbuf, 0, -1, false, { 'let a = 99;', 'log(a);', "log('extra');" })
    open.sync(tbuf)
    local L = api.nvim_buf_get_lines(buf, 0, -1, false)
    eq(L[4], 'let a = 99;', 'open/sync: edit reflected in source')
    ok(vim.tbl_contains(L, "log('extra');"), 'open/sync: added line synced')
    eq(L[3], '```javascript', 'open/sync: fence preserved')
    open.cleanup(tbuf)
    pcall(api.nvim_buf_delete, tbuf, { force = true })
    api.nvim_buf_delete(buf, { force = true })
  end

  -- ---- align (:Fence align wiring; algorithm itself in box_align_spec) -----
  do
    local buf = H.scratch('markdown', {
      '```ascii',
      '┌────┐',
      '│ hi │',
      '│ world  │',
      '└────┘',
      '```',
    })
    api.nvim_win_set_cursor(0, { 3, 0 })
    require('color_my_ascii.commands.fence.align').run({})
    local L = api.nvim_buf_get_lines(buf, 0, -1, false)
    eq(L[2], '┌────────┐', 'align: fence content rewritten in the buffer')
    eq(L[3], '│ hi     │', 'align: interior row padded to match')
    eq(L[6], '```', 'align: closing fence untouched')
    api.nvim_buf_delete(buf, { force = true })
  end

  -- ---- align: no boxes -> no-op, no error -----------------------------------
  do
    local buf = md_buf()
    api.nvim_win_set_cursor(0, { 4, 0 })
    local L_before = api.nvim_buf_get_lines(buf, 0, -1, false)
    local okrun = pcall(require('color_my_ascii.commands.fence.align').run, {})
    ok(okrun, 'align: does not error on a block with no boxes')
    local L_after = api.nvim_buf_get_lines(buf, 0, -1, false)
    eq(table.concat(L_after, '\n'), table.concat(L_before, '\n'), 'align: buffer untouched when nothing to align')
    api.nvim_buf_delete(buf, { force = true })
  end

  require('color_my_ascii.config').setup({})
end
