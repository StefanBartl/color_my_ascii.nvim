-- TESTS/debug_inspect_spec.lua — debug.inspect.get_statistics() with schemes
-- whose group `hl` is a ColorMyAscii.CustomHighlight table (not a plain
-- highlight-group string). Regression for a crash where
-- `stats.groups.by_highlight` was keyed by the raw table, so printing it
-- with `hl .. ': '` failed with "attempt to concatenate a table value".

return function(H)
  local eq, ok = H.eq, H.ok
  local config = require('color_my_ascii.config')
  local inspect = require('color_my_ascii.debug.inspect')

  -- ---- scheme with table-valued group highlights (dracula) ------------------
  do
    config.setup({ scheme = 'dracula' })

    local stats = inspect.get_statistics()
    ok(stats.groups.count > 0, 'get_statistics: dracula scheme reports groups')

    for hl, groups in pairs(stats.groups.by_highlight) do
      eq(type(hl), 'string', 'by_highlight: key is always a string, even for table-valued group.hl')
      ok(#groups > 0, 'by_highlight: each key maps to at least one group name')
      -- Must not error: this is exactly what the stats printer does.
      local _ = '    ' .. hl .. ': ' .. table.concat(groups, ', ')
    end
  end

  -- ---- default scheme still reports plain highlight-group names as-is -------
  do
    config.setup({})

    local stats = inspect.get_statistics()
    for hl, _ in pairs(stats.groups.by_highlight) do
      eq(type(hl), 'string', 'by_highlight: key is a string for the default scheme too')
      ok(not hl:find('^table:'), "by_highlight: plain highlight names aren't mangled")
    end
  end

  config.setup({})
end
