-- docs/TESTS/config_languages_spec.lua — config.languages extension point.
---@diagnostic disable: missing-fields

return function(H)
  local eq, ok = H.eq, H.ok
  local config = require('color_my_ascii.config')

  -- valid custom language: merged into keywords, participates in lookups
  do
    config.setup({
      languages = {
        mylang = { words = { 'foo', 'bar' }, hl = 'Function', unique_words = { 'foo' } },
      },
    })
    local c = config.get()
    ok(c.keywords.mylang ~= nil, 'custom language merged into keywords')
    ok(c.keywords.lua ~= nil, 'built-in languages still present')
    eq(config.get_unique_language('foo'), 'mylang', 'unique-keyword lookup picks up the custom language')
    local langs = config.get_keyword_languages('foo')
    ok(langs ~= nil and #langs == 1 and langs[1].language == 'mylang', 'keyword lookup picks up the custom language')
  end

  -- invalid entry: skipped, doesn't break lookup construction or other entries
  do
    config.setup({
      languages = {
        mylang = { words = { 'foo' }, hl = 'Function' },
        badlang = { hl = 'Function' }, -- missing `words` -> invalid
      },
    })
    local c = config.get()
    ok(c.keywords.mylang ~= nil, 'valid sibling entry still merged despite an invalid one')
    ok(c.keywords.badlang == nil, 'invalid entry (missing words) is skipped')
  end

  -- a custom language can override a built-in one by reusing its name
  do
    config.setup({
      languages = {
        lua = { words = { 'override_word' }, hl = 'Special' },
      },
    })
    local c = config.get()
    eq(c.keywords.lua.hl, 'Special', 'custom entry overrides the built-in language of the same name')
    eq(#c.keywords.lua.words, 1, 'override replaces (not merges) the built-in word list')
  end

  config.setup({})
end
