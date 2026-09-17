-- TESTS/data_tables_spec.lua — the declarative data the plugin ships, and the
-- `plugin/` bootstrap that loads it.
--
-- `languages/*.lua` (31 files) and `groups/*.lua` (5) are keyword and character
-- tables. Asserting individual entries would be transcription, not testing --
-- so what is checked is the contract `config/init.lua`'s loaders enforce
-- before accepting a file, applied to every file that ships, plus the
-- properties a wrong entry would break silently (a duplicated keyword, a
-- character claimed by two groups, a `unique_words` entry that is not unique
-- at all).

return function(H)
  local eq, ok = H.eq, H.ok

  local root = debug.getinfo(1, 'S').source:sub(2):match('(.*[/\\])') .. '../lua/color_my_ascii/'

  ---@param subdir string
  ---@return string[] names
  local function module_names(subdir)
    local names = {}
    for _, path in ipairs(vim.fn.globpath(root .. subdir, '*.lua', false, true)) do
      names[#names + 1] = vim.fn.fnamemodify(path, ':t:r')
    end
    table.sort(names)
    return names
  end

  -- -------------------------------------------------------------- languages

  local languages = module_names('languages')
  ok(#languages >= 30, 'the bundled language files are all there')

  local duplicated, unique_clashes, unique_unlisted = {}, {}, {}
  local claimed_unique = {}

  for _, name in ipairs(languages) do
    local mod = require('color_my_ascii.languages.' .. name)
    local label = 'languages/' .. name

    -- Exactly the shape `load_languages()` validates before accepting a file.
    eq(type(mod), 'table', label .. ' returns a table')
    eq(type(mod.words), 'table', label .. '.words is a table')
    ok(mod.hl ~= nil, label .. '.hl is set')
    ok(type(mod.hl) == 'string' or type(mod.hl) == 'table', label .. '.hl is a group name or an attribute table')
    ok(#mod.words > 0, label .. ' declares at least one keyword')

    local words = {}
    for _, word in ipairs(mod.words) do
      eq(type(word), 'string', label .. ': every keyword is a string')
      ok(word ~= '', label .. ': and non-empty')
      if words[word] then
        duplicated[#duplicated + 1] = name .. ':' .. word
      end
      words[word] = true
    end

    if mod.unique_words ~= nil then
      eq(type(mod.unique_words), 'table', label .. '.unique_words is a table')
      for _, word in ipairs(mod.unique_words) do
        eq(type(word), 'string', label .. ': every unique keyword is a string')
        if claimed_unique[word] then
          unique_clashes[#unique_clashes + 1] = ('%s (%s + %s)'):format(word, claimed_unique[word], name)
        end
        claimed_unique[word] = name
        if not words[word] then
          unique_unlisted[#unique_unlisted + 1] = name .. ':' .. word
        end
      end
    end
  end

  -- --------------------------------------------- FINDING: duplicate keywords
  --
  -- Twelve keywords are listed twice inside their own file. Harmless to the
  -- character lookup (a table key), but `tokenize_line` -> `keyword_lookup`
  -- then holds two identical entries, so the word is painted twice at each
  -- position and `detect_from_content` counts it twice towards that language's
  -- tiebreaker. Enumerated rather than asserted away, so a *new* duplicate is
  -- a failure while the known ones are on record.
  table.sort(duplicated)
  eq(
    table.concat(duplicated, ', '),
    'bash:unset, cpp:constexpr, cpp:decltype, llvm:label, llvm:uge, llvm:ugt, llvm:ule, llvm:ult, '
      .. 'lua:goto, typescript:default, vim:map, zig:volatile',
    'FINDING: exactly these keywords are declared twice in their own file'
  )

  -- --------------------------------------- regression: "unique" is not always
  --
  -- `build_unique_keyword_lookup` is a flat word -> language map, filled by
  -- iterating `pairs(config.keywords)`. Eight shipped words are claimed as
  -- `unique_words` by TWO languages, so which language each of them used to
  -- identify was decided by Lua's table iteration order -- i.e. not decided at
  -- all: a block containing `elif` came out as bash or as python depending on
  -- hash order, and the two paint with different highlight groups. A word two
  -- languages both claim identifies neither, so it is dropped from the lookup
  -- now; the ordinary keyword lists still count it.
  --
  -- The list itself is still pinned: a ninth collision should be a deliberate
  -- decision in the data, not a silent loss of one more detection hint.
  table.sort(unique_clashes)
  eq(
    table.concat(unique_clashes, ', '),
    'elif (bash + python), i128 (llvm + rust), isize (rust + zig), namespace (cpp + typescript), '
      .. 'readonly (bash + typescript), self (php + python), trait (rust + scala), usize (rust + zig)',
    'exactly these eight words are claimed as unique by two languages each'
  )
  local config_for_unique = require('color_my_ascii.config')
  config_for_unique.setup({})
  for _, clash in ipairs({ 'elif', 'self', 'namespace', 'readonly' }) do
    eq(
      config_for_unique.get_unique_language(clash),
      nil,
      ('"%s" identifies no language, rather than a hash-order one'):format(clash)
    )
  end
  -- A word only one language claims still resolves, so the shortcut works.
  ok(config_for_unique.get_unique_language('elseif') ~= nil, 'a genuinely unique word still resolves')

  -- ------------------------------- FINDING: unique words outside `words`
  --
  -- Two entries are declared unique to bash without being bash keywords at
  -- all, so they steer language *detection* while never being highlighted
  -- themselves.
  table.sort(unique_unlisted)
  eq(table.concat(unique_unlisted, ', '), 'bash:bash, bash:sh', 'FINDING: exactly these unique words are not keywords')

  -- Every language file is picked up by the loader, under its file name.
  local config = require('color_my_ascii.config')
  config.setup({})
  local loaded = config.get().keywords
  for _, name in ipairs(languages) do
    ok(loaded[name] ~= nil, 'languages/' .. name .. ' is loaded under its file name')
  end

  -- -------------------------------------------------------------- groups

  local groups = module_names('groups')
  ok(#groups >= 5, 'the bundled character groups are all there')

  local owner = {}
  for _, name in ipairs(groups) do
    local mod = require('color_my_ascii.groups.' .. name)
    local label = 'groups/' .. name

    -- Exactly the shape `load_groups()` validates.
    eq(type(mod), 'table', label .. ' returns a table')
    eq(type(mod.chars), 'string', label .. '.chars is a string')
    ok(mod.hl ~= nil, label .. '.hl is set')
    ok(#mod.chars > 0, label .. ' declares at least one character')

    for _, char in ipairs(vim.fn.split(mod.chars, '\\zs')) do
      -- The lookup is a flat character -> group map, so a character in two
      -- groups would silently resolve to whichever group is visited last --
      -- the same order-dependence the `unique_words` clashes above have. The
      -- five bundled groups are disjoint; this keeps them that way.
      ok(owner[char] == nil, ('%s: "%s" is also in groups/%s'):format(label, char, tostring(owner[char])))
      owner[char] = name
    end
  end

  local loaded_groups = config.get().groups
  for _, name in ipairs(groups) do
    ok(loaded_groups[name] ~= nil, 'groups/' .. name .. ' is loaded under its file name')
  end

  -- Every declared character really resolves through the lookup built from it.
  for char, group in pairs(owner) do
    local resolved = config.get_char_highlight(char)
    ok(resolved ~= nil, ('the lookup resolves "%s" (groups/%s)'):format(char, group))
  end

  -- ------------------------------------------------------ type-only modules
  --
  -- Pure `---@meta` annotation anchors: no runtime code, nothing to assert
  -- beyond "requiring them does not raise", which is what keeps a syntax error
  -- in them from surfacing only in someone's editor.

  ok(pcall(require, 'color_my_ascii.@types'), 'the shared type declarations load')
  ok(pcall(require, 'color_my_ascii.debug.@types'), 'and the debug ones')

  config.setup({})
end
