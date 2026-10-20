-- TESTS/visible_range_spec.lua — the opt-in `visible_range` option: only rows
-- around the window are painted in very large buffers, and a scroll past them
-- repaints around the new position.
---@diagnostic disable: missing-fields

return function(H)
  local eq, ok = H.eq, H.ok
  local cma = require('color_my_ascii')
  local vr = require('color_my_ascii.visible_range')
  local ns = vim.api.nvim_get_namespaces()['ColorMyAscii'] or vim.api.nvim_create_namespace('ColorMyAscii')

  -- ---- hits(): nil accepts everything, otherwise plain interval overlap ------
  local range = { first = 10, last = 20 }
  eq(vr.hits(nil, 500, 600), true, 'hits: nil range accepts any rows')
  eq(vr.hits(range, 0, 9), false, 'hits: block above the range')
  eq(vr.hits(range, 21, 30), false, 'hits: block below the range')
  eq(vr.hits(range, 5, 10), true, 'hits: block touching the first row')
  eq(vr.hits(range, 20, 30), true, 'hits: block touching the last row')
  eq(vr.hits(range, 0, 100), true, 'hits: block spanning the whole range')

  -- A 2500-line document with an ASCII block near the top and one near the bottom.
  local lines = {}
  for i = 1, 2500 do
    lines[i] = 'prose line ' .. i
  end
  local function put_block(at)
    lines[at] = '```ascii'
    lines[at + 1] = '┌─► func ─┐'
    lines[at + 2] = '```'
  end
  put_block(10)
  put_block(2300)

  local function marks_between(buf, first, last)
    return #vim.api.nvim_buf_get_extmarks(buf, ns, { first, 0 }, { last, -1 }, {})
  end

  local function fresh()
    local buf = H.scratch('markdown', lines)
    cma.setup_buffer(buf)
    vim.fn.winrestview({ topline = 1 })
    return buf
  end

  -- ---- default: off, everything painted --------------------------------------
  cma.setup({})
  local buf = fresh()
  require('color_my_ascii.cache_manager').invalidate(buf)
  cma.highlight_buffer(buf)
  ok(marks_between(buf, 9, 11) > 0, 'off: top block painted')
  ok(marks_between(buf, 2299, 2301) > 0, 'off: bottom block painted too')
  vim.api.nvim_buf_delete(buf, { force = true })

  -- ---- on: only the rows around the window ------------------------------------
  cma.setup({ visible_range = { enable = true, margin = 20, min_lines = 100 } })
  buf = fresh()
  require('color_my_ascii.cache_manager').invalidate(buf)
  cma.highlight_buffer(buf)
  ok(marks_between(buf, 9, 11) > 0, 'on: block in view is painted')
  eq(marks_between(buf, 2299, 2301), 0, 'on: block far below the view is not painted')
  eq(
    vr.needs_repaint(buf, require('color_my_ascii.config').get()),
    false,
    'on: no repaint needed while the view stays put'
  )

  -- ---- scrolling past the painted rows repaints around the new position -------
  vim.fn.winrestview({ topline = 2290 })
  eq(
    vr.needs_repaint(buf, require('color_my_ascii.config').get()),
    true,
    'scroll: leaving the painted rows asks for a repaint'
  )
  cma.highlight_buffer(buf)
  ok(marks_between(buf, 2299, 2301) > 0, 'scroll: block now in view is painted')
  eq(marks_between(buf, 9, 11), 0, 'scroll: block left far behind is cleared')
  vim.api.nvim_buf_delete(buf, { force = true })

  -- ---- the view nears the painted edge: repaint before it runs out ------------
  cma.setup({ visible_range = { enable = true, margin = 40, min_lines = 100 } })
  buf = fresh()
  require('color_my_ascii.cache_manager').invalidate(buf)
  cma.highlight_buffer(buf)
  local cfg_now = require('color_my_ascii.config').get()
  eq(vr.needs_repaint(buf, cfg_now), false, 'slack: top of the buffer needs nothing')
  vim.fn.winrestview({ topline = 100 })
  cma.highlight_buffer(buf) -- painted rows now ~60..165
  eq(vr.needs_repaint(buf, cfg_now), false, 'slack: view in the middle of the painted rows')
  vim.fn.winrestview({ topline = 70 })
  eq(vr.needs_repaint(buf, cfg_now), true, 'slack: view within half a margin of the top edge asks for a repaint')
  vim.api.nvim_buf_delete(buf, { force = true })

  -- ---- a jump without a scroll event is picked up by the autocmd ---------------
  cma.setup({ visible_range = { enable = true, margin = 20, min_lines = 100 } })
  buf = fresh()
  require('color_my_ascii.cache_manager').invalidate(buf)
  cma.highlight_buffer(buf)
  eq(marks_between(buf, 2299, 2301), 0, 'jump: far block not painted before the jump')
  vim.fn.winrestview({ topline = 2290 })
  vim.api.nvim_exec_autocmds('BufWinEnter', { buffer = buf })
  ok(
    vim.wait(1000, function()
      return marks_between(buf, 2299, 2301) > 0
    end, 20),
    'jump: BufWinEnter repaints around the new view'
  )
  vim.api.nvim_buf_delete(buf, { force = true })

  -- ---- option off: no autocmd group content ---------------------------------------
  cma.setup({})
  eq(#vim.api.nvim_get_autocmds({ group = 'ColorMyAsciiVisibleRange' }), 0, 'off: no visible_range autocmds registered')

  -- ---- buffers up to min_lines are always painted in full ---------------------
  cma.setup({ visible_range = { enable = true, margin = 20, min_lines = 5000 } })
  buf = fresh()
  require('color_my_ascii.cache_manager').invalidate(buf)
  cma.highlight_buffer(buf)
  ok(marks_between(buf, 2299, 2301) > 0, 'min_lines: a buffer below the threshold is painted in full')
  vim.api.nvim_buf_delete(buf, { force = true })

  cma.setup({})
end
