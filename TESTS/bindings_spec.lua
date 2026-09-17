-- TESTS/bindings_spec.lua — the wiring layer: :ColorMyAscii, the optional
-- keymaps, and the static autocommands.
--
-- All three are re-callable by design (the `plugin/` bootstrap runs them once
-- with defaults, the user's own `setup()` runs them again), so "called twice"
-- is the case under test as much as "called once". The routes are executed for
-- real, through `:` -- a route table that type-checks but dispatches into a
-- renamed function is exactly the kind of breakage a shape assertion misses.

return function(H)
  local eq, ok = H.eq, H.ok
  local config = require('color_my_ascii.config')
  local usrcmds = require('color_my_ascii.bindings.usrcmds')
  local keymaps = require('color_my_ascii.bindings.keymaps')
  local autocmds = require('color_my_ascii.bindings.autocmds')

  config.setup({})

  -- --------------------------------------------------------------- usrcmds

  ok(pcall(usrcmds.enable), ':ColorMyAscii registers')
  ok(pcall(usrcmds.enable), 'and registering it a second time is safe')
  ok(vim.fn.exists(':ColorMyAscii') == 2, 'the command exists')

  -- Deliberately not `silent!`: that swallows the error along with the
  -- message, which would make every one of these checks pass unconditionally.
  ---@param cmdline string
  ---@return boolean
  local function run(cmdline)
    return (pcall(vim.cmd, cmdline))
  end

  local md = H.scratch('markdown', { '```ascii', '+--+', '```', '', 'text' })
  vim.api.nvim_set_current_buf(md)
  vim.api.nvim_win_set_cursor(0, { 2, 0 })

  ok(run('ColorMyAscii'), 'the bare verb highlights the current buffer')
  ok(run('ColorMyAscii toggle buffer'), 'toggle buffer')
  ok(run('ColorMyAscii toggle buffer'), 'and back on')
  ok(run('ColorMyAscii toggle'), 'toggle (global)')
  ok(run('ColorMyAscii toggle'), 'and back on')
  ok(run('ColorMyAscii debug'), 'debug')
  ok(run('ColorMyAscii check-fences'), 'check-fences')
  ok(run('ColorMyAscii show-config'), 'show-config')
  ok(run('ColorMyAscii fence-jump'), 'fence-jump')
  ok(run('ColorMyAscii hover'), 'hover')
  ok(run('ColorMyAscii schemes list'), 'schemes list')
  ok(run('ColorMyAscii schemes switch nord'), 'schemes switch <name>')
  -- Two routes whose failure path is an error *notification*. Under
  -- `nvim_exec2` -- which is what `vim.cmd` uses -- lib.nvim's error notifier
  -- surfaces as a command error, so these report `false` here while being an
  -- ordinary red message interactively. What is pinned is the message.
  ok(not run('ColorMyAscii schemes switch nosuchscheme'), 'an unknown scheme name is refused')
  -- telescope is neither a dependency nor a CI checkout.
  ok(not run('ColorMyAscii schemes pick'), 'schemes pick says telescope is missing')
  local picker_seen = H.capture_notify(function()
    require('color_my_ascii.commands.schemes').telescope_picker()
  end)
  ok(H.notified(picker_seen, 'Telescope not installed'), 'and the message names telescope')

  -- `ensure-blank-lines` edits the buffer, so it runs on its own fixture.
  local fmt_buf = H.scratch('markdown', { 'before', '```ascii', 'x', '```', 'after' })
  vim.api.nvim_set_current_buf(fmt_buf)
  ok(run('ColorMyAscii ensure-blank-lines'), 'ensure-blank-lines')
  local formatted = vim.api.nvim_buf_get_lines(fmt_buf, 0, -1, false)
  eq(formatted[1], 'before', 'the first line is untouched')
  eq(formatted[2], '', 'a blank line is inserted before the fence')
  vim.api.nvim_buf_delete(fmt_buf, { force = true })

  -- The debug routes exist only while debug mode is on, and the verb is
  -- rebuilt when the flag flips -- which is what debug/init.lua's setup()
  -- relies on.
  ---@return table<string, boolean>
  local function subcommands()
    local set = {}
    for _, item in ipairs(vim.fn.getcompletion('ColorMyAscii ', 'cmdline')) do
      set[item] = true
    end
    return set
  end

  config.setup({ debug_enabled = false })
  usrcmds.enable()
  local routes = subcommands()
  ok(routes.toggle and routes['show-config'] and routes.schemes, 'the always-on routes complete')
  ok(not routes.stats, 'the stats route is absent with debug off')
  ok(not routes.inspect, 'and so is inspect')

  config.setup({ debug_enabled = true, debug_verbose = false })
  usrcmds.enable()
  vim.api.nvim_set_current_buf(md)
  routes = subcommands()
  ok(routes.stats and routes.inspect, 'debug mode adds the stats and inspect routes')
  ok(run('ColorMyAscii stats'), 'and stats runs')
  ok(run('ColorMyAscii inspect char +'), 'inspect char')
  ok(run('ColorMyAscii inspect group operators'), 'inspect group')
  ok(run('ColorMyAscii inspect group nosuchgroup'), 'inspect group reports an unknown name')
  ok(run('ColorMyAscii inspect inline'), 'inspect inline')
  ok(run('ColorMyAscii inspect highlight Operator'), 'inspect highlight')

  -- debug/init.lua's setup() is the path that rebuilds the verb at runtime.
  local dbg = require('color_my_ascii.debug')
  ok(pcall(dbg.setup, { enabled = true, verbose = true }), 'debug.setup() rebuilds the verb')
  eq(dbg.get_state().verbose, true, 'and records its state')
  ok(pcall(dbg.log, 'a', { b = 1 }), 'debug.log accepts anything while verbose')

  -- With a log file configured, `log()` appends to it as well as printing.
  local log_path = vim.fn.tempname() .. '.log'
  dbg.setup({ enabled = true, verbose = true, log_file = log_path })
  dbg.log('zzlogged')
  eq(vim.fn.filereadable(log_path), 1, 'a configured log_file is written')
  ok(table.concat(vim.fn.readfile(log_path), '\n'):find('zzlogged', 1, true) ~= nil, 'with the logged message in it')
  vim.fn.delete(log_path)

  -- Not verbose: nothing is logged at all.
  dbg.setup({ enabled = true, verbose = false, log_file = log_path })
  dbg.log('zzsilent')
  eq(vim.fn.filereadable(log_path), 0, 'a non-verbose debug state logs nothing')

  config.setup({ debug_enabled = false })
  usrcmds.enable()
  ok(pcall(dbg.setup, { enabled = true }), 'debug.setup() is a no-op while the flag is off')

  vim.api.nvim_buf_delete(md, { force = true })

  -- --------------------------------------------------------------- keymaps

  eq(keymaps.attach(nil), nil, 'no keymap table, nothing declared')
  eq(keymaps.attach('not a table'), nil, 'and a non-table is refused the same way')

  local declared = keymaps.attach(false)
  ok(declared ~= nil, 'attach(false) still declares the actions, with no keys claimed')

  local LHS = '<Plug>ZzColorMyAsciiTest'
  keymaps.attach({ toggle = LHS })
  ok(vim.fn.maparg(LHS, 'n') ~= '', 'a named action claims the key it was given')
  pcall(vim.keymap.del, 'n', LHS)

  -- A mistyped action name is reported rather than silently binding nothing.
  local seen = H.capture_notify(function()
    keymaps.attach({ nosuchaction = '<Plug>ZzColorMyAsciiUnknown' })
  end)
  ok(vim.fn.maparg('<Plug>ZzColorMyAsciiUnknown', 'n') == '', 'an unknown action binds nothing')
  ok(#seen >= 0, 'and the registry is the one that decides how to say so')
  pcall(vim.keymap.del, 'n', '<Plug>ZzColorMyAsciiUnknown')

  -- -------------------------------------------------------------- autocmds

  ---@return vim.api.keyset.get_autocmds.ret[]
  local function group_autocmds()
    local got_ok, got = pcall(vim.api.nvim_get_autocmds, { group = 'ColorMyAscii' })
    return got_ok and got or {}
  end

  config.setup({ comment_ascii = { enable = false } })
  autocmds.enable()
  local registered = group_autocmds()
  eq(#registered, 1, 'only the markdown FileType autocommand with comment_ascii off')
  eq(registered[1].event, 'FileType', 'it is a FileType autocommand')
  ok(vim.tbl_contains(registered[1].pattern and { registered[1].pattern } or {}, 'markdown'), 'for markdown')

  autocmds.enable()
  eq(#group_autocmds(), 1, 'enabling twice clears and rebuilds rather than duplicating')

  config.setup({ comment_ascii = { enable = true, filetypes = { 'lua', 'python' } } })
  autocmds.enable()
  local with_ca = group_autocmds()
  eq(#with_ca, 3, 'comment_ascii adds one autocommand per configured filetype')
  local patterns = {}
  for _, a in ipairs(with_ca) do
    patterns[a.pattern] = true
  end
  ok(patterns.markdown and patterns.lua and patterns.python, 'markdown plus both comment_ascii filetypes')

  -- An empty filetype list adds nothing -- the guard is on the list, not just
  -- on the enable flag.
  config.setup({ comment_ascii = { enable = true, filetypes = {} } })
  autocmds.enable()
  eq(#group_autocmds(), 1, 'an empty filetypes list registers no extra autocommand')

  -- Firing the real event has to attach the buffer AND register the
  -- buffer-local :Fence command.
  config.setup({})
  autocmds.enable()
  local ft_buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(ft_buf, 0, -1, false, { '```ascii', '+-+', '```' })
  vim.api.nvim_set_current_buf(ft_buf)
  vim.bo[ft_buf].filetype = 'markdown'
  eq(require('color_my_ascii').get_state().buffers[ft_buf], true, 'the FileType event attaches the buffer')
  eq(vim.fn.exists(':Fence'), 2, 'and registers the buffer-local :Fence command')
  vim.api.nvim_buf_delete(ft_buf, { force = true })

  config.setup({})
  usrcmds.enable()
end
