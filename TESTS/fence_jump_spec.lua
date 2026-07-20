-- docs/TESTS/fence_jump_spec.lua — %-style jump between fence delimiters.
---@diagnostic disable: missing-fields

return function(H)
  local eq, ok = H.eq, H.ok
  local api = vim.api
  local fence_jump = require('color_my_ascii.fence_jump')

  local LINES = {
    '# Title', -- 0
    '', -- 1
    '```text', -- 2  open (non-ascii)
    'plain text', -- 3
    '```', -- 4  close
    '', -- 5
    '```ascii-c', -- 6  open (ascii)
    '+--+', -- 7
    '```', -- 8  close
    '', -- 9  not a fence line
  }

  require('color_my_ascii.config').setup({})

  -- cursor on opening delimiter -> jumps to closing delimiter
  do
    local buf = H.scratch('markdown', LINES)
    local win = api.nvim_get_current_win()
    api.nvim_win_set_cursor(win, { 3, 0 }) -- row 2 (0-idx) = opening ```text
    local handled = fence_jump.jump(buf)
    ok(handled, 'open -> jump handled')
    eq(api.nvim_win_get_cursor(win)[1], 5, 'open -> lands on closing delimiter row')
    api.nvim_buf_delete(buf, { force = true })
  end

  -- cursor on closing delimiter -> jumps back to opening delimiter
  do
    local buf = H.scratch('markdown', LINES)
    local win = api.nvim_get_current_win()
    api.nvim_win_set_cursor(win, { 9, 0 }) -- row 8 (0-idx) = closing ``` of ascii block
    local handled = fence_jump.jump(buf)
    ok(handled, 'close -> jump handled')
    eq(api.nvim_win_get_cursor(win)[1], 7, 'close -> lands on opening delimiter row')
    api.nvim_buf_delete(buf, { force = true })
  end

  -- cursor not on a delimiter line -> not handled, cursor untouched
  do
    local buf = H.scratch('markdown', LINES)
    local win = api.nvim_get_current_win()
    api.nvim_win_set_cursor(win, { 4, 0 }) -- row 3 (0-idx) = content line, not a delimiter
    local handled = fence_jump.jump(buf)
    ok(not handled, 'content line -> not handled')
    eq(api.nvim_win_get_cursor(win)[1], 4, 'content line -> cursor unchanged')
    api.nvim_buf_delete(buf, { force = true })
  end

  -- outside any fence -> not handled
  do
    local buf = H.scratch('markdown', LINES)
    local win = api.nvim_get_current_win()
    api.nvim_win_set_cursor(win, { 1, 0 }) -- row 0 (0-idx) = title, no fence at all
    local handled = fence_jump.jump(buf)
    ok(not handled, 'outside fence -> not handled')
    api.nvim_buf_delete(buf, { force = true })
  end
end
