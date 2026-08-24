-- TESTS/toggle_buffer_spec.lua — color_my_ascii.toggle_buffer
--
-- `toggle()` has always been global: one `state.enabled` flag applied across
-- every managed buffer. `toggle_buffer()` is the per-buffer case, which had no
-- expression before. It reuses the existing `state.buffers` model — a buffer
-- is highlighted when it is *managed* — rather than adding a second one, so
-- what these checks pin is that the two switches stay independent.

return function(H)
  local cma = require('color_my_ascii')
  cma.setup({})

  ---A real, listed buffer with ASCII-art-ish content.
  ---@return integer
  local function fixture()
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { '-- +---+', '-- | x |', '-- +---+' })
    vim.bo[buf].filetype = 'lua'
    return buf
  end

  local buf = fixture()
  vim.api.nvim_set_current_buf(buf)
  cma.setup_buffer(buf)

  H.eq(cma.get_state().buffers[buf], true, 'setup_buffer marks the buffer managed')

  -- ------------------------------------------------------------ toggling off

  H.eq(cma.toggle_buffer(buf), false, 'toggling a managed buffer turns it off')
  H.eq(cma.get_state().buffers[buf], nil, 'and unmarks it as managed')
  H.eq(cma.get_state().enabled, true, 'without touching the global switch')

  -- ------------------------------------------------------------- toggling on

  H.eq(cma.toggle_buffer(buf), true, 'toggling it again turns it back on')
  H.eq(cma.get_state().buffers[buf], true, 'and marks it managed again')

  -- --------------------------------------------------- the two are independent
  --
  -- A second buffer must be unaffected by the first one's per-buffer state:
  -- that is the whole point of having a per-buffer switch at all.

  local other = fixture()
  cma.setup_buffer(other)
  cma.toggle_buffer(buf)
  H.eq(cma.get_state().buffers[buf], nil, 'one buffer off')
  H.eq(cma.get_state().buffers[other], true, '...leaves the other one on')
  cma.toggle_buffer(buf)

  -- ------------------------------------------------- global switch wins
  --
  -- Enabling a single buffer while the plugin is globally off would mark it
  -- managed and then highlight nothing, which reads as a bug rather than as a
  -- setting. It refuses instead.

  cma.toggle_buffer(buf) -- off
  H.eq(cma.get_state().buffers[buf], nil, 'buffer is off before the global toggle')

  cma.toggle()
  H.eq(cma.get_state().enabled, false, 'plugin is globally disabled')

  H.eq(cma.toggle_buffer(buf), false, 'enabling one buffer while globally off is refused')
  H.eq(cma.get_state().buffers[buf], nil, 'and it stays unmanaged')

  cma.toggle()
  H.eq(cma.get_state().enabled, true, 'plugin is globally enabled again')

  -- ------------------------------------------------------- invalid buffer
  --
  -- Reported rather than raised: this is reachable straight from a keymap.

  local dead = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_delete(dead, { force = true })
  local ok = pcall(cma.toggle_buffer, dead)
  H.ok(ok, 'an invalid buffer is reported, not raised')
end
