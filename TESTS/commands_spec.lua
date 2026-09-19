-- TESTS/commands_spec.lua — the command modules that had no suite yet:
-- the two report commands, the blank-line formatter, the fence linter, the
-- scheme commands, and the shared `:Fence` helpers plus the two subcommands
-- that shell out.
--
-- No subprocess is started. `:Fence run` and `:Fence format` reach the outside
-- world through `vim.system`, which is a field on `vim` resolved at call time
-- -- so it is replaced for the duration of the check and what gets asserted is
-- the argv that *would* have been spawned, plus each branch of the completion
-- callback.

return function(H)
  local eq, ok = H.eq, H.ok
  local config = require('color_my_ascii.config')

  config.setup({})

  -- ------------------------------------------------------- report commands
  --
  -- Both build a multi-line report and hand it to the notifier; what matters
  -- is that they survive every configuration they can be called in and that
  -- the numbers they quote come from the live configuration.

  local seen = H.capture_notify(function()
    require('color_my_ascii.commands.config').show_config()
  end)
  ok(H.notified(seen, 'Configuration'), 'show-config reports a configuration block')
  ok(H.notified(seen, '## Languages'), 'with a languages section')
  ok(H.notified(seen, '## Character Groups'), 'and a character groups section')
  ok(H.notified(seen, 'Threshold'), 'and the detection threshold while detection is on')

  config.setup({ enable_language_detection = false })
  seen = H.capture_notify(function()
    require('color_my_ascii.commands.config').show_config()
  end)
  ok(not H.notified(seen, 'Threshold'), 'the detection section is omitted when detection is off')

  config.setup({})
  seen = H.capture_notify(function()
    require('color_my_ascii.commands.debug').show_debug_info()
  end)
  ok(H.notified(seen, 'Debug Info'), 'the debug report is produced')
  ok(H.notified(seen, 'Languages loaded'), 'listing the loaded languages')
  ok(H.notified(seen, 'Character lookup entries'), 'and the lookup sizes')

  -- ------------------------------------------------- ensure-blank-lines
  --
  -- `commands/format.lua` binds `local notify = vim.notify` at load time, so
  -- its messages are captured by reloading it behind the capture.

  ---@param lines string[]
  ---@return string[] result
  ---@return { msg: string, level: integer|nil }[] messages
  local function ensure_blank(lines)
    local buf = H.scratch('markdown', lines)
    vim.api.nvim_set_current_buf(buf)
    local messages = H.reload_notify({ 'color_my_ascii.commands.format' }, function(mods)
      mods['color_my_ascii.commands.format'].ensure_blank_lines()
    end)
    local result = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    vim.api.nvim_buf_delete(buf, { force = true })
    return result, messages
  end

  local result, messages = ensure_blank({ 'before', '```ascii', 'x', '```', 'after' })
  eq(result[1], 'before', 'text before the block is kept')
  eq(result[2], '', 'a blank line is inserted before the opening fence')
  eq(result[3], '```ascii', 'followed by the fence itself')
  ok(H.notified(messages, 'Added'), 'and the number of inserted lines is reported')

  -- Noted: the "Empty buffer" guard is unreachable. A Neovim buffer always has
  -- at least one line, so `#lines` is never 0 -- an emptied buffer takes the
  -- ordinary path and reports "no changes needed".
  local emptied
  emptied, messages = ensure_blank({})
  eq(table.concat(emptied, '|'), '', 'an emptied buffer is still a one-line buffer')
  ok(not H.notified(messages, 'Empty buffer'), 'so it never reaches the empty-buffer guard')
  ok(H.notified(messages, 'No changes needed'), 'it takes the ordinary path instead')

  result = ensure_blank({ '```ascii', 'x', '```' })
  eq(result[1], '```ascii', 'a fence on the very first line gets no blank line above it')

  -- ------------------------------------------------------------ regression
  --
  -- The command promises blank lines *around* a fenced block. It used to
  -- insert them INSIDE it as well, editing the block's content: the scanner
  -- treated every fence line alike and, for each, consumed the following line
  -- and appended a blank after it. For an opening fence that following line is
  -- the block's FIRST CONTENT LINE, so a blank row was pushed into the middle
  -- of the art and a second one in front of the closing fence -- a destructive
  -- edit of the very blocks this plugin exists to highlight, reachable from
  -- `:ColorMyAscii ensure-blank-lines` and from the optional keymap. The walk
  -- tracks open vs. close now.

  result = ensure_blank({ 'before', '```ascii', '+-+', '|x|', '+-+', '```', 'after' })
  eq(
    table.concat(result, '|'),
    'before||```ascii|+-+|\124x\124|+-+|```||after',
    'the art is spaced from its surroundings and otherwise untouched'
  )
  eq(result[4], '+-+', 'the first content line stays put...')
  eq(result[5], '|x|', '...and is still followed by the next one')
  eq(result[7], '```', 'the closing fence directly follows the last content line')

  -- And it is idempotent: an already-spaced block is a no-op, not two more
  -- rows.
  result, messages = ensure_blank({ '', '```ascii', 'x', '```', '' })
  eq(table.concat(result, '|'), '|```ascii|x|```|', 'an already-spaced block is left alone')
  ok(H.notified(messages, 'No changes needed'), 'and reported as a no-op')

  -- A buffer with no fence line at all needs nothing either.
  result, messages = ensure_blank({ 'just prose', 'and more prose' })
  ok(H.notified(messages, 'No changes needed'), 'a buffer without fences needs nothing')
  eq(table.concat(result, '|'), 'just prose|and more prose', 'and is left untouched')

  -- --------------------------------------------------------- check-fences

  ---@param lines string[]
  ---@return { msg: string, level: integer|nil }[]
  local function check_fences(lines)
    local buf = H.scratch('markdown', lines)
    vim.api.nvim_set_current_buf(buf)
    local msgs = H.reload_notify({ 'color_my_ascii.commands.fence_check' }, function(mods)
      mods['color_my_ascii.commands.fence_check'].check_current_buffer()
    end)
    vim.api.nvim_buf_delete(buf, { force = true })
    return msgs
  end

  local checked = check_fences({ '```ascii', 'x', '```' })
  ok(H.notified(checked, 'No unmatched'), 'a balanced buffer is clean')

  checked = check_fences({ '```ascii', 'x' })
  ok(H.notified(checked, 'without matching closing fence'), 'an unclosed block is reported')
  ok(H.notified(checked, 'Line 1'), 'naming the line it was opened on')

  checked = check_fences({ '````ascii', 'x', '```', 'y', '````' })
  ok(H.notified(checked, 'too short to close'), 'a fence too short to close is reported')

  checked = check_fences({ 'no fences at all' })
  ok(H.notified(checked, 'No unmatched'), 'a buffer without fences is clean')

  checked = check_fences({ '~~~', 'x', '~~~' })
  ok(H.notified(checked, 'No unmatched'), 'tilde fences are understood too')

  -- ----------------------------------------------------- scheme commands

  local schemes = require('color_my_ascii.commands.schemes')
  local names = schemes.get_scheme_names()
  ok(vim.tbl_contains(names, 'nord'), 'the command module knows the registered schemes')
  ok(schemes.get_scheme_names() ~= names, 'and hands back a copy each time')
  eq(
    #names,
    #require('color_my_ascii.scheme_loader').get_available_schemes(),
    'sourced from the loader, not a second list'
  )

  seen = H.capture_notify(function()
    schemes.list_schemes()
  end)
  ok(H.notified(seen, 'Available Color Schemes'), 'list_schemes reports the catalogue')
  ok(H.notified(seen, 'nord'), 'including each name')

  seen = H.capture_notify(function()
    schemes.switch_scheme('nord')
  end)
  ok(H.notified(seen, 'Switched to scheme: nord'), 'switch_scheme applies a known scheme')

  -- LUA-87 regression: a scheme switch must not silently reset options the
  -- user passed to their own setup() that the chosen scheme doesn't mention.
  config.setup({ fence_line_highlight = { enable = false }, comment_ascii = { enable = true } })
  seen = H.capture_notify(function()
    schemes.switch_scheme('nord')
  end)
  ok(H.notified(seen, 'Switched to scheme: nord'), 'switch_scheme still applies the scheme')
  eq(config.get().fence_line_highlight.enable, false, "an option nord.lua doesn't mention survives the switch")
  eq(config.get().comment_ascii.enable, true, 'so does another one')
  eq(config.get().enable_bracket_highlighting, false, "and the scheme's own keys still win")
  config.setup({})

  seen = H.capture_notify(function()
    schemes.switch_scheme('nosuchscheme')
  end)
  ok(H.notified(seen, 'Unknown scheme'), 'and reports an unknown one')
  ok(H.notified(seen, 'Available:'), 'listing what it could have been')

  seen = H.capture_notify(function()
    schemes.switch_scheme('')
  end)
  ok(H.notified(seen, 'Usage:'), 'an empty name gets the usage line')

  config.setup({})

  -- ------------------------------------------------------- fence helpers

  local util = require('color_my_ascii.commands.fence.util')

  eq(util.ext_for('lua'), 'lua', 'a known language maps to its extension')
  eq(util.ext_for('TypeScript'), 'ts', 'the tag is trimmed and lowercased')
  eq(util.ext_for('nosuchlang'), 'txt', 'an unknown tag falls back to txt')
  eq(util.ext_for(nil), 'txt', 'and so does no tag at all')

  config.setup({ fence_export = { ext_map = { zzlang = 'zz' } } })
  eq(util.ext_for('zzlang'), 'zz', 'a user ext_map entry is honoured')
  config.setup({})

  eq(util.filetype_for('py'), 'python', 'a short tag maps to its filetype')
  eq(util.filetype_for('lua'), 'lua', 'a tag that is already a filetype passes through')
  eq(util.filetype_for(nil), '', 'no tag maps to no filetype')

  local tags = util.lang_tags()
  ok(vim.tbl_contains(tags, 'lua'), 'the tag list covers the extension table')
  ok(vim.tbl_contains(tags, 'vimscript'), 'and the fence language map')
  local sorted_tags = vim.deepcopy(tags)
  table.sort(sorted_tags)
  eq(table.concat(tags, ','), table.concat(sorted_tags, ','), 'and is sorted')

  local unnamed = H.scratch('markdown', { 'x' })
  eq(util.cwd_for(unnamed), vim.fn.getcwd(), 'an unnamed buffer runs in the editor cwd')
  vim.api.nvim_buf_set_name(unnamed, vim.fn.tempname() .. '/doc.md')
  eq(
    util.cwd_for(unnamed),
    vim.fn.fnamemodify(vim.api.nvim_buf_get_name(unnamed), ':p:h'),
    'a named one in its own directory'
  )
  vim.api.nvim_buf_delete(unnamed, { force = true })

  -- current_block resolves from the cursor, fence lines included.
  local fbuf = H.scratch('markdown', { 'prose', '```lua', 'local x = 1', '```', 'more' })
  vim.api.nvim_set_current_buf(fbuf)
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  local cbuf, block = util.current_block()
  eq(cbuf, fbuf, 'current_block answers for the current buffer')
  eq(block.lang, 'lua', 'and finds the block under the cursor')
  eq(table.concat(util.content(cbuf, block), '\n'), 'local x = 1', 'content() returns the interior')
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  ok(util.current_block() ~= nil, 'the opening fence line counts as "under the cursor"')
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  local _, none = util.current_block()
  ok(none == nil, 'prose outside a block does not')

  -- ------------------------------------------------- :Fence run (no spawn)

  local run_mod = require('color_my_ascii.commands.fence.run')
  local fmt_mod = require('color_my_ascii.commands.fence.format')

  ---@param fn fun()
  ---@return { cmd: string[], opts: table, on_exit: fun(res: table) }[] calls
  ---@return { msg: string, level: integer|nil }[] messages
  local function without_spawning(fn)
    local calls = {}
    local original = vim.system
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.system = function(cmd, opts, on_exit)
      calls[#calls + 1] = { cmd = cmd, opts = opts, on_exit = on_exit }
      return { wait = function() end, kill = function() end, pid = -1 }
    end
    local msgs
    local run_ok, err = pcall(function()
      msgs = H.capture_notify(fn)
    end)
    vim.system = original
    if not run_ok then
      error(err, 0)
    end
    return calls, msgs
  end

  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  local calls
  calls, messages = without_spawning(function()
    run_mod.run({})
  end)
  eq(#calls, 0, ':Fence run with no block under the cursor spawns nothing')
  ok(H.notified(messages, 'no fenced block under the cursor'), 'and says so')

  local nolang = H.scratch('markdown', { '```zznolang', 'x', '```' })
  vim.api.nvim_set_current_buf(nolang)
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  calls, messages = without_spawning(function()
    run_mod.run({})
  end)
  eq(#calls, 0, 'a language with no runner spawns nothing')
  ok(H.notified(messages, 'no runner configured'), 'and points at the config key')
  vim.api.nvim_buf_delete(nolang, { force = true })

  vim.api.nvim_set_current_buf(fbuf)
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  calls = without_spawning(function()
    run_mod.run({})
  end)
  eq(#calls, 1, 'a lua block would spawn exactly one process')
  eq(calls[1].cmd[1], 'lua', 'with the built-in lua runner')
  eq(#calls[1].cmd, 2, 'and one argument')
  ok(calls[1].cmd[2]:sub(-4) == '.lua', "a temp file carrying the block's own extension")
  eq(vim.fn.filereadable(calls[1].cmd[2]), 1, 'which really holds the block content')
  eq(vim.fn.readfile(calls[1].cmd[2])[1], 'local x = 1', 'verbatim')
  eq(calls[1].opts.cwd, util.cwd_for(fbuf), 'and an explicit cwd resolved from the buffer')
  vim.fn.delete(calls[1].cmd[2])

  -- The completion callback renders stdout, stderr and the exit code into a
  -- scratch split.
  local windows_before = #vim.api.nvim_list_wins()
  calls[1].on_exit({ stdout = 'hello\n', stderr = 'oops\n', code = 3 })
  vim.wait(200, function()
    return #vim.api.nvim_list_wins() > windows_before
  end)
  local out_lines = vim.api.nvim_buf_get_lines(vim.api.nvim_get_current_buf(), 0, -1, false)
  eq(out_lines[1], 'hello', 'stdout is shown')
  ok(vim.tbl_contains(out_lines, '─── stderr ───'), 'stderr gets its own separator')
  ok(vim.tbl_contains(out_lines, 'oops'), 'and is shown below it')
  eq(out_lines[#out_lines], '[lua · exit 3]', 'the exit code is the last line')
  vim.cmd('close')

  -- A user-declared runner replaces the built-in one, string form included.
  config.setup({ fence_run = { runners = { lua = { 'zzrunner', '--flag' } } } })
  vim.api.nvim_set_current_buf(fbuf)
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  calls = without_spawning(function()
    run_mod.run({})
  end)
  eq(calls[1].cmd[1], 'zzrunner', 'a configured runner wins over the built-in')
  eq(calls[1].cmd[2], '--flag', 'keeping its arguments')
  vim.fn.delete(calls[1].cmd[3])

  config.setup({ fence_run = { runners = { lua = 'zzrunner --split-me' } } })
  calls = without_spawning(function()
    run_mod.run({})
  end)
  eq(calls[1].cmd[1], 'zzrunner', 'a string runner is split on whitespace')
  eq(calls[1].cmd[2], '--split-me', 'into separate argv entries')
  vim.fn.delete(calls[1].cmd[3])
  config.setup({})

  -- ---------------------------------------------- :Fence format (no spawn)

  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  calls, messages = without_spawning(function()
    fmt_mod.run({})
  end)
  eq(#calls, 0, ':Fence format with no block spawns nothing')
  ok(H.notified(messages, 'no fenced block under the cursor'), 'and says so')

  local unformattable = H.scratch('markdown', { '```zznolang', 'x', '```' })
  vim.api.nvim_set_current_buf(unformattable)
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  calls, messages = without_spawning(function()
    fmt_mod.run({})
  end)
  eq(#calls, 0, 'a language with no formatter spawns nothing')
  ok(H.notified(messages, 'no formatter configured'), 'and points at the config key')
  vim.api.nvim_buf_delete(unformattable, { force = true })

  vim.api.nvim_set_current_buf(fbuf)
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  calls = without_spawning(function()
    fmt_mod.run({})
  end)
  eq(#calls, 1, 'a lua block would spawn the configured formatter')
  eq(calls[1].cmd[1], 'stylua', 'the built-in lua formatter')
  eq(calls[1].opts.stdin, 'local x = 1', 'fed the block interior on stdin')
  eq(calls[1].opts.cwd, util.cwd_for(fbuf), 'with an explicit cwd')

  local replaced = false
  calls[1].on_exit({ stdout = 'local x = 2\nlocal y = 3\n', stderr = '', code = 0 })
  vim.wait(200, function()
    replaced = vim.api.nvim_buf_get_lines(fbuf, 2, 3, false)[1] == 'local x = 2'
    return replaced
  end)
  ok(replaced, "a clean exit replaces the interior with the formatter's output")
  eq(vim.api.nvim_buf_get_lines(fbuf, 3, 4, false)[1], 'local y = 3', 'including added lines')
  eq(vim.api.nvim_buf_get_lines(fbuf, 4, 5, false)[1], '```', 'and the closing fence moves down with it')

  -- A non-zero exit leaves the buffer untouched and reports the stderr.
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  calls = without_spawning(function()
    fmt_mod.run({})
  end)
  local before_fail = vim.api.nvim_buf_get_lines(fbuf, 0, -1, false)
  local failure = H.capture_notify(function()
    calls[1].on_exit({ stdout = '', stderr = 'syntax error', code = 1 })
    vim.wait(100, function()
      return false
    end)
  end)
  ok(H.notified(failure, 'formatter failed'), 'a non-zero exit is reported')
  eq(
    table.concat(vim.api.nvim_buf_get_lines(fbuf, 0, -1, false), '|'),
    table.concat(before_fail, '|'),
    'and the buffer is left exactly as it was'
  )

  -- ERR-30 regression: an edit made inside the block between spawn and the
  -- formatter's callback must not be silently overwritten by output computed
  -- from the pre-edit text -- the position-tracking extmarks only defend
  -- against lines shifting, not against the interior itself changing.
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  calls = without_spawning(function()
    fmt_mod.run({})
  end)
  eq(calls[1].opts.stdin, 'local x = 2\nlocal y = 3', 'formatter spawned on the current interior')
  vim.api.nvim_buf_set_lines(fbuf, 2, 3, false, { 'local x = 999 -- edited mid-format' })
  local stale = H.capture_notify(function()
    calls[1].on_exit({ stdout = 'local x = formatted\nlocal y = formatted\n', stderr = '', code = 0 })
    vim.wait(100, function()
      return false
    end)
  end)
  ok(
    H.notified(stale, 'block content changed while formatting'),
    'a mid-flight edit is reported, not silently replaced'
  )
  eq(
    vim.api.nvim_buf_get_lines(fbuf, 2, 3, false)[1],
    'local x = 999 -- edited mid-format',
    'the buffer keeps the edit made while the formatter was running'
  )

  vim.api.nvim_buf_delete(fbuf, { force = true })
  config.setup({})
end
