-- TESTS/debounce_manager_spec.lua — tiered adaptive delay + lib.nvim.debounce delegation.

return function(H)
  local eq, ok = H.eq, H.ok
  local debounce_manager = require('color_my_ascii.debounce_manager')

  debounce_manager.configure({
    small_file_threshold = 10,
    medium_file_threshold = 20,
    small_delay = 10,
    medium_delay = 20,
    large_delay = 30,
    min_delay = 10,
    max_delay = 30,
  })

  -- ---- calculate_delay tiers, via get_delay -------------------------------
  do
    local small_buf = H.scratch(nil, { 'line' })
    eq(debounce_manager.get_delay(small_buf), 10, 'get_delay: small file -> small_delay')
    vim.api.nvim_buf_delete(small_buf, { force = true })

    local lines = {}
    for i = 1, 15 do
      lines[i] = 'line ' .. i
    end
    local medium_buf = H.scratch(nil, lines)
    eq(debounce_manager.get_delay(medium_buf), 20, 'get_delay: medium file -> medium_delay')
    vim.api.nvim_buf_delete(medium_buf, { force = true })
  end

  -- ---- debounce / is_pending / cancel --------------------------------------
  do
    local buf = H.scratch(nil, { 'line' })
    local calls = 0

    ok(not debounce_manager.is_pending(buf), 'is_pending: nothing scheduled yet')

    debounce_manager.debounce(buf, function()
      calls = calls + 1
    end)
    ok(debounce_manager.is_pending(buf), 'is_pending: true right after scheduling')

    local cancelled = debounce_manager.cancel(buf)
    ok(cancelled, 'cancel: reports true when a call was pending')
    ok(not debounce_manager.is_pending(buf), 'is_pending: false after cancel')

    vim.wait(50)
    eq(calls, 0, 'cancel: prevents the debounced function from firing')

    vim.api.nvim_buf_delete(buf, { force = true })
  end

  -- ---- debounce fires once with a fixed delay ------------------------------
  do
    local buf = H.scratch(nil, { 'line' })
    local calls = 0

    debounce_manager.debounce(buf, function()
      calls = calls + 1
    end, 15)
    debounce_manager.debounce(buf, function()
      calls = calls + 1
    end, 15) -- supersedes the first
    vim.wait(200, function()
      return calls > 0
    end)

    eq(calls, 1, 'debounce: rapid re-scheduling still fires exactly once')
    ok(not debounce_manager.is_pending(buf), 'is_pending: false once fired')

    vim.api.nvim_buf_delete(buf, { force = true })
  end

  -- ---- cancel_all / get_pending_count ---------------------------------------
  do
    local buf1 = H.scratch(nil, { 'a' })
    local buf2 = H.scratch(nil, { 'b' })

    debounce_manager.debounce(buf1, function() end, 500)
    debounce_manager.debounce(buf2, function() end, 500)
    eq(debounce_manager.get_pending_count(), 2, 'get_pending_count: two buffers pending')

    local n = debounce_manager.cancel_all()
    ok(n >= 2, 'cancel_all: cancels at least the two we scheduled')
    eq(debounce_manager.get_pending_count(), 0, 'get_pending_count: zero after cancel_all')

    vim.api.nvim_buf_delete(buf1, { force = true })
    vim.api.nvim_buf_delete(buf2, { force = true })
  end

  -- ---- get_config round-trips what configure set ----------------------------
  do
    local cfg = debounce_manager.get_config()
    eq(cfg.small_delay, 10, 'get_config: reflects configure()')
    eq(cfg.max_delay, 30, 'get_config: reflects configure()')
  end
end
