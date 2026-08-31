-- TESTS/api_highlight_spec.lua — the public read-back API (api/highlight.lua).
--
-- What `highlight_export` already did for :Fence export is now also a public
-- surface, so another plugin can reproduce the buffer's colors in its own
-- medium. This spec guards the promises that surface makes, since a consumer
-- outside this repo cannot see them break: the runs reassemble the source line
-- byte for byte, attributes come back as "#rrggbb" strings with link chains
-- followed, and an unpainted block answers honestly instead of inventing color.
---@diagnostic disable: missing-fields, param-type-mismatch, undefined-global

return function(H)
  local eq, ok = H.eq, H.ok

  require('color_my_ascii.config').setup({})
  local cma = require('color_my_ascii')
  cma.setup({})

  -- ---- reachable from the root module, without setup() gymnastics ---------
  do
    ok(type(cma.highlight) == 'table', 'api: color_my_ascii.highlight is exposed')
    ok(type(cma.highlight.runs_for_block) == 'function', 'api: runs_for_block')
    ok(type(cma.highlight.attrs_for_group) == 'function', 'api: attrs_for_group')
  end

  local hl = cma.highlight
  local fences = cma.fences

  -- ---- runs over a painted block -----------------------------------------
  do
    local buf = H.scratch('markdown', {
      '```lua',
      'local x = 1',
      'return x',
      '```',
    })
    cma.setup_buffer(buf)

    local blocks = fences.list_blocks(buf)
    eq(#blocks, 1, 'one fenced block')
    local runs = hl.runs_for_block(buf, blocks[1])
    eq(#runs, 2, 'one runs-array per content row')

    for i, line in ipairs({ 'local x = 1', 'return x' }) do
      local joined = ''
      for _, run in ipairs(runs[i]) do
        joined = joined .. run.text
      end
      eq(joined, line, 'row ' .. i .. ' reassembles byte for byte')
    end
  end

  -- ---- an unpainted block answers with nil groups, not with guesses -------
  do
    local buf = H.scratch('markdown', {
      '```',
      'plain text, no language',
      '```',
    })
    -- Deliberately NOT setup_buffer'd: nothing has painted this buffer, so the
    -- honest answer is "no groups" — the consumer's cue to fall back.
    local blocks = fences.list_blocks(buf)
    eq(#blocks, 1, 'one fenced block')
    local runs = hl.runs_for_block(buf, blocks[1])
    local painted = false
    for _, row in ipairs(runs) do
      for _, run in ipairs(row) do
        if run.group ~= nil then
          painted = true
        end
      end
    end
    eq(painted, false, 'unpainted block reports no groups')
  end

  -- ---- attrs_for_group: hex strings, links followed, absent stays absent --
  do
    vim.api.nvim_set_hl(0, 'CmaSpecBase', { fg = 0xff8800, bold = true })
    vim.api.nvim_set_hl(0, 'CmaSpecLink', { link = 'CmaSpecBase' })

    local attrs = hl.attrs_for_group('CmaSpecBase')
    eq(attrs.fg, '#ff8800', 'attrs: fg as #rrggbb')
    eq(attrs.bold, true, 'attrs: bold')
    eq(attrs.bg, nil, 'attrs: an unset background stays nil, not a default')
    eq(attrs.italic, nil, 'attrs: an unset style stays nil')

    local linked = hl.attrs_for_group('CmaSpecLink')
    eq(linked.fg, '#ff8800', 'attrs: link= chains are followed')

    local missing = hl.attrs_for_group('CmaSpecNoSuchGroupExists')
    eq(missing.fg, nil, 'attrs: an unknown group yields no attributes, not an error')
  end
end
