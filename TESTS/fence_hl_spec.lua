-- docs/TESTS/fence_hl_spec.lua — fence delimiter line highlighting.
---@diagnostic disable: missing-fields

return function(H)
  local eq, ok = H.eq, H.ok
  local api = vim.api
  local fence_hl = require('color_my_ascii.fence_hl')

  local LINES = {
    '# Title', -- 0
    '', -- 1
    '```text', -- 2  non-ascii (unmapped lang)
    'plain text', -- 3
    '```', -- 4
    '', -- 5
    '```ascii-c', -- 6  ascii
    '+--+', -- 7
    '```', -- 8
  }

  local ns = api.nvim_create_namespace('ColorMyAsciiFenceLine')
  local function rows(buf)
    local set = {}
    for _, m in ipairs(api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })) do
      set[m[2]] = m[4].line_hl_group or m[4].hl_group or set[m[2]] or true
    end
    return set
  end

  -- apply_to = "all"
  require('color_my_ascii.config').setup({
    fence_line_highlight = { enable = true, preset = 'accent', apply_to = 'all' },
    fence_content_highlight = { enable = false }, -- isolate line-highlight behavior from the default-on content highlight
  })
  fence_hl.setup_hl(require('color_my_ascii.config').get())
  do
    local buf = H.scratch('markdown', LINES)
    fence_hl.apply(buf, require('color_my_ascii.config').get())
    local r = rows(buf)
    ok(r[2] ~= nil and r[4] ~= nil, 'all: text fence open+close highlighted')
    ok(r[6] ~= nil and r[8] ~= nil, 'all: ascii fence open+close highlighted')
    ok(r[3] == nil, 'all: content line not highlighted')
    eq(r[2], 'ColorMyAsciiFenceOpen', 'all: open uses open group')
    eq(r[4], 'ColorMyAsciiFenceClose', 'all: close uses close group')
    api.nvim_buf_delete(buf, { force = true })
  end

  -- apply_to = "ascii"
  require('color_my_ascii.config').setup({
    fence_line_highlight = { enable = true, preset = 'subtle', apply_to = 'ascii' },
    fence_content_highlight = { enable = false },
  })
  fence_hl.setup_hl(require('color_my_ascii.config').get())
  do
    local buf = H.scratch('markdown', LINES)
    fence_hl.apply(buf, require('color_my_ascii.config').get())
    local r = rows(buf)
    ok(r[2] == nil, 'ascii: non-ascii text fence not highlighted')
    ok(r[6] ~= nil and r[8] ~= nil, 'ascii: ascii fence highlighted')
    api.nvim_buf_delete(buf, { force = true })
  end

  -- disabled -> clears
  do
    local buf = H.scratch('markdown', LINES)
    fence_hl.apply(buf, { fence_line_highlight = { enable = true, apply_to = 'all' } })
    ok(next(rows(buf)) ~= nil, 'marks present before disable')
    fence_hl.apply(buf, { fence_line_highlight = { enable = false } })
    ok(next(rows(buf)) == nil, 'marks cleared when disabled')
    api.nvim_buf_delete(buf, { force = true })
  end

  -- overrides: string group + attr table
  require('color_my_ascii.config').setup({
    fence_line_highlight = { enable = true, open = 'Comment', close = { bg = '#331111' }, apply_to = 'all' },
  })
  fence_hl.setup_hl(require('color_my_ascii.config').get())
  do
    local close_hl = api.nvim_get_hl(0, { name = 'ColorMyAsciiFenceClose' })
    ok(close_hl.bg ~= nil, 'override: close group has custom bg')
  end

  -- preset = a theme name -> uses that theme's hand-tuned palette
  require('color_my_ascii.config').setup({
    fence_line_highlight = { enable = true, preset = 'catppuccin', apply_to = 'all' },
  })
  fence_hl.setup_hl(require('color_my_ascii.config').get())
  do
    local themes = require('color_my_ascii.theme_presets')
    local open_hl = api.nvim_get_hl(0, { name = 'ColorMyAsciiFenceOpen' })
    eq(string.format('#%06x', open_hl.bg), themes.presets.catppuccin.bg, 'theme preset applies catppuccin bg')
  end

  -- preset = "auto" -> matches the current colorscheme name by substring
  do
    local themes = require('color_my_ascii.theme_presets')
    local saved_name, saved_bg = vim.g.colors_name, vim.o.background
    vim.g.colors_name = 'tokyonight-storm'
    vim.o.background = 'dark'
    require('color_my_ascii.config').setup({
      fence_line_highlight = { enable = true, preset = 'auto', apply_to = 'all' },
    })
    fence_hl.setup_hl(require('color_my_ascii.config').get())
    local open_hl = api.nvim_get_hl(0, { name = 'ColorMyAsciiFenceOpen' })
    eq(string.format('#%06x', open_hl.bg), themes.presets.tokyonight.bg, 'auto matches tokyonight variant')

    -- auto with an unknown theme -> falls back to the generic 'subtle' link
    vim.g.colors_name = 'some-unknown-theme-xyz'
    fence_hl.setup_hl(require('color_my_ascii.config').get())
    local fallback = api.nvim_get_hl(0, { name = 'ColorMyAsciiFenceOpen', link = true })
    ok(fallback.link == 'CursorLine', 'auto falls back to subtle (CursorLine) on no match')

    vim.g.colors_name = saved_name
    vim.o.background = saved_bg
  end

  -- respect_indent: indented block -> highlight starts at the block's own indent
  -- column (not column 0) and runs to the window edge via hl_eol; a blank
  -- interior row masks the would-be indent back to Normal so the left edge
  -- stays aligned with the opening fence.
  do
    local INDENT = {
      '- item', -- 0
      '  ```lua', -- 1  indent 2
      '  x = 1', -- 2
      '', -- 3  blank interior row
      '  ```', -- 4
    }
    require('color_my_ascii.config').setup({
      fence_line_highlight = { enable = true, preset = 'accent', apply_to = 'all' },
      fence_content_highlight = { enable = true, apply_to = 'all' },
    })
    fence_hl.setup_hl(require('color_my_ascii.config').get())
    local buf = H.scratch('markdown', INDENT)
    fence_hl.apply(buf, require('color_my_ascii.config').get())
    local marks = api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })
    local by_row = {}
    for _, m in ipairs(marks) do
      by_row[m[2]] = by_row[m[2]] or {}
      table.insert(by_row[m[2]], m)
    end
    local open_hl
    for _, m in ipairs(by_row[1] or {}) do
      if m[4].hl_group == 'ColorMyAsciiFenceOpen' then
        open_hl = m
      end
    end
    ok(open_hl ~= nil, 'respect_indent: open line painted with a bounded hl_group range (not line_hl_group)')
    eq(open_hl[3], 2, 'respect_indent: highlight starts at the 2-col indent')
    ok(open_hl[4].hl_eol == true, 'respect_indent: highlight runs to the window edge (hl_eol)')
    ok(open_hl[4].line_hl_group == nil, 'respect_indent: no full-line line_hl_group')

    local blank_mask
    for _, m in ipairs(by_row[3] or {}) do
      if m[4].virt_text ~= nil then
        blank_mask = m
      end
    end
    ok(blank_mask ~= nil, 'respect_indent: blank interior row gets an indent mask')
    eq(blank_mask[4].virt_text_win_col, 0, 'respect_indent: mask pinned at column 0')
    eq(blank_mask[4].virt_text[1][1], '  ', 'respect_indent: mask covers the 2-col indent')
    api.nvim_buf_delete(buf, { force = true })
  end

  -- respect_indent = false -> classic full-line line_hl_group
  do
    require('color_my_ascii.config').setup({
      fence_line_highlight = { enable = true, respect_indent = false, apply_to = 'all' },
      fence_content_highlight = { enable = false },
    })
    fence_hl.setup_hl(require('color_my_ascii.config').get())
    local buf = H.scratch('markdown', { '  ```lua', '  x = 1', '  ```' })
    fence_hl.apply(buf, require('color_my_ascii.config').get())
    local marks = api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })
    ok(marks[1] and marks[1][4].line_hl_group == 'ColorMyAsciiFenceOpen', 'opt-out: full-line line_hl_group')
    api.nvim_buf_delete(buf, { force = true })
  end

  require('color_my_ascii.config').setup({})
end
