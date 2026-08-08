-- TESTS/highlight_export_spec.lua — highlight_export (HTML/ANSI serializers).
---@diagnostic disable: missing-fields, param-type-mismatch

return function(H)
  local eq, ok = H.eq, H.ok
  local api = vim.api

  require('color_my_ascii.config').setup({})
  local cma = require('color_my_ascii')
  cma.setup({})
  local he = require('color_my_ascii.highlight_export')

  local buf = H.scratch('markdown', {
    '```ascii',
    '+--+',
    '```',
  })
  cma.setup_buffer(buf)

  local block = require('color_my_ascii.api.fences').block_at(buf, 1, { include_fence = true })
  ok(block ~= nil, 'block found for content row')

  -- ---- runs_for_block: contiguous same-group runs, byte-column-aligned -----
  do
    local runs = he.runs_for_block(buf, block)
    eq(#runs, 1, 'one content row')
    local joined = ''
    for _, r in ipairs(runs[1]) do
      joined = joined .. r.text
    end
    eq(joined, '+--+', 'runs reassemble to the original line')
    ok(#runs[1] > 0, 'at least one run')
    for _, r in ipairs(runs[1]) do
      ok(r.group == nil or type(r.group) == 'string', 'each run has a group or nil')
    end
  end

  -- ---- to_html: span-wrapped runs + a stylesheet rule per group used -------
  do
    local html = he.to_html(buf, block)
    ok(html:find('<pre class="cma%-fence">', 1, false) ~= nil, 'html: pre block present')
    ok(html:find('%+%-%-%+') ~= nil or html:find('<span', 1, true) ~= nil, 'html: content or spans present')
    ok(html:find('<style>', 1, true) ~= nil, 'html: stylesheet block present')
    -- every class referenced in the body has a matching CSS rule
    for class in html:gmatch('class="(cma%-[%w_-]+)"') do
      ok(html:find('%.' .. class:gsub('%-', '%%-') .. '{'), 'html: css rule exists for ' .. class)
    end
  end

  -- ---- to_ansi: escape codes wrap highlighted runs, reset after each -------
  do
    local ansi = he.to_ansi(buf, block)
    local ESC = string.char(27)
    ok(ansi:find(ESC, 1, true) ~= nil, 'ansi: contains at least one escape sequence')
    ok(ansi:find(ESC .. '[0m', 1, true) ~= nil, 'ansi: contains a reset code')
    -- stripping all escape codes must recover the plain content
    local stripped = ansi:gsub(ESC .. '%[[%d;]*m', '')
    eq(stripped, '+--+', 'ansi: stripped of escapes matches plain content')
  end

  -- ---- unhighlighted content: no groups, no escapes/spans -------------------
  do
    local buf2 = H.scratch('markdown', {
      '```text',
      'plain text, no highlighting',
      '```',
    })
    cma.setup_buffer(buf2)
    local block2 = require('color_my_ascii.api.fences').block_at(buf2, 1, { include_fence = true })
    local runs = he.runs_for_block(buf2, block2)
    for _, r in ipairs(runs[1]) do
      eq(r.group, nil, 'plain text block: no color_my_ascii group applied')
    end
    local ansi = he.to_ansi(buf2, block2)
    eq(ansi, 'plain text, no highlighting', 'ansi: unhighlighted block passes through unchanged')
    api.nvim_buf_delete(buf2, { force = true })
  end

  api.nvim_buf_delete(buf, { force = true })
  require('color_my_ascii.config').setup({})
end
