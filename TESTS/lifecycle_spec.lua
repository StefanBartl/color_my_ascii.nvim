-- TESTS/lifecycle_spec.lua — `color_my_ascii/init.lua`: setup, per-buffer
-- attachment, the cached highlight pass, and teardown.
--
-- `toggle_buffer_spec.lua` covers the per-buffer switch. What is pinned here
-- is the rest of the module's state machine, and in particular the teardown:
-- a cleanup handler that runs *while* a buffer is being deleted has to touch
-- only what is still legal to touch at that moment, through every route a
-- buffer can disappear by (`nvim_buf_delete`, `:bdelete`, `:bwipeout`).

return function(H)
  local eq, ok = H.eq, H.ok
  local cma = require('color_my_ascii')
  local cache = require('color_my_ascii.cache_manager')

  local NS = 'ColorMyAscii'

  ---@return integer
  local function fixture()
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { '```ascii', '+--+', '|ok|', '+--+', '```' })
    vim.bo[buf].filetype = 'markdown'
    return buf
  end

  -- ----------------------------------------------------------------- setup

  local setup_ok, setup_err = cma.setup({})
  eq(setup_ok, true, 'setup() reports success')
  ok(setup_err == nil, 'and no error')

  -- Re-callable, which is the whole point: the plugin/ bootstrap calls it once
  -- with defaults and the user's own config calls it again.
  eq(cma.setup({ language_detection_threshold = 4 }), true, 'setup() can be called again')
  eq(require('color_my_ascii.config').get().language_detection_threshold, 4, 'with effect')
  cma.setup({})

  -- ---------------------------------------------------------- setup_buffer

  local dead = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_delete(dead, { force = true })
  local attached, why = cma.setup_buffer(dead)
  eq(attached, false, 'an invalid buffer is refused')
  ok(why:find('Invalid buffer', 1, true) ~= nil, 'with a message naming it')

  local buf = fixture()
  eq(cma.setup_buffer(buf), true, 'a real buffer attaches')
  eq(cma.get_state().buffers[buf], true, 'and is marked managed')
  ok(#H.marks(buf, NS) > 0, 'attaching highlights it right away')

  -- The per-buffer autocommands live in their own augroup.
  local group = 'ColorMyAsciiBuffer_' .. buf
  local autocmds = vim.api.nvim_get_autocmds({ group = group })
  local events = {}
  for _, a in ipairs(autocmds) do
    events[a.event] = true
  end
  ok(events.TextChanged, 'a TextChanged autocommand is registered for the buffer')
  ok(events.TextChangedI, 'and one for insert mode')
  ok(events.BufDelete, 'plus the cleanup handler')
  for _, a in ipairs(autocmds) do
    eq(a.buffer, buf, 'every one of them is buffer-local')
  end

  -- ------------------------------------------------------- highlight_buffer

  -- Deliberately without a filetype: setting one to "markdown" would fire the
  -- plugin's own FileType autocommand and attach the buffer behind our back.
  local unmanaged = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(unmanaged, 0, -1, false, { '```ascii', '+-+', '```' })
  local painted, reason = cma.highlight_buffer(unmanaged)
  eq(painted, false, 'an unmanaged buffer is not painted')
  ok(reason:find('not managed', 1, true) ~= nil, 'and says why')
  vim.api.nvim_buf_delete(unmanaged, { force = true })

  eq(cma.highlight_buffer(buf), true, 'a managed buffer paints')

  -- Cache miss, then hit: the second pass in a row (no edit in between)
  -- must be served from the cache rather than re-parsed.
  cma.setup({ cache = { enable_stats = true, timeout = 60000 } })
  cma.setup_buffer(buf)
  cache.invalidate(buf)
  cache.reset_stats()
  cma.highlight_buffer(buf)
  eq(cache.get_stats().misses, 1, 'the first pass after an invalidation is a miss')
  cma.highlight_buffer(buf)
  eq(cache.get_stats().hits, 1, 'the second is a hit')
  ok(#H.marks(buf, NS) > 0, 'and the cached pass still paints')

  -- An edit takes the miss path again -- and the marks follow the new content.
  vim.api.nvim_buf_set_lines(buf, 1, 2, false, { '+----+' })
  cma.highlight_buffer(buf)
  eq(cache.get_stats().misses, 2, 'an edit forces a re-parse')

  -- A buffer that dies between being marked managed and being painted is
  -- reported, not raised.
  local doomed = fixture()
  cma.setup_buffer(doomed)
  vim.api.nvim_buf_delete(doomed, { force = true })
  painted, reason = cma.highlight_buffer(doomed)
  eq(painted, false, 'a deleted buffer is refused, not raised')
  -- The BufDelete handler has already unmarked it by now, so it is the
  -- "not managed" guard that answers rather than the validity check below it.
  ok(reason:find('not managed', 1, true) ~= nil, 'the not-managed guard answers first')

  -- ------------------------------------------------------------- teardown
  --
  -- The cleanup handler runs during BufDelete, i.e. while the buffer is on its
  -- way out. It unmarks the buffer, clears both extmark namespaces, drops the
  -- cache entry and cancels the debounce timer -- and must not itself try to
  -- delete anything. Checked through all three routes a buffer disappears by,
  -- including the one where it is still displayed in a window.

  ---@param label string
  ---@param kill fun(bufnr: integer)
  local function teardown_via(label, kill)
    local victim = fixture()
    cma.setup_buffer(victim)
    cache.set(victim, {}, {})
    ok(cma.get_state().buffers[victim] == true, label .. ': managed before')

    local torn_ok, torn_err = pcall(kill, victim)
    ok(torn_ok, label .. ': teardown raises nothing (' .. tostring(torn_err) .. ')')
    ok(cma.get_state().buffers[victim] == nil, label .. ': the buffer is unmarked')
    eq(select(3, cache.get(victim)), false, label .. ': and its cache entry is gone')
  end

  teardown_via('nvim_buf_delete', function(b)
    vim.api.nvim_buf_delete(b, { force = true })
  end)
  teardown_via(':bdelete', function(b)
    vim.cmd(('silent! %dbdelete!'):format(b))
  end)
  teardown_via(':bwipeout', function(b)
    vim.cmd(('silent! %dbwipeout!'):format(b))
  end)

  -- The window case is the one that raised E937 elsewhere in this campaign:
  -- deleting a buffer that is still the current window's buffer.
  local in_window = fixture()
  vim.api.nvim_set_current_buf(in_window)
  cma.setup_buffer(in_window)
  local win_ok, win_err = pcall(vim.api.nvim_buf_delete, in_window, { force = true })
  ok(win_ok, 'deleting a buffer that is still shown raises nothing (' .. tostring(win_err) .. ')')
  ok(cma.get_state().buffers[in_window] == nil, 'and it is unmarked')

  -- ---------------------------------------------------------------- toggle

  local a, b = fixture(), fixture()
  cma.setup_buffer(a)
  cma.setup_buffer(b)
  ok(#H.marks(a, NS) > 0, 'both buffers are painted')

  eq(cma.toggle(), false, 'toggle() switches the plugin off')
  eq(#H.marks(a, NS), 0, 'and clears every managed buffer')
  eq(#H.marks(b, NS), 0, 'all of them')
  ok(cma.get_state().buffers[a] == true, 'while leaving them managed')

  eq(cma.setup_buffer(a), false, 'attaching a buffer while globally off is refused')

  eq(cma.toggle(), true, 'toggle() switches it back on')
  ok(#H.marks(a, NS) > 0, 'and repaints the managed buffers')

  -- ------------------------------------------------------------- get_state

  local snapshot = cma.get_state()
  snapshot.buffers[a] = nil
  snapshot.enabled = false
  ok(cma.get_state().buffers[a] == true, 'get_state hands back a deep copy')
  eq(cma.get_state().enabled, true, 'that cannot be written through')

  -- --------------------------------------------------------- hot reload
  --
  -- Calling setup() again with a managed buffer around invalidates the stale
  -- parse cache and repaints, so an edited `languages` entry takes effect
  -- without touching the buffer.

  cache.reset_stats()
  cma.setup({ cache = { enable_stats = true, timeout = 60000 } })
  ok(#H.marks(a, NS) > 0, 'a re-setup repaints the managed buffers')
  eq(select(3, cache.get(a)), true, 'and leaves a fresh cache entry behind')

  -- ---------------------------------------------------- the passthrough API

  eq(type(cma.get_cache_stats()), 'table', 'get_cache_stats forwards to the cache')
  eq(type(cma.get_cache_hit_rate()), 'number', 'get_cache_hit_rate too')
  eq(type(cma.get_debounce_config()), 'table', 'and get_debounce_config to the debouncer')
  ok(cma.clear_caches() >= 1, 'clear_caches reports how many entries it dropped')
  eq(cma.clear_caches(), 0, 'and zero once the cache is empty')

  cma.configure_cache({ max_size = 7 })
  eq(cache.get_config().max_size, 7, 'configure_cache forwards its options')
  local debounce = require('color_my_ascii.debounce_manager')
  local original_small = debounce.get_config().small_delay
  cma.configure_debounce({ small_delay = 123 })
  eq(debounce.get_config().small_delay, 123, 'configure_debounce does too')
  cma.configure_debounce({ small_delay = original_small })

  -- ------------------------------------------------ colorscheme autocommands
  --
  -- `:colorscheme` runs an implicit `hi clear`. Two autocommands put the
  -- plugin's own groups back: the fence-line groups and the generated
  -- fixed-colour ASCII groups.

  cma.setup({ default_text_hl = { fg = '#0f0f0f' }, fence_line_highlight = { enable = true } })
  local generated = require('color_my_ascii.config').get().default_text_hl
  vim.api.nvim_set_hl(0, generated, {})
  vim.api.nvim_set_hl(0, 'ColorMyAsciiFenceOpen', {})
  ok(pcall(vim.api.nvim_exec_autocmds, 'ColorScheme', {}), 'firing ColorScheme raises nothing')
  eq(vim.api.nvim_get_hl(0, { name = generated }).fg, tonumber('0f0f0f', 16), 'the generated group is back')
  ok(next(vim.api.nvim_get_hl(0, { name = 'ColorMyAsciiFenceOpen' })) ~= nil, 'and so is the fence group')

  -- The resize handler recomputes the right-edge inset; with both paddings at
  -- zero it returns immediately, and with one set it repaints without raising.
  cma.setup({ fence_line_highlight = { enable = true, right_pad = 0 }, fence_content_highlight = { right_pad = 0 } })
  ok(pcall(vim.api.nvim_exec_autocmds, 'VimResized', {}), 'a resize with no padding is a no-op')
  cma.setup({ fence_line_highlight = { enable = true, right_pad = 2 } })
  vim.api.nvim_set_current_buf(a)
  cma.setup_buffer(a)
  ok(pcall(vim.api.nvim_exec_autocmds, 'VimResized', {}), 'a resize with padding repaints without raising')

  -- ------------------------------------------------- the plugin/ bootstrap
  --
  -- The two files Neovim sources at startup. Not reached by the suite's own
  -- `set rtp+=.` run (which loads modules by require, not by sourcing
  -- `plugin/`), so they are executed explicitly here: the double-load guard,
  -- and the wiring the guard protects.

  local plugin_dir = debug.getinfo(1, 'S').source:sub(2):match('(.*[/\\])') .. '../plugin/'

  local loaded_before = vim.g.loaded_color_my_ascii
  vim.g.loaded_color_my_ascii = 1
  ok(pcall(dofile, plugin_dir .. 'color_my_ascii.lua'), 'a second load returns at the guard')
  eq(vim.g.loaded_color_my_ascii, 1, 'leaving the flag as it found it')

  vim.g.loaded_color_my_ascii = nil
  vim.api.nvim_del_augroup_by_name('ColorMyAscii')
  ok(pcall(dofile, plugin_dir .. 'color_my_ascii.lua'), 'a first load runs through')
  eq(vim.g.loaded_color_my_ascii, 1, 'setting the guard flag')
  eq(vim.fn.exists(':ColorMyAscii'), 2, 'registering the user command')
  ok(#vim.api.nvim_get_autocmds({ group = 'ColorMyAscii' }) > 0, 'and the static autocommands')
  vim.g.loaded_color_my_ascii = loaded_before or 1

  ok(pcall(dofile, plugin_dir .. 'color_my_ascii_autodoc.lua'), 'the helptag generator loads without raising')

  -- ------------------------------------------------------------- clean up

  for _, victim in ipairs({ buf, a, b }) do
    if vim.api.nvim_buf_is_valid(victim) then
      vim.api.nvim_buf_delete(victim, { force = true })
    end
  end
  cma.setup({})
  cache.configure({ timeout = 5000, max_size = 50, enable_stats = false })
  cache.clear_all()
end
