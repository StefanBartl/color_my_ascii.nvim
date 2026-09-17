-- TESTS/scheme_loader_spec.lua — the scheme registry, and the shape of the
-- schemes it registers.
--
-- `scheme_loader` is a name-to-module registry with four failure modes, all of
-- which have to be *reported* rather than raised: `config.setup({ scheme =
-- ... })` calls it with whatever the user typed. The bundled schemes
-- themselves are declarative data, so they are spot-checked for shape rather
-- than entry by entry.

return function(H)
  local eq, ok = H.eq, H.ok
  local loader = require('color_my_ascii.scheme_loader')

  -- ------------------------------------------------------------- the registry

  local names = loader.get_available_schemes()
  ok(#names >= 10, 'every bundled scheme is registered')
  ok(vim.tbl_contains(names, 'default'), 'including the default one')
  local sorted = vim.deepcopy(names)
  table.sort(sorted)
  eq(table.concat(names, ','), table.concat(sorted, ','), 'the list is sorted')
  ok(loader.get_available_schemes() ~= names, 'and is a fresh table each call')

  ok(loader.scheme_exists('nord'), 'a known scheme exists')
  ok(loader.scheme_exists('NORD'), 'the check is case-insensitive')
  ok(not loader.scheme_exists('nosuchscheme'), 'an unknown one does not')

  -- --------------------------------------------------------------- loading

  local cfg, err = loader.load_scheme('matrix')
  ok(cfg ~= nil, 'a named scheme loads')
  ok(err == nil, 'without an error')
  eq(cfg, require('color_my_ascii.schemes.matrix'), 'and is the module itself')

  eq(loader.load_scheme('MATRIX'), cfg, 'the name is lowercased before lookup')

  local passthrough = { default_hl = 'ZzInline' }
  eq(loader.load_scheme(passthrough), passthrough, 'a table is handed straight back')

  cfg, err = loader.load_scheme('nosuchscheme')
  ok(cfg == nil, 'an unknown name does not load')
  ok(err:find('Unknown scheme', 1, true) ~= nil, 'and says so')
  ok(err:find('matrix', 1, true) ~= nil, 'listing what is available instead')

  cfg, err = loader.load_scheme(42)
  ok(cfg == nil, 'a number is not a scheme')
  ok(err:find('must be a string or table', 1, true) ~= nil, 'and the message says which types are')

  cfg, err = loader.load_scheme(nil)
  ok(cfg == nil, 'nil is reported, not raised')
  ok(err ~= nil, 'with an error message')

  -- A scheme module that fails to load, and one that returns something that is
  -- not a configuration table: both are registry entries going wrong, so they
  -- are simulated at the require seam rather than by shipping a broken file.
  local PATH = 'color_my_ascii.schemes.matrix'
  local saved = package.loaded[PATH]

  package.loaded[PATH] = nil
  package.preload[PATH] = function()
    error('synthetic load failure')
  end
  cfg, err = loader.load_scheme('matrix')
  package.preload[PATH] = nil
  package.loaded[PATH] = saved
  ok(cfg == nil, 'a scheme module that raises does not load')
  ok(err:find('Failed to load scheme', 1, true) ~= nil, 'and is reported as such')

  package.loaded[PATH] = 'not a table'
  cfg, err = loader.load_scheme('matrix')
  package.loaded[PATH] = saved
  ok(cfg == nil, 'a scheme module returning a non-table does not load')
  ok(err:find('did not return a configuration table', 1, true) ~= nil, 'and is reported as such')

  eq(loader.load_scheme('matrix'), saved, 'the registry is unharmed afterwards')

  -- ------------------------------------------------- the bundled schemes' shape
  --
  -- Declarative colour data: what matters is that every registered name really
  -- resolves to a table whose values are the kinds of thing `config.setup()`
  -- merges, not that any particular colour is any particular hex string.

  for _, name in ipairs(names) do
    local scheme = loader.load_scheme(name)
    eq(type(scheme), 'table', name .. ' loads as a table')
    if scheme.overrides ~= nil then
      eq(type(scheme.overrides), 'table', name .. '.overrides is a table')
      for char, hl in pairs(scheme.overrides) do
        eq(type(char), 'string', name .. ': override keys are characters')
        ok(type(hl) == 'string' or type(hl) == 'table', name .. ': override values are a group name or attrs')
      end
    end
    if scheme.groups ~= nil then
      eq(type(scheme.groups), 'table', name .. '.groups is a table')
    end
    for _, flag in ipairs({
      'enable_keywords',
      'enable_function_names',
      'enable_bracket_highlighting',
      'enable_inline_code',
    }) do
      if scheme[flag] ~= nil then
        eq(type(scheme[flag]), 'boolean', ('%s.%s is a boolean'):format(name, flag))
      end
    end
  end

  -- Every scheme has to survive being merged into the real configuration --
  -- that is the only thing the registry exists for.
  local config = require('color_my_ascii.config')
  for _, name in ipairs(names) do
    ok(pcall(config.setup, { scheme = name }), name .. ' merges into the configuration')
  end
  config.setup({})
end
