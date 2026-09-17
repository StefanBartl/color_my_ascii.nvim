-- TESTS/cache_manager_spec.lua — the per-buffer parse cache.
--
-- Every highlight pass asks this module first, so a wrong answer here is not a
-- crash but stale colours: an entry kept past a buffer edit paints yesterday's
-- block ranges onto today's lines. The four invalidation criteria (timeout,
-- changedtick, line count, dead buffer) are therefore each checked on their
-- own, against real buffers.

return function(H)
  local eq, ok = H.eq, H.ok
  local cache = require('color_my_ascii.cache_manager')

  ---@return integer
  local function fixture()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'a', 'b' })
    return buf
  end

  local BLOCKS = { { start_line = 0, end_line = 1, lines = { 'a' } } }
  local INLINE = {}

  cache.clear_all()
  cache.reset_stats()
  cache.configure({ timeout = 5000, max_size = 50, enable_stats = true })

  -- ------------------------------------------------------------- configure

  cache.configure('not a table')
  eq(cache.get_config().timeout, 5000, 'a non-table argument is ignored')
  cache.configure({ timeout = -1, max_size = 0, enable_stats = 'yes' })
  local cfg = cache.get_config()
  eq(cfg.timeout, 5000, 'a non-positive timeout is rejected')
  eq(cfg.max_size, 50, 'a non-positive max_size too')
  eq(cfg.enable_stats, true, 'and a non-boolean enable_stats')
  ok(cache.get_config() ~= cache.get_config(), 'get_config hands back a copy, not the live table')

  -- -------------------------------------------------------------- get / set

  eq(select(3, cache.get('not a number')), false, 'a non-numeric bufnr is a miss, not an error')
  eq(select(3, cache.get(-1)), false, 'a negative bufnr too')

  local buf = fixture()
  eq(select(3, cache.get(buf)), false, 'an unknown buffer is a miss')

  eq(cache.set(buf, BLOCKS, INLINE), true, 'a valid entry is stored')
  local blocks, inline, hit = cache.get(buf)
  eq(hit, true, 'and read back as a hit')
  ok(blocks == BLOCKS, 'with the very blocks that were stored')
  ok(inline == INLINE, 'and the inline codes')
  eq(cache.get_size(), 1, 'the cache holds one buffer')

  eq(cache.set('x', BLOCKS, INLINE), false, 'a non-numeric bufnr is refused')
  eq(cache.set(buf, 'not a table', INLINE), false, 'non-table blocks are refused')
  eq(cache.set(buf, BLOCKS, 'not a table'), false, 'non-table inline codes too')

  local dead = fixture()
  vim.api.nvim_buf_delete(dead, { force = true })
  eq(cache.set(dead, BLOCKS, INLINE), false, 'a dead buffer has no metadata, so nothing is cached')

  -- ------------------------------------------------------- invalidation rules

  -- 1. content changed (changedtick)
  vim.api.nvim_buf_set_lines(buf, 0, 1, false, { 'changed' })
  eq(select(3, cache.get(buf)), false, 'an edit invalidates the entry')
  eq(cache.get_size(), 0, 'and drops it from the cache')

  -- 2. line count changed without a matching changedtick is covered by the
  --    same check; what matters is that a shrunken buffer is never served.
  cache.set(buf, BLOCKS, INLINE)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'only one line' })
  eq(select(3, cache.get(buf)), false, 'a changed line count invalidates too')

  -- 3. dead buffer
  local doomed = fixture()
  cache.set(doomed, BLOCKS, INLINE)
  vim.api.nvim_buf_delete(doomed, { force = true })
  eq(select(3, cache.get(doomed)), false, 'a deleted buffer invalidates its entry')

  -- 4. timeout
  cache.configure({ timeout = 1 })
  cache.set(buf, BLOCKS, INLINE)
  vim.uv.sleep(5)
  vim.uv.update_time() -- uv caches the loop time; without this "now" never moves
  eq(select(3, cache.get(buf)), false, 'an entry older than the timeout is invalidated')
  cache.configure({ timeout = 5000 })

  -- ------------------------------------------------------------- eviction

  cache.clear_all()
  cache.configure({ max_size = 2 })
  local a, b, c = fixture(), fixture(), fixture()
  cache.set(a, BLOCKS, INLINE)
  vim.uv.sleep(2)
  vim.uv.update_time()
  cache.set(b, BLOCKS, INLINE)
  vim.uv.sleep(2)
  vim.uv.update_time()
  cache.set(c, BLOCKS, INLINE)
  ok(cache.get_size() <= 2, 'the cache never grows past max_size')
  eq(select(3, cache.get(a)), false, 'the oldest entry is the one evicted')
  eq(select(3, cache.get(c)), true, 'the newest one survives')
  cache.configure({ max_size = 50 })

  -- ------------------------------------------------------ invalidate / clear

  eq(cache.invalidate('x'), false, 'invalidating a non-numeric bufnr is refused')
  eq(cache.invalidate(a), false, 'invalidating a buffer with no entry answers false')
  cache.set(a, BLOCKS, INLINE)
  eq(cache.invalidate(a), true, 'invalidating a cached buffer answers true')

  cache.clear_all()
  cache.set(a, BLOCKS, INLINE)
  cache.set(b, BLOCKS, INLINE)
  eq(cache.clear_all(), 2, 'clear_all reports how many entries it dropped')
  eq(cache.get_size(), 0, 'and leaves the cache empty')
  eq(cache.clear_all(), 0, 'clearing an empty cache reports zero')

  -- ---------------------------------------------------------------- statistics

  cache.reset_stats()
  eq(cache.get_hit_rate(), 0, 'the hit rate of an empty history is 0, not a division by zero')

  cache.set(a, BLOCKS, INLINE)
  cache.get(a) -- hit
  cache.get(b) -- miss
  local stats = cache.get_stats()
  eq(stats.hits, 1, 'hits are counted')
  eq(stats.misses, 1, 'and misses')
  eq(cache.get_hit_rate(), 50, 'the hit rate is a percentage')
  ok(cache.get_stats() ~= cache.get_stats(), 'get_stats hands back a copy')

  cache.reset_stats()
  eq(cache.get_stats().hits, 0, 'reset_stats zeroes the counters')

  -- With statistics off nothing is counted at all -- the flag is not just a
  -- reporting switch.
  cache.configure({ enable_stats = false })
  cache.clear_all()
  cache.set(a, BLOCKS, INLINE)
  cache.get(a)
  cache.get(b)
  eq(cache.get_stats().hits, 0, 'enable_stats = false stops counting hits')
  eq(cache.get_stats().misses, 0, 'and misses')
  cache.configure({ enable_stats = true })

  -- -------------------------------------------------------------- cleanup

  cache.clear_all()
  local live = fixture()
  local gone = fixture()
  cache.set(live, BLOCKS, INLINE)
  cache.set(gone, BLOCKS, INLINE)
  vim.api.nvim_buf_delete(gone, { force = true })
  eq(cache.cleanup(), 1, 'cleanup reaps the entry of a deleted buffer')
  eq(cache.get_size(), 1, 'and leaves the live one alone')

  cache.configure({ timeout = 1 })
  vim.uv.sleep(5)
  vim.uv.update_time()
  eq(cache.cleanup(), 1, 'and reaps expired entries as well')
  eq(cache.get_size(), 0, 'leaving the cache empty')
  cache.configure({ timeout = 5000 })
  eq(cache.cleanup(), 0, 'an empty cache needs no cleaning')

  -- ------------------------------------------------------- the cleanup timer
  --
  -- `setup_auto_cleanup` is called from `M.setup()`, which the plugin/
  -- bootstrap runs once and the user's own config runs again -- so a second
  -- call must replace the first timer rather than leave two of them ticking.

  local first = cache.setup_auto_cleanup(60000)
  ok(first ~= nil, 'a timer is created')
  local second = cache.setup_auto_cleanup(60000)
  ok(second ~= nil, 'a second call creates a new one')
  ok(second ~= first, 'a different handle')
  ok(first:is_closing(), 'and the first one is closed, not leaked')

  -- Leave the module in the state the plugin's own setup() would.
  cache.setup_auto_cleanup(30000)
  cache.configure({ timeout = 5000, max_size = 50, enable_stats = false })
  cache.clear_all()
  cache.reset_stats()

  for _, b2 in ipairs({ buf, a, b, c, live }) do
    if vim.api.nvim_buf_is_valid(b2) then
      vim.api.nvim_buf_delete(b2, { force = true })
    end
  end
end
