-- TESTS/language_detector_spec.lua — which language a block is highlighted as.
--
-- The detector picks the keyword table a block is painted with, so getting it
-- wrong is silent: the block still highlights, just with another language's
-- keywords. Four strategies in a fixed priority order, each checked on its own
-- and then against the one below it.

return function(H)
  local eq, ok = H.eq, H.ok
  local config = require('color_my_ascii.config')
  local detector = require('color_my_ascii.language_detector')

  ---@param lines string[]
  ---@param fence_line string
  ---@param ft? string
  ---@return string|nil
  local function detect(lines, fence_line, ft)
    local buf = H.scratch(ft or 'markdown', {})
    local result = detector.detect_language(buf, { lines = lines }, fence_line)
    vim.api.nvim_buf_delete(buf, { force = true })
    return result
  end

  config.setup({})

  -- ------------------------------------------- strategy 1: explicit marker

  eq(detect({}, '```ascii-lua'), 'lua', 'the ascii-<lang> form')
  eq(detect({}, '```ascii lua'), 'lua', 'the "ascii <lang>" form')
  eq(detect({}, '```ascii:lua'), 'lua', 'the ascii:<lang> form')
  eq(detect({}, '~~~ascii-python'), 'python', 'tilde fences are read the same way')
  eq(detect({}, '```ascii-c_sharp'), 'c_sharp', 'underscores belong to the tag')

  -- A plain fence tag resolves through fence_language_map, which is what makes
  -- ```vim / ```vimscript / ```viml all reach the same language file.
  eq(detect({}, '```vim'), 'vim', 'a mapped fence tag resolves')
  eq(detect({}, '```vimscript'), 'vim', 'including its aliases')
  eq(detect({}, '```rs'), 'rust', 'and short forms')
  ok(detect({}, '```nosuchtag') == nil, 'an unmapped tag does not resolve here')

  -- The map is a merge target, so a user entry extends it. (It cannot be
  -- *emptied* through `setup()`: the merge is a deep extend, and an empty
  -- table removes nothing -- noted here so the next reader does not try.)
  config.setup({ fence_language_map = { zzcustomtag = 'lua' } })
  eq(detect({}, '```zzcustomtag'), 'lua', 'a user-added fence tag resolves')
  eq(detect({}, '```vim'), 'vim', 'without displacing the built-in entries')
  config.setup({})

  -- ------------------------------------------ strategy 2: content heuristic
  --
  -- Scored per language: a *unique* keyword counts towards both counters, a
  -- shared one only towards the tiebreaker, and a language is only returned
  -- once it clears `language_detection_threshold` unique hits.

  config.setup({
    enable_language_detection = true,
    language_detection_threshold = 2,
    languages = {
      zzalpha = { words = { 'zzshared' }, unique_words = { 'zzalpha1', 'zzalpha2' }, hl = 'Keyword' },
      zzbeta = { words = { 'zzshared' }, unique_words = { 'zzbeta1' }, hl = 'Identifier' },
    },
  })

  eq(detect({ 'zzalpha1 zzalpha2' }, '```ascii'), 'zzalpha', 'two unique keywords clear a threshold of two')
  ok(detect({ 'zzalpha1' }, '```ascii') == nil, 'one unique keyword does not')
  ok(detect({ 'zzshared zzshared' }, '```ascii') == nil, 'shared keywords never clear the threshold')

  config.setup({
    enable_language_detection = true,
    language_detection_threshold = 1,
    languages = {
      zzalpha = { words = { 'zzshared' }, unique_words = { 'zzalpha1', 'zzalpha2' }, hl = 'Keyword' },
      zzbeta = { words = { 'zzshared' }, unique_words = { 'zzbeta1' }, hl = 'Identifier' },
    },
  })
  eq(detect({ 'zzbeta1' }, '```ascii'), 'zzbeta', 'a lowered threshold admits a single hit')
  eq(detect({ 'zzalpha1 zzalpha2 zzbeta1' }, '```ascii'), 'zzalpha', 'the language with more unique hits wins')

  config.setup({
    enable_language_detection = false,
    languages = { zzalpha = { words = {}, unique_words = { 'zzalpha1' }, hl = 'Keyword' } },
  })
  ok(detect({ 'zzalpha1' }, '```ascii') == nil, 'the flag switches content detection off')

  -- ------------------------------------------- strategy 3: buffer filetype

  config.setup({ enable_language_detection = false })
  eq(detect({}, '```ascii', 'lua'), 'lua', 'a lua buffer identifies the block as lua')
  eq(detect({}, '```ascii', 'sh'), 'bash', 'filetype aliases are mapped (sh -> bash)')
  eq(detect({}, '```ascii', 'zsh'), 'bash', 'and so is zsh')
  eq(detect({}, '```ascii', 'cs'), 'csharp', 'cs -> csharp')
  ok(detect({}, '```ascii', 'markdown') == nil, 'a filetype with no language file resolves to nil')
  ok(detect({}, '```ascii', 'text') == nil, 'and so does an unmapped one')

  -- A filetype that maps to a language which is not actually loaded is not
  -- returned -- the mapping is verified against the available languages. Every
  -- entry of the filetype map does have a language file today, so the only way
  -- to reach that branch is to make the availability list answer empty.
  local real_available = config.get_available_languages
  config.get_available_languages = function()
    return {}
  end
  local unavailable_ok, unavailable_err = pcall(function()
    ok(detect({}, '```ascii', 'lua') == nil, 'a mapped language that is not loaded is not returned')
  end)
  config.get_available_languages = real_available
  if not unavailable_ok then
    error(unavailable_err, 0)
  end
  config.setup({})

  -- ------------------------------------------------------ priority order

  config.setup({
    enable_language_detection = true,
    language_detection_threshold = 1,
    languages = { zzalpha = { words = {}, unique_words = { 'zzalpha1' }, hl = 'Keyword' } },
  })

  eq(detect({ 'zzalpha1' }, '```ascii-python', 'lua'), 'python', 'the explicit marker beats content and filetype')
  eq(detect({ 'zzalpha1' }, '```ascii', 'lua'), 'zzalpha', 'content beats the buffer filetype')
  eq(detect({ 'nothing here' }, '```ascii', 'lua'), 'lua', 'the buffer filetype is the last resort')
  ok(detect({ 'nothing here' }, '```ascii', 'markdown') == nil, 'and nil means "use every language"')

  config.setup({})
end
