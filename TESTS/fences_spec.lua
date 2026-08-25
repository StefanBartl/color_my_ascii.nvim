-- docs/TESTS/fences_spec.lua — public fence API + generic block scanners.
-- Runs against both the heuristic scanner and (when a markdown parser is
-- installed) the treesitter backend, asserting they agree.
---@diagnostic disable: missing-fields

return function(H)
  local eq, ok = H.eq, H.ok

  local LINES = {
    '# Title', -- 0
    '', -- 1
    '```markdown', -- 2
    '## Inner H2', -- 3
    'text', -- 4
    '```', -- 5
    '', -- 6
    '```lua', -- 7
    'local x = 1', -- 8
    '```', -- 9
    '', -- 10
    '```ascii-c', -- 11
    '+--+', -- 12
    '```', -- 13
  }

  local function run_backend(label, ts_enabled)
    require('color_my_ascii.config').setup({ treesitter = { enabled = ts_enabled, block_detection = ts_enabled } })
    local fences = require('color_my_ascii').fences
    fences.invalidate()
    local buf = H.scratch('markdown', LINES)

    local blocks = fences.list_blocks(buf)
    eq(#blocks, 3, label .. ': three blocks')
    eq(blocks[1].open_row, 2, label .. ': md open_row')
    eq(blocks[1].close_row, 5, label .. ': md close_row')
    eq(blocks[1].content_start, 3, label .. ': md content_start')
    eq(blocks[1].content_end, 5, label .. ': md content_end')
    eq(blocks[1].lang, 'markdown', label .. ': md lang')
    eq(blocks[1].fence_char, '`', label .. ': md fence_char')
    eq(blocks[1].fence_len, 3, label .. ': md fence_len')
    -- ColorMyAscii.Block aliases preserved for existing consumers:
    eq(blocks[1].start_line, 2, label .. ': alias start_line')
    eq(blocks[1].end_line, 5, label .. ': alias end_line')
    ok(blocks[1].lines == nil, label .. ': lines not collected by default')

    eq(#fences.list_blocks(buf, { markdown = true }), 1, label .. ': md filter -> 1')
    eq(#fences.list_blocks(buf, { lang = 'lua' }), 1, label .. ': lua filter -> 1')

    eq(fences.block_at(buf, 4).lang, 'markdown', label .. ': block_at interior')
    ok(fences.block_at(buf, 2) == nil, label .. ': fence line not interior')
    ok(fences.block_at(buf, 2, { include_fence = true }).lang == 'markdown', label .. ': include_fence')
    ok(fences.block_at(buf, 0) == nil, label .. ': outside -> nil')
    ok(fences.block_at(buf, 8, { markdown = true }) == nil, label .. ': md filter excludes lua block')

    ok(fences.is_markdown_lang('md') and fences.is_markdown_lang('MDX'), label .. ': is_markdown_lang yes')
    ok(not fences.is_markdown_lang('lua'), label .. ': is_markdown_lang no')

    local with_lines = fences.list_blocks(buf, { lines = 'all' })
    eq(with_lines[1].lines[1], '## Inner H2', label .. ': lines=all populated')

    -- ASCII backward-compat path still finds the ascii-c block, with content.
    local ascii = require('color_my_ascii.parser').find_ascii_blocks(buf)
    local found
    for _, b in ipairs(ascii) do
      if b.start_line == 11 then
        found = b
      end
    end
    ok(found ~= nil, label .. ': ascii block detected (compat)')
    eq(found.lines[1], '+--+', label .. ': ascii block content')

    vim.api.nvim_buf_delete(buf, { force = true })
  end

  run_backend('heuristic', false)
  if require('color_my_ascii.parser_ts').markdown_available() then
    run_backend('treesitter', true)
  end

  require('color_my_ascii.config').setup({})
end
