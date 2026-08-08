-- TESTS/hover_spec.lua — :ColorMyAscii hover (info_at_cursor pure data).
---@diagnostic disable: missing-fields, param-type-mismatch

return function(H)
  local ok = H.ok
  local api = vim.api

  require('color_my_ascii.config').setup({})
  local cma = require('color_my_ascii')
  cma.setup({})
  local hover = require('color_my_ascii.commands.hover')

  -- ---- character actually highlighted by color_my_ascii -------------------
  do
    local buf = H.scratch('markdown', {
      '```ascii',
      '+---+',
      '```',
    })
    cma.setup_buffer(buf)
    api.nvim_win_set_cursor(0, { 2, 0 }) -- the '+'

    local lines = hover.info_at_cursor()
    ok(lines ~= nil, 'info_at_cursor returns lines')
    local joined = table.concat(lines, '\n')
    ok(joined:find('Character: "%+"') ~= nil, 'reports the character under the cursor')
    ok(joined:find('Applied highlight: Operator') ~= nil, 'reports the live applied hl_group')
    api.nvim_buf_delete(buf, { force = true })
  end

  -- ---- outside any highlighted region: no applied group, no crash --------
  do
    local buf = H.scratch('markdown', { 'plain paragraph text' })
    cma.setup_buffer(buf)
    api.nvim_win_set_cursor(0, { 1, 3 })

    local lines = hover.info_at_cursor()
    ok(lines ~= nil, 'still returns lines outside any block')
    local joined = table.concat(lines, '\n')
    ok(joined:find('Applied highlight: none') ~= nil, 'reports no applied highlight')
    api.nvim_buf_delete(buf, { force = true })
  end

  -- ---- cursor on a recognized keyword: reports language matches -----------
  do
    local buf = H.scratch('markdown', {
      '```ascii-lua',
      'local x = 1',
      '```',
    })
    cma.setup_buffer(buf)
    api.nvim_win_set_cursor(0, { 2, 0 }) -- "local"

    local lines = hover.info_at_cursor()
    local joined = table.concat(lines, '\n')
    ok(joined:find('Keyword "local"') ~= nil, 'reports the keyword under the cursor')
    ok(joined:find('lua %->') ~= nil, 'reports a language match for the keyword')
    api.nvim_buf_delete(buf, { force = true })
  end

  -- ---- show() copies the same text to the unnamed register ----------------
  do
    local buf = H.scratch('markdown', {
      '```ascii',
      '+---+',
      '```',
    })
    cma.setup_buffer(buf)
    api.nvim_win_set_cursor(0, { 2, 0 })

    vim.fn.setreg('"', '')
    -- kit.note isn't installed in the test env: show() falls back to the
    -- plain nvim_open_win path, which is fine here - only the register copy
    -- is under test.
    hover.show()
    local reg = vim.fn.getreg('"')
    ok(reg:find('Character: "%+"') ~= nil, 'show() copies the info text to the unnamed register')
    api.nvim_buf_delete(buf, { force = true })
  end

  require('color_my_ascii.config').setup({})
end
