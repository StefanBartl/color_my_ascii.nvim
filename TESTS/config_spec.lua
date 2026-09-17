-- TESTS/config_spec.lua — config merge, the lookup tables built from it, and
-- the lifecycle of the highlight groups it creates.
--
-- `config_languages_spec.lua` covers the `languages` extension point on its
-- own; this file covers the rest of `config/init.lua`, plus one property that
-- is easy to regress and expensive when it happens: `nvim_set_hl` forces a
-- full redraw, so highlight groups have to be defined once at setup time and
-- never from inside a render pass.

return function(H)
  local eq, ok = H.eq, H.ok
  local config = require('color_my_ascii.config')
  local parser = require('color_my_ascii.parser')
  local highlighter = require('color_my_ascii.highlighter')
  local fence_hl = require('color_my_ascii.fence_hl')

  -- ------------------------------------------------------ defaults and merge

  config.setup({})
  local cfg = config.get()
  eq(cfg.default_hl, 'Normal', 'defaults are in place after a bare setup()')
  eq(cfg.enable_keywords, true, 'feature flags default on')
  eq(cfg.language_detection_threshold, 2, 'and numeric defaults carry through')
  ok(next(cfg.groups) ~= nil, 'the bundled character groups are loaded')
  ok(next(cfg.keywords) ~= nil, 'and the bundled language definitions')
  eq(cfg.treesitter.enabled, true, 'nested defaults too')

  config.setup({ enable_keywords = false, language_detection_threshold = 7 })
  eq(config.get().enable_keywords, false, 'a user value overrides its default')
  eq(config.get().language_detection_threshold, 7, 'for every key given')
  eq(config.get().enable_inline_code, true, 'and leaves the rest of the defaults alone')

  -- Nested tables are deep-merged: naming one sub-key must not drop its
  -- siblings.
  config.setup({ treesitter = { syntax_highlight = false } })
  eq(config.get().treesitter.syntax_highlight, false, 'the named sub-key is taken')
  eq(config.get().treesitter.enabled, true, 'its siblings survive the merge')

  -- setup() is not cumulative: each call rebuilds from the defaults, so a key
  -- left out of the second call returns to its default rather than keeping the
  -- first call's value.
  config.setup({ enable_keywords = false })
  config.setup({})
  eq(config.get().enable_keywords, true, 'a second setup() resets omitted keys to their default')

  -- `get()` hands back the live configuration table, not a snapshot. Pinned as
  -- the documented behaviour it is -- the docstring promises "the current
  -- configuration", and callers such as fence_hl read it that way.
  ok(config.get() == config.get(), "get() returns the module's own table, not a copy")

  -- ---------------------------------------------------------------- schemes

  config.setup({ scheme = 'matrix' })
  local matrix = require('color_my_ascii.schemes.matrix')
  eq(config.get().default_hl, matrix.default_hl or config.get().default_hl, 'a named scheme is merged in')
  ok(config.get().scheme ~= nil, 'the scheme key itself survives on the merged config')

  -- User options win over the scheme they are combined with.
  config.setup({ scheme = 'matrix', language_detection_threshold = 99 })
  eq(config.get().language_detection_threshold, 99, 'user options beat the scheme')

  -- An unknown scheme is reported and then ignored: the remaining options are
  -- still applied rather than the whole call failing.
  --
  -- `config/init.lua` binds `local notify = vim.notify` at load time, so the
  -- capture has to be installed before the module is required -- the same seam
  -- rule this suite follows everywhere.
  local seen = H.reload_notify({ 'color_my_ascii.config' }, function(mods)
    mods['color_my_ascii.config'].setup({ scheme = 'no-such-scheme', language_detection_threshold = 3 })
    eq(mods['color_my_ascii.config'].get().language_detection_threshold, 3, 'and the rest of the options still apply')
  end)
  ok(H.notified(seen, 'Unknown scheme'), 'an unknown scheme is reported')

  -- A scheme passed as a table is taken as-is (scheme_loader's table branch).
  config.setup({ scheme = { default_hl = 'ZzSchemeTable' } })
  eq(config.get().default_hl, 'ZzSchemeTable', 'a scheme table is merged like a named one')

  config.setup({})

  -- ----------------------------------------------------------- lookup tables

  config.setup({
    overrides = { ['@'] = 'ZzOverride' },
    languages = {
      zzlang = { words = { 'zzword', 'zzshared' }, unique_words = { 'zzuniq' }, hl = 'ZzLangHl' },
    },
  })

  eq(config.get_char_highlight('@'), 'ZzOverride', 'an override wins over the group that owns the character')
  ok(config.get_char_highlight('+') ~= nil, 'a plain group character resolves')
  ok(config.get_char_highlight('q') == nil, 'an unclaimed character resolves to nil')

  local langs_for = config.get_keyword_languages('zzword')
  ok(langs_for ~= nil, 'a keyword resolves to its languages')
  eq(langs_for[1].language, 'zzlang', 'with the language name')
  eq(langs_for[1].hl, 'ZzLangHl', 'and the resolved highlight group')
  ok(config.get_keyword_languages('zznotakeyword') == nil, 'an unknown word resolves to nil')

  eq(config.get_unique_language('zzuniq'), 'zzlang', 'a unique keyword identifies its language')
  ok(config.get_unique_language('zzshared') == nil, 'a shared keyword does not')

  local available = config.get_available_languages()
  ok(vim.tbl_contains(available, 'zzlang'), 'the user language shows up as available')
  ok(vim.tbl_contains(available, 'lua'), 'alongside the bundled ones')
  local sorted = vim.deepcopy(available)
  table.sort(sorted)
  eq(table.concat(available, ','), table.concat(sorted, ','), 'the list is sorted')

  eq(config.is_function_detection_enabled(), true, 'function detection reads through to the flag')
  config.setup({ enable_function_names = false })
  eq(config.is_function_detection_enabled(), false, 'and follows it')

  -- With keywords disabled the lookups are not merely unused, they are empty.
  config.setup({ enable_keywords = false })
  eq(vim.tbl_count(config.keyword_lookup), 0, 'enable_keywords = false empties the keyword lookup')
  config.setup({ enable_language_detection = false })
  eq(vim.tbl_count(config.unique_keyword_lookup), 0, 'enable_language_detection = false empties the unique lookup')

  config.setup({})

  -- ------------------------------------------------- generated highlight groups
  --
  -- A `{ fg = ..., bold = ... }` highlight spec is turned into a real, named
  -- highlight group once and reused by name afterwards. The name is derived
  -- from the attributes (with "#" stripped, since it is not valid in a group
  -- name), which is what makes it stable across calls.

  config.setup({ default_text_hl = { fg = '#123456', bold = true } })
  local generated = config.get().default_text_hl
  eq(type(generated), 'string', 'the spec is replaced by a group name')
  ok(generated:find('ColorMyAsciiCustom', 1, true) == 1, "with the plugin's own prefix")
  ok(generated:find('#', 1, true) == nil, 'and no "#" left in it')

  local attrs = vim.api.nvim_get_hl(0, { name = generated })
  eq(attrs.fg, tonumber('123456', 16), 'the group really carries the requested foreground')
  eq(attrs.bold, true, 'and the requested attributes')

  config.setup({ default_text_hl = { fg = '#123456', bold = true } })
  eq(config.get().default_text_hl, generated, 'the same spec resolves to the same group name')

  -- `:colorscheme` runs an implicit `hi clear`, which wipes these fixed-colour
  -- groups while the module still believes they exist. reapply_custom_highlights
  -- is what the ColorScheme autocmd uses to put them back.
  vim.api.nvim_set_hl(0, generated, {})
  eq(vim.api.nvim_get_hl(0, { name = generated }).fg, nil, 'the group can be wiped')
  config.reapply_custom_highlights()
  eq(vim.api.nvim_get_hl(0, { name = generated }).fg, tonumber('123456', 16), 'and is restored verbatim')

  -- ------------------------------------------- highlight groups are not per-render
  --
  -- `nvim_set_hl` forces a full redraw. Defining a group inside a render path
  -- would therefore turn every debounced re-highlight into a full screen
  -- repaint, on every keystroke in a markdown buffer. The contract is: groups
  -- are created while the configuration is built, and the painting passes only
  -- ever *name* them.

  local calls = 0
  local original_set_hl = vim.api.nvim_set_hl
  vim.api.nvim_set_hl = function(...)
    calls = calls + 1
    return original_set_hl(...)
  end

  local render_ok, render_err = pcall(function()
    config.setup({
      default_text_hl = { fg = '#abcdef' },
      overrides = { ['+'] = { fg = '#fedcba', italic = true } },
      fence_line_highlight = { enable = true },
      fence_content_highlight = { enable = true },
      treesitter = { enabled = false, block_detection = false, syntax_highlight = false },
    })
    ok(calls > 0, 'building the configuration is what creates the groups')

    fence_hl.setup_hl(config.get())
    ok(calls > 0, 'setup_hl creates the fence groups, once, from setup()')

    local buf = H.scratch('markdown', { '```ascii', '+--+', '```' })
    calls = 0
    for _, block in ipairs(parser.find_ascii_blocks(buf)) do
      highlighter.highlight_block(buf, block)
    end
    highlighter.highlight_inline_codes(buf)
    fence_hl.apply(buf, config.get())
    eq(calls, 0, 'a full render pass defines no highlight group at all')

    -- And a repeat pass, the debounced case, does not either.
    highlighter.clear_buffer(buf)
    for _, block in ipairs(parser.find_ascii_blocks(buf)) do
      highlighter.highlight_block(buf, block)
    end
    fence_hl.apply(buf, config.get())
    eq(calls, 0, 'nor does re-rendering the same buffer')
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  vim.api.nvim_set_hl = original_set_hl
  if not render_ok then
    error(render_err, 0)
  end

  config.setup({})
end
