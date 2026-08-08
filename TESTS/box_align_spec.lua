-- TESTS/box_align_spec.lua — box_align.align() (:Fence align's algorithm).
---@diagnostic disable: missing-fields

return function(H)
  local eq, ok = H.eq, H.ok
  local align = require('color_my_ascii.box_align')

  -- ---- simple drift: right edge widened, content preserved -----------------
  do
    local out, changed = align.align({
      '┌────┐',
      '│ hi │',
      '│ world  │',
      '└────┘',
    })
    eq(changed, 1, 'drift: one box changed')
    eq(out[1], '┌────────┐', 'drift: top border widened')
    eq(out[2], '│ hi     │', 'drift: short interior row padded')
    eq(out[3], '│ world  │', 'drift: wide interior row unchanged (already the max)')
    eq(out[4], '└────────┘', 'drift: bottom border widened')
    for _, line in ipairs(out) do
      eq(vim.fn.strchars(line), vim.fn.strchars(out[1]), 'drift: every row has the same character count as the border')
    end
  end

  -- ---- ASCII (+/-/|) style works the same way -------------------------------
  do
    local out, changed = align.align({
      '+----+',
      '| hi |',
      '| world  |',
      '+----+',
    })
    eq(changed, 1, 'ascii: one box changed')
    eq(out[1], '+--------+', 'ascii: top border widened')
    eq(out[4], '+--------+', 'ascii: bottom border widened')
  end

  -- ---- missing right edge: added, never treated as "no box" ----------------
  do
    local out, changed = align.align({
      '┌────┐',
      '│ hi',
      '│ world │',
      '└────┘',
    })
    eq(changed, 1, 'missing edge: one box changed')
    eq(out[2], '│ hi    │', 'missing edge: right edge added with correct padding')
  end

  -- ---- already aligned: no-op, lines untouched ------------------------------
  do
    local input = { '┌────┐', '│ hi │', '└────┘' }
    local out, changed = align.align(input)
    eq(changed, 0, 'aligned: no boxes reported as changed')
    eq(out[1], input[1], 'aligned: top border byte-identical')
    eq(out[2], input[2], 'aligned: interior byte-identical')
    eq(out[3], input[3], 'aligned: bottom border byte-identical')
  end

  -- ---- non-box content (directory tree) is left completely untouched -------
  do
    local input = {
      'project/',
      '├── src/',
      '│   └── main.lua',
      '└── README.md',
    }
    local out, changed = align.align(input)
    eq(changed, 0, 'tree: no boxes detected')
    for i, line in ipairs(input) do
      eq(out[i], line, 'tree: line ' .. i .. ' untouched')
    end
  end

  -- ---- indentation before the box is preserved ------------------------------
  do
    local out = align.align({
      '  ┌───┐',
      '  │ a │',
      '  │ bb  │',
      '  └───┘',
    })
    ok(out[1]:sub(1, 2) == '  ', 'indent: leading whitespace kept on the border')
    ok(out[2]:sub(1, 2) == '  ', 'indent: leading whitespace kept on interior rows')
  end

  -- ---- two separate boxes in one block: handled independently --------------
  do
    local out, changed = align.align({
      '┌───┐',
      '│ a │',
      '└───┘',
      '',
      '┌────┐',
      '│ bb   │',
      '└────┘',
    })
    eq(changed, 1, 'two boxes: only the misaligned one counted')
    eq(out[1], '┌───┐', 'two boxes: first box (already fine) untouched')
    eq(out[5], '┌──────┐', 'two boxes: second box widened')
    eq(out[4], '', 'two boxes: blank separator line preserved')
  end

  -- ---- malformed "box" (junction chars instead of a real bottom border) ----
  -- must not be misdetected as a box at all.
  do
    local input = {
      '┌────┐',
      '│ a  │',
      '├────┤',
      '│ bb   │',
      '└────┘',
    }
    local out, changed = align.align(input)
    eq(changed, 0, 'malformed: not detected as any box')
    for i, line in ipairs(input) do
      eq(out[i], line, 'malformed: line ' .. i .. ' untouched')
    end
  end

  -- ---- empty input: no crash -------------------------------------------------
  do
    local out, changed = align.align({})
    eq(changed, 0, 'empty: no boxes')
    eq(#out, 0, 'empty: no lines')
  end
end
