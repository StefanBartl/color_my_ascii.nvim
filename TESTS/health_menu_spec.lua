-- TESTS/health_menu_spec.lua — `:checkhealth color_my_ascii` and the opt-in
-- context-menu entries.
--
-- Both are reporters, so both are checked the same way: through a recorder
-- substituted for the reporting API, asserting on *what was reported* rather
-- than on a return value neither of them has. `ui.nvim` is a soft dependency
-- and not a CI checkout, so `ui.contextmenu` is replaced in `package.loaded`
-- before any menu entries are requested -- `integrations/menu.lua` resolves
-- it lazily per call rather than at require time, so the stub only needs to
-- be in place when `items()`/`submenu()` actually run.

return function(H)
  local eq, ok = H.eq, H.ok
  local config = require('color_my_ascii.config')

  -- --------------------------------------------------------------- health

  ---@return table report
  ---@return table recorder
  local function recorder()
    local report = { ok = {}, info = {}, warn = {}, error = {}, start = {} }
    return report,
      {
        start = function(name)
          report.start[#report.start + 1] = name
        end,
        ok = function(msg)
          report.ok[#report.ok + 1] = msg
        end,
        info = function(msg)
          report.info[#report.info + 1] = msg
        end,
        warn = function(msg)
          report.warn[#report.warn + 1] = msg
        end,
        error = function(msg)
          report.error[#report.error + 1] = msg
        end,
      }
  end

  ---@param list string[]
  ---@param needle string
  ---@return boolean
  local function says(list, needle)
    for _, msg in ipairs(list) do
      if tostring(msg):find(needle, 1, true) then
        return true
      end
    end
    return false
  end

  ---@return table report
  local function checkhealth()
    local report, rec = recorder()
    local original = vim.health
    vim.health = rec
    local run_ok, err = pcall(require('color_my_ascii.health').check)
    vim.health = original
    if not run_ok then
      error(err, 0)
    end
    return report
  end

  config.setup({})
  -- The report ends by handing over to lib.nvim's composer, which reports an
  -- error for a verb that was never registered. Register it here rather than
  -- depending on whichever spec happened to run first.
  require('color_my_ascii.bindings.usrcmds').enable()

  local md = H.scratch('markdown', { '```lua', 'local x = 1', '```', '```zznolang', 'x', '```' })
  vim.api.nvim_set_current_buf(md)

  local report = checkhealth()
  eq(report.start[1], 'color_my_ascii.nvim', 'the report opens with the plugin name')
  eq(#report.error, 0, 'a healthy checkout reports no errors')
  ok(says(report.ok, 'Module "color_my_ascii" loaded successfully'), 'the core modules are checked')
  ok(says(report.ok, 'Module "color_my_ascii.highlighter" loaded successfully'), 'each of them')
  ok(says(report.ok, 'language(s) loaded'), 'the loaded languages are counted')
  ok(says(report.ok, 'character group(s) loaded'), 'and the character groups')
  ok(says(report.ok, 'character(s) in lookup table'), 'the lookup tables are reported')
  ok(says(report.ok, 'Languages directory found'), 'the bundled directories are found')
  ok(says(report.ok, 'Groups directory found'), 'all of them')
  ok(says(report.ok, 'Color schemes directory found'), 'schemes included')
  ok(says(report.ok, 'lib.nvim found'), 'lib.nvim is reported as present')
  ok(says(report.ok, 'Fence API available'), 'and the public fence API as available')
  ok(says(report.ok, 'All core modules loaded successfully'), 'with a closing summary')
  ok(says(report.ok, 'Current buffer is markdown'), 'the current markdown buffer is recognised')
  ok(says(report.info, 'Feature status:'), 'the feature flags are listed')

  -- The fence-language section reads the *current buffer* and splits its fence
  -- tags by whether a treesitter parser exists for them.
  ok(
    says(report.ok, 'Fence languages with a treesitter parser') or says(report.info, 'WITHOUT a treesitter parser'),
    "the buffer's fence languages are reported"
  )
  if says(report.info, 'WITHOUT a treesitter parser') then
    ok(says(report.info, 'zznolang'), 'the made-up tag is on the "no parser" side')
  end

  -- Sub-feature reporting follows the configuration in both directions.
  config.setup({ fence_line_highlight = { enable = false }, fence_content_highlight = { enable = false } })
  report = checkhealth()
  ok(says(report.info, 'Fence-line highlight: disabled'), 'a disabled fence-line highlight is reported')
  ok(says(report.info, 'Fence-content highlight: disabled'), 'and a disabled fence-content highlight')

  config.setup({
    fence_line_highlight = { enable = true, preset = 'accent', apply_to = 'ascii' },
    fence_content_highlight = { enable = true, shade = 'lighten', amount = 9 },
  })
  report = checkhealth()
  ok(says(report.ok, 'Fence-line highlight: enabled'), 'an enabled one is reported')
  ok(says(report.ok, 'accent'), 'naming its preset')
  ok(says(report.ok, 'Fence-content highlight: enabled'), 'and the content highlight too')
  ok(says(report.ok, 'lighten'), 'naming its shade')

  config.setup({ treesitter = { enabled = true, block_detection = true, syntax_highlight = true } })
  report = checkhealth()
  ok(
    says(report.ok, 'Treesitter block detection') or says(report.info, 'Treesitter block detection'),
    'treesitter block detection is reported either way'
  )
  ok(says(report.info, 'Treesitter syntax highlighting enabled'), 'and the per-block syntax note')

  config.setup({ treesitter = { enabled = false, block_detection = false, syntax_highlight = false } })
  report = checkhealth()
  ok(not says(report.info, 'Treesitter syntax highlighting enabled'), 'both are silent when switched off')

  -- A non-markdown buffer is reported as such rather than as a problem.
  local plain = H.scratch('text', { 'x' })
  vim.api.nvim_set_current_buf(plain)
  report = checkhealth()
  ok(says(report.info, 'Current buffer is not markdown'), 'a non-markdown buffer is reported as info')
  eq(#report.error, 0, 'and is not an error')
  vim.api.nvim_buf_delete(plain, { force = true })

  -- The initialisation flag is read from vim.g, which the plugin/ bootstrap
  -- sets; both states are reported.
  local loaded_before = vim.g.loaded_color_my_ascii
  vim.g.loaded_color_my_ascii = nil
  vim.api.nvim_set_current_buf(md)
  report = checkhealth()
  ok(says(report.info, 'Plugin not initialized'), 'an unloaded plugin is reported')
  vim.g.loaded_color_my_ascii = 1
  report = checkhealth()
  ok(says(report.ok, 'Plugin initialized successfully'), 'and a loaded one')
  vim.g.loaded_color_my_ascii = loaded_before

  -- Regression: a missing lib.nvim used to crash the whole report rather than
  -- just reporting it. `composer_ok` from the "lib.nvim found" check above was
  -- discarded, and the report ended by unconditionally re-requiring the exact
  -- module just reported missing to hand off to it -- raising, and aborting
  -- the report right after the health.error that was supposed to explain why.
  -- Simulated at the require seam (composer is a real sibling checkout here,
  -- same as the rest of this suite) rather than by actually uninstalling
  -- lib.nvim.
  do
    local PATH = 'lib.nvim.bindings.usercmd.composer'
    local saved = package.loaded[PATH]
    package.loaded[PATH] = nil
    package.preload[PATH] = function()
      error('synthetic: lib.nvim not installed')
    end
    local run_ok, run_err = pcall(function()
      report = checkhealth()
    end)
    package.preload[PATH] = nil
    package.loaded[PATH] = saved
    ok(run_ok, ('checkhealth completes rather than raising when lib.nvim is missing (%s)'):format(tostring(run_err)))
    ok(says(report.error, 'lib.nvim not found'), 'and still reports the missing dependency')
  end

  vim.api.nvim_buf_delete(md, { force = true })
  config.setup({})

  -- ----------------------------------------------------------------- menu

  ---@return table stub
  local function contextmenu_stub()
    return {
      group = function(out, ...)
        for _, entry in ipairs({ ... }) do
          out[#out + 1] = entry
        end
        out[#out + 1] = { separator = true }
      end,
      entry = function(enabled, label, action)
        return { enabled = enabled, label = label, action = action }
      end,
      submenu = function(label, items)
        return { label = label, items = items }
      end,
    }
  end

  ---@param fn fun(menu: table)
  local function with_menu(fn)
    H.with_modules({
      ['ui.contextmenu'] = contextmenu_stub(),
      ['color_my_ascii.integrations.menu'] = false,
    }, function()
      fn(require('color_my_ascii.integrations.menu'))
    end)
  end

  config.setup({})
  local menu_buf = H.scratch('markdown', { 'prose', '```lua', 'local x = 1', '```' })
  vim.api.nvim_set_current_buf(menu_buf)

  with_menu(function(menu)
    -- Cursor inside a fenced block: every entry is offered, the fence actions
    -- enabled.
    vim.api.nvim_win_set_cursor(0, { 3, 0 })
    local items = menu.items(menu_buf)
    ok(#items > 0, 'a markdown buffer gets menu entries')

    -- enabled(): what ui.nvim's ui.menu asks first.
    eq(menu.enabled(), true, 'enabled() is true by default')
    config.setup({ integrations = { ui_menu = false } })
    eq(menu.enabled(), false, 'integrations.ui_menu = false -> enabled() false')
    ok(#menu.items(menu_buf) > 0, 'ui_menu = false leaves items() to other hosts')
    config.setup({ menu = { enable = false } })
    eq(menu.enabled(), false, 'menu.enable = false -> enabled() false')
    config.setup({})

    local by_label = {}
    for _, item in ipairs(items) do
      if item.label then
        by_label[item.label] = item
      end
    end
    ok(by_label['  Toggle ASCII highlighting'] ~= nil, 'the toggle entry is there')
    eq(by_label['  Toggle ASCII highlighting'].enabled, true, 'always enabled')
    eq(by_label['  Yank fence content'].enabled, true, 'the fence actions are enabled inside a block')
    eq(by_label['  Wrap line in a fence'].enabled, true, 'and so is wrap')

    -- Cursor outside any block: the fence actions are greyed out, wrap is not
    -- (it creates a fence rather than acting on one).
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    items = menu.items(menu_buf)
    by_label = {}
    for _, item in ipairs(items) do
      if item.label then
        by_label[item.label] = item
      end
    end
    eq(by_label['  Yank fence content'].enabled, false, 'fence actions are disabled outside a block')
    eq(by_label['  Unwrap fence under cursor'].enabled, false, 'unwrap too')
    eq(by_label['  Wrap line in a fence'].enabled, true, 'wrap stays enabled -- it creates a fence')
    eq(by_label['  Switch color scheme'].enabled, true, 'and the buffer-wide entries too')

    -- The actions are callable; `:Fence yank` on the current block is the one
    -- with an observable effect.
    vim.api.nvim_win_set_cursor(0, { 3, 0 })
    items = menu.items(menu_buf)
    for _, item in ipairs(items) do
      if item.label == '  Toggle ASCII highlighting' then
        local before = require('color_my_ascii').get_state().enabled
        ok(pcall(item.action), 'a menu action really runs its command')
        eq(require('color_my_ascii').get_state().enabled, not before, 'with the effect the label promises')
        require('color_my_ascii').toggle() -- and back, so the suite carries on as it was
      end
    end

    -- The submenu wrapper reuses the same list.
    local sub = menu.submenu(nil, menu_buf)
    eq(sub.label, '  Color My ASCII', 'the submenu carries a default label')
    ok(#sub.items > 0, 'wrapping the same entries')
    eq(menu.submenu('Custom', menu_buf).label, 'Custom', 'and accepts a custom one')

    -- Opt-out, and the filetype gate.
    config.setup({ menu = { enable = false } })
    eq(#menu.items(menu_buf), 0, 'menu.enable = false returns no entries')
    config.setup({})

    local other = H.scratch('lua', { 'local x = 1' })
    eq(#menu.items(other), 0, 'a non-markdown buffer gets no entries')
    vim.api.nvim_buf_delete(other, { force = true })
  end)

  vim.api.nvim_buf_delete(menu_buf, { force = true })
  config.setup({})
end
