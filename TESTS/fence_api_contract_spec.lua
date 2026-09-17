-- TESTS/fence_api_contract_spec.lua — the fenced-block API as a *contract*.
--
-- `color_my_ascii.api.fences` is not an internal helper: markdown.nvim's
-- `fenced_scope` feature treats a fenced block as its own scope by calling into
-- it through a soft `pcall(require, "color_my_ascii")`, and falls back to its
-- own small scanner when the require fails. That makes three things load-
-- bearing from this side, none of which the plugin's own features would notice
-- breaking:
--
--   1. reachability -- `require("color_my_ascii").fences` is a table, available
--      without anyone having called `setup()`;
--   2. the exact call shapes the consumer uses, down to `content_start` /
--      `content_end` being 0-indexed and half-open, because the consumer adds
--      1 to one of them and not to the other;
--   3. the consumer's own absence changing nothing here -- the API is
--      standalone, and it is the *consumer* that degrades.
--
-- `fences_spec.lua` checks the detection itself against both backends; this
-- file pins the shape of the promise.

return function(H)
  local eq, ok = H.eq, H.ok
  local config = require('color_my_ascii.config')

  config.setup({})

  -- ------------------------------------------------------------ reachability

  local cma = require('color_my_ascii')
  eq(type(cma), 'table', 'the plugin module is a table (what the consumer checks first)')
  eq(type(cma.fences), 'table', "and exposes .fences as a table (the consumer's second check)")
  ok(cma.fences == require('color_my_ascii.api.fences'), '.fences is the api.fences module itself')
  eq(type(cma.fences.list_blocks), 'function', 'list_blocks is callable')
  eq(type(cma.fences.block_at), 'function', 'block_at is callable')
  eq(type(cma.fences.is_markdown_lang), 'function', 'is_markdown_lang is callable')
  eq(type(cma.fences.invalidate), 'function', 'invalidate is callable')

  local fences = cma.fences

  -- ----------------------------------------------- the consumer's call shapes
  --
  -- markdown.nvim calls exactly these two forms:
  --   fences.block_at(bufnr, row0, { lang = <string[]> })
  --   fences.list_blocks(bufnr)
  -- and reads `content_start`/`content_end` off the result as a half-open,
  -- 0-indexed row range (`first = content_start + 1`, `last = content_end`).

  local LINES = {
    '# Title', -- 0
    '', -- 1
    '```markdown', -- 2
    'inner', -- 3
    'text', -- 4
    '```', -- 5
    '', -- 6
    '```lua', -- 7
    'local x = 1', -- 8
    '```', -- 9
    '', -- 10
    '```md', -- 11
    '```', -- 12
  }

  local buf = H.scratch('markdown', LINES)
  fences.invalidate()

  local md_langs = { 'markdown', 'md', 'mdx' }
  local block = fences.block_at(buf, 3, { lang = md_langs })
  ok(block ~= nil, 'block_at finds the markdown block from its interior')
  eq(block.content_start, 3, 'content_start is the first interior row, 0-indexed')
  eq(block.content_end, 5, 'content_end is exclusive (== close_row)')
  eq(block.content_start + 1, 4, 'the consumer\'s "first interior line" arithmetic lands on line 4')
  eq(block.content_end, 5, 'and its "last interior line" on line 5')
  eq(block.open_row, 2, 'open_row is the delimiter row')
  eq(block.close_row, 5, 'close_row likewise')
  eq(block.lang, 'markdown', 'lang is the raw fence tag')

  ok(fences.block_at(buf, 8, { lang = md_langs }) == nil, 'a lua block is not a markdown scope')
  ok(fences.block_at(buf, 0, { lang = md_langs }) == nil, 'prose outside any block has no scope')
  ok(fences.block_at(buf, 2, { lang = md_langs }) == nil, 'the opening delimiter is outside the interior')
  ok(fences.block_at(buf, 5, { lang = md_langs }) == nil, 'and so is the closing one')
  eq(fences.block_at(buf, 2, { lang = md_langs, include_fence = true }).lang, 'markdown', 'include_fence reaches it')

  -- The empty block at rows 11..12 has no interior at all: only include_fence
  -- can match it, which is what keeps `content_end > content_start` a usable
  -- "non-empty interior" test on the consumer's side.
  ok(fences.block_at(buf, 11, { lang = md_langs }) == nil, 'an empty block has no interior row to match')
  ok(fences.block_at(buf, 11, { lang = md_langs, include_fence = true }) ~= nil, 'include_fence still finds it')

  local all = fences.list_blocks(buf)
  eq(#all, 3, 'list_blocks with no options returns every fenced block')
  local non_empty = 0
  for _, b in ipairs(all) do
    if b.content_end > b.content_start then
      non_empty = non_empty + 1
    end
  end
  eq(non_empty, 2, "two of them have a non-empty interior (the consumer's exclude list)")

  -- ----------------------------------------------------------- filtering

  eq(#fences.list_blocks(buf, { lang = 'lua' }), 1, 'a single-string lang filter')
  eq(#fences.list_blocks(buf, { lang = { 'lua', 'markdown' } }), 2, 'a list lang filter')
  eq(#fences.list_blocks(buf, { lang = 'LUA' }), 1, 'the filter is case-insensitive')
  eq(#fences.list_blocks(buf, { lang = {} }), 0, 'an empty list filter matches nothing')
  eq(#fences.list_blocks(buf, { markdown = true }), 2, 'the markdown family covers markdown and md')
  eq(#fences.list_blocks(buf, { markdown = true, markdown_extra = { lua = true } }), 3, 'markdown_extra widens it')
  eq(#fences.list_blocks(buf, {
    filter = function(b)
      return b.close_row - b.open_row > 2
    end,
  }), 1, 'a user filter is applied')
  eq(#fences.list_blocks(buf, {
    markdown = true,
    filter = function()
      return false
    end,
  }), 0, 'filters combine (both must pass)')

  -- ------------------------------------------------------- is_markdown_lang

  ok(fences.is_markdown_lang('markdown'), 'markdown')
  ok(fences.is_markdown_lang('MD'), 'case-insensitive')
  ok(fences.is_markdown_lang('  mdx  '), 'trimmed')
  ok(fences.is_markdown_lang('ascii-md'), 'the ascii-md alias counts')
  ok(not fences.is_markdown_lang('lua'), 'lua does not')
  ok(not fences.is_markdown_lang(''), 'an empty tag does not')
  ok(not fences.is_markdown_lang(nil), 'nil is answered, not raised')
  ok(not fences.is_markdown_lang(42), 'and so is a non-string')
  ok(fences.is_markdown_lang('rmd', { rmd = true }), 'extra tags are honoured')
  ok(not fences.is_markdown_lang('rmd'), 'and are not remembered between calls')

  -- --------------------------------------------------------------- caching
  --
  -- Range-only queries are cached per (buffer, changedtick). The identity of
  -- the returned table is the observable: a cache hit hands back the very same
  -- list, a miss builds a new one.

  local first = fences.list_blocks(buf)
  ok(fences.list_blocks(buf) == first, 'a second range-only query is served from the cache')
  ok(fences.list_blocks(buf, { lines = 'all' }) ~= first, 'asking for content bypasses the cache')

  vim.api.nvim_buf_set_lines(buf, 0, 1, false, { '# Changed' })
  ok(fences.list_blocks(buf) ~= first, 'an edit bumps changedtick and re-scans')

  local before_invalidate = fences.list_blocks(buf)
  fences.invalidate(buf)
  ok(fences.list_blocks(buf) ~= before_invalidate, 'invalidate(bufnr) drops that buffer')

  local before_all = fences.list_blocks(buf)
  fences.invalidate()
  ok(fences.list_blocks(buf) ~= before_all, 'invalidate() drops every buffer')

  -- The API installs its own augroup for this; a wiped buffer must not keep a
  -- stale entry alive under a bufnr Neovim may hand out again.
  local cached = fences.list_blocks(buf)
  vim.api.nvim_exec_autocmds('BufWipeout', { buffer = buf })
  ok(fences.list_blocks(buf) ~= cached, 'BufWipeout invalidates the cached list')

  cached = fences.list_blocks(buf)
  vim.api.nvim_exec_autocmds('BufDelete', { buffer = buf })
  ok(fences.list_blocks(buf) ~= cached, 'BufDelete does too')

  -- ------------------------------------------------- cursor row by default

  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_win_set_cursor(0, { 4, 0 }) -- 1-indexed -> row 3
  eq(fences.block_at(buf).lang, 'markdown', 'block_at defaults to the cursor row')
  eq(fences.block_at().lang, 'markdown', 'and to the current buffer')

  -- -------------------------------------------- agreement with the scanner

  local scanned = require('color_my_ascii.parser').scan_blocks_heuristic(buf, { lines = 'none' })
  local api_blocks = require('color_my_ascii.parser').find_all_blocks(buf, { lines = 'none' })
  eq(#api_blocks, #scanned, 'the dispatcher and the heuristic scanner agree on the block count')

  vim.api.nvim_buf_delete(buf, { force = true })
  fences.invalidate()

  -- ----------------------------------------------------------- a cold load
  --
  -- The module must not need the plugin to have been set up: `init.lua`
  -- requires it at its own top level, before any `setup()` runs, and a
  -- consumer may reach it the same way. Re-requiring it from a cleared
  -- `package.loaded` is the closest a single-process suite gets to "somebody
  -- loaded only this".
  --
  -- Deliberately last in this file: the module registers its cache-invalidation
  -- autocmds into an augroup it *clears* on load, so a second instance takes
  -- the BufDelete/BufWipeout hooks away from the first. The rebinding below
  -- leaves one live instance behind rather than a half-wired pair.
  H.with_modules({ ['color_my_ascii.api.fences'] = false }, function()
    local fresh = require('color_my_ascii.api.fences')
    eq(type(fresh.list_blocks), 'function', 'a cold load of the API needs no setup() first')
    local cold = H.scratch('markdown', { '```md', 'x', '```' })
    eq(#fresh.list_blocks(cold), 1, 'and answers immediately')
    vim.api.nvim_buf_delete(cold, { force = true })
  end)

  package.loaded['color_my_ascii.api.fences'] = nil
  cma.fences = require('color_my_ascii.api.fences')
  ok(cma.fences ~= fences, 'the reload really produced a new instance')
  eq(type(cma.fences.block_at), 'function', 'and the plugin now points at it')

  config.setup({})
end
