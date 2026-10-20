---@module 'color_my_ascii.config'
--- Configuration management for color_my_ascii.nvim plugin.
--- Handles user configuration, defaults, and provides access to settings.
--- Supports modular language and group definitions, custom highlights, dynamic highlight groups,
--- and simplified scheme loading via string identifiers.

local M = {}

local notify = require('lib.nvim.notify').create('[color_my_ascii]')
local fn = vim.fn

local DEFAULTS = require('color_my_ascii.config.DEFAULTS')

--- List the *.lua file names (bare, no directory) directly inside `path`.
---
--- `vim.fn.readdir` takes `path` as an actual filesystem path, not a glob
--- pattern, so a metacharacter in the plugin's own install path (`[`, `]`,
--- `*`, `?`, `{}`, a comma -- `globpath` also splits its {path} argument on
--- commas) can never be misread as pattern syntax the way it would be by
--- `vim.fn.glob`/`globpath` (XP-01).
---@internal
---@param path string
---@return boolean ok
---@return string[] names
local function list_lua_files(path)
  local ok, entries = pcall(fn.readdir, path)
  if not ok or type(entries) ~= 'table' then
    return false, {}
  end
  local out = {}
  for _, name in ipairs(entries) do
    if name:sub(-4) == '.lua' then
      out[#out + 1] = name
    end
  end
  return true, out
end

--- Cache for dynamically created highlight groups: name -> the attrs table
--- passed to nvim_set_hl, so the group can be re-applied verbatim later (see
--- M.reapply_custom_highlights).
---@type table<string, table>
local created_highlight_groups = {}

---@internal
--- What the schema inferred from `DEFAULTS` cannot say. `groups`/`keywords`
--- are filled with the bundled definitions and `languages`/`overrides`/
--- `fence_language_map` with the built-in tags, but all of them are
--- name-keyed extension points whose keys are the user's to choose. `keymaps`
--- is `false` by default and takes a table to enable and customize.
---@type table<string, string|table>
local SCHEMA = {
  groups = { 'table' },
  keywords = { 'table' },
  fence_language_map = { 'table' },
  keymaps = 'table|boolean',
  default_hl = 'string|table',
}

---@internal
--- Keys that are allowed but have no default (absent means off / inherit).
---@type table<string, string>
local OPTIONAL = {
  default_text_hl = 'string|table|false',
  cache = 'table',
  debounce = 'table',
  ['fence_line_highlight.open'] = 'string|table',
  ['fence_line_highlight.close'] = 'string|table',
  ['fence_content_highlight.preset'] = 'string',
  ['fence_content_highlight.hl'] = 'string|table',
}

---@internal
--- Degrade a numeric option of a layer to `default` when the value is not a
--- number, or clamp it into `[min, max]` when it is a number but out of
--- range (ERR-22): a known key with a wrong-typed or out-of-range value must
--- not reach the code that consumes it as-is. `language_detection_threshold`
--- feeds a numeric comparison in `language_detector.lua` and a `%d` format in
--- `commands/config.lua` -- a non-numeric value there raises on every ASCII
--- block and on `:ColorMyAscii show-config`, not just a cosmetic glitch.
--- `fence_*_highlight.right_pad`/`fence_content_highlight.amount` were
--- already clamped where fence_hl.lua consumes them, but that left the
--- *reported* config value -- e.g. on `:checkhealth` -- silently wrong; this
--- corrects the value itself and reports it on the issues list. Runs in the
--- `normalize` hook, so the schema check afterwards sees a number.
---@param tbl any Layer table or nested sub-table; anything but a table is left to the schema check
---@param key string
---@param min number
---@param max number
---@param default number
---@param label string Dotted path used in the issue message
---@param issues string[]
---@return nil
local function degrade_number(tbl, key, min, max, default, label, issues)
  if type(tbl) ~= 'table' or tbl[key] == nil then
    return
  end
  local raw = tbl[key]
  local n = tonumber(raw)
  local clamped = n and math.max(min, math.min(max, n))
  if n == nil or clamped ~= n then
    tbl[key] = clamped or default
    local range = max == math.huge and ('>= %s'):format(min) or ('%s-%s'):format(min, max)
    issues[#issues + 1] = ("option '%s' must be a number (%s), got %s -- using %s"):format(
      label,
      range,
      vim.inspect(raw),
      tostring(tbl[key])
    )
  end
end

--- Load all language definitions from the languages/ directory
--- Implements safe loading with error recovery and validation
---@internal
---@return table<string, ColorMyAscii.KeywordGroup> languages Map of language name to keyword group
---@return string[] errors List of loading errors (non-fatal)
local function load_languages()
  local languages = {}
  local errors = {}

  -- Safe path resolution
  local ok1, source = pcall(function()
    return debug.getinfo(1, 'S').source:sub(2)
  end)

  if not ok1 then
    table.insert(errors, 'Failed to determine plugin path')
    return languages, errors
  end

  local dir = fn.fnamemodify(source, ':h:h')
  local lang_path = dir .. '/languages'

  -- Check directory existence
  if fn.isdirectory(lang_path) == 0 then
    table.insert(errors, string.format('CRITICAL - languages/ directory not found at: %s', lang_path))
    return languages, errors
  end

  -- Safe file listing (path-based, not glob-pattern-based -- see XP-01)
  local list_ok, files = list_lua_files(lang_path)
  if not list_ok then
    table.insert(errors, 'Failed to list language files')
    return languages, errors
  end

  if #files == 0 then
    table.insert(errors, string.format('WARNING - No language files found in: %s', lang_path))
    return languages, errors
  end

  -- Load each language file with error recovery
  for _, file in ipairs(files) do
    local lang_name = fn.fnamemodify(file, ':t:r')
    local ok2, lang_module = pcall(require, 'color_my_ascii.languages.' .. lang_name)

    if ok2 and type(lang_module) == 'table' then
      -- Validate language module structure
      if type(lang_module.words) == 'table' and type(lang_module.hl) ~= 'nil' then
        languages[lang_name] = lang_module
      else
        table.insert(errors, string.format('Language "%s" has invalid structure', lang_name))
      end
    else
      table.insert(errors, string.format('Failed to load language "%s": %s', lang_name, tostring(lang_module)))
    end
  end

  return languages, errors
end

--- Load all character group definitions from the groups/ directory
--- Implements safe loading with error recovery and validation
---@internal
---@return table<string, ColorMyAscii.CharGroup> groups Map of group name to character group
---@return string[] errors List of loading errors (non-fatal)
local function load_groups()
  local groups = {}
  local errors = {}

  -- Safe path resolution
  local ok3, source = pcall(function()
    return debug.getinfo(1, 'S').source:sub(2)
  end)

  if not ok3 then
    table.insert(errors, 'Failed to determine plugin path')
    return groups, errors
  end

  local dir = fn.fnamemodify(source, ':h:h')
  local group_path = dir .. '/groups'

  -- Check directory existence
  if fn.isdirectory(group_path) == 0 then
    table.insert(errors, string.format('CRITICAL - groups/ directory not found at: %s', group_path))
    return groups, errors
  end

  -- Safe file listing (path-based, not glob-pattern-based -- see XP-01)
  local list_ok, files = list_lua_files(group_path)
  if not list_ok then
    table.insert(errors, 'Failed to list group files')
    return groups, errors
  end

  if #files == 0 then
    table.insert(errors, string.format('WARNING - No group files found in: %s', group_path))
    return groups, errors
  end

  -- Load each group file with error recovery
  for _, file in ipairs(files) do
    local group_name = fn.fnamemodify(file, ':t:r')
    local ok4, group_module = pcall(require, 'color_my_ascii.groups.' .. group_name)

    if ok4 and type(group_module) == 'table' then
      -- Validate group module structure
      if type(group_module.chars) == 'string' and type(group_module.hl) ~= 'nil' then
        groups[group_name] = group_module
      else
        table.insert(errors, string.format('Group "%s" has invalid structure', group_name))
      end
    else
      table.insert(errors, string.format('Failed to load group "%s": %s', group_name, tostring(group_module)))
    end
  end

  return groups, errors
end

--- Cached result of load_groups()/load_languages(): both read the plugin's own
--- bundled groups/ and languages/ directories, never anything user-supplied,
--- so re-globbing and re-requiring every file on a second setup() call (e.g.
--- plugin/color_my_ascii.lua's eager call, followed by the user's own
--- config = function() ... setup(opts) end) would just repeat the same result.
---@type { groups: table<string, ColorMyAscii.KeywordGroup>, group_errors: string[], languages: table<string, ColorMyAscii.CharGroup>, language_errors: string[] }|nil
local _bundled_defs = nil

---@internal
---@return { groups: table<string, ColorMyAscii.KeywordGroup>, group_errors: string[], languages: table<string, ColorMyAscii.CharGroup>, language_errors: string[] }
local function bundled_defs()
  if not _bundled_defs then
    local loaded_groups, group_errors = load_groups()
    local loaded_languages, language_errors = load_languages()
    _bundled_defs = {
      groups = loaded_groups,
      group_errors = group_errors,
      languages = loaded_languages,
      language_errors = language_errors,
    }
  end
  return _bundled_defs
end

--- Current configuration: the table of the store (`get_store()`), kept here for
--- the lookup builders below. Replaced by the store's `on_change` hook.
---@type ColorMyAscii.Config
local current_config = vim.deepcopy(DEFAULTS)

--- Incremented on every M.setup() call. Consumers that cache data derived
--- from the config but keyed only on e.g. (bufnr, changedtick) -- such as the
--- fence API's block-range cache, whose `is_ascii` classification depends on
--- `fence_language_map`/`treat_empty_fence_as_ascii`/`treesitter` -- fold this
--- into their own cache key so a config/scheme change invalidates them too.
---@type integer
local generation = 0

--- Create or get a custom highlight group
---@internal
---@param spec string|ColorMyAscii.CustomHighlight Highlight specification
---@return string highlight_group_name Name of the highlight group to use
local function resolve_highlight(spec)
  if type(spec) == 'string' then
    return spec
  end

  local hl_def = spec
  local name = string
    .format(
      'ColorMyAsciiCustom_%s_%s_%s_%s_%s_%s_%s',
      hl_def.fg or 'none',
      hl_def.bg or 'none',
      hl_def.bold and 'b' or '',
      hl_def.italic and 'i' or '',
      hl_def.underline and 'u' or '',
      hl_def.undercurl and 'c' or '',
      hl_def.strikethrough and 's' or ''
    )
    :gsub('#', '') -- Remove # from hex colors for group name

  if not created_highlight_groups[name] then
    local attrs = {
      fg = hl_def.fg,
      bg = hl_def.bg,
      bold = hl_def.bold,
      italic = hl_def.italic,
      underline = hl_def.underline,
      undercurl = hl_def.undercurl,
      strikethrough = hl_def.strikethrough,
    }
    vim.api.nvim_set_hl(0, name, attrs)
    created_highlight_groups[name] = attrs
  end

  return name
end

--- Re-apply all dynamically created custom ASCII-art highlight groups
--- (fixed-hex scheme colors, see e.g. schemes/catppuccin.lua). Neovim's
--- `:colorscheme` command runs an implicit `hi clear` that wipes these even
--- though `created_highlight_groups` still thinks they exist, so without this
--- the ASCII art highlighting goes stale after a colorscheme switch.
---@return nil
function M.reapply_custom_highlights()
  for name, attrs in pairs(created_highlight_groups) do
    vim.api.nvim_set_hl(0, name, attrs)
  end
end

--- Build a lookup table for fast character-to-highlight-group resolution
---@internal
---@return table<string, string> Map of character to highlight group name
local function build_char_lookup()
  local lookup = {}

  -- Step 1: Add all group characters
  for _, group in pairs(current_config.groups) do
    local hl_group = resolve_highlight(group.hl)
    local chars = fn.split(group.chars, '\\zs')
    for _, char in ipairs(chars) do
      lookup[char] = hl_group
    end
  end

  -- Step 2: Add brackets if bracket highlighting is enabled AND not already in groups
  if current_config.enable_bracket_highlighting then
    local bracket_hl = resolve_highlight('Operator')
    local brackets = { '(', ')', '[', ']', '{', '}' }
    for _, bracket in ipairs(brackets) do
      -- Only add if not already defined (groups have priority)
      if not lookup[bracket] then
        lookup[bracket] = bracket_hl
      end
    end
  end

  -- Step 3: Apply overrides (highest priority)
  for char, hl in pairs(current_config.overrides) do
    lookup[char] = resolve_highlight(hl)
  end

  return lookup
end

--- Build a lookup table for keywords across all languages
---@internal
---@return table<string, table<integer, {language: string, hl: string}>> Map of keyword to list of {language, hl_group}
local function build_keyword_lookup()
  if not current_config.enable_keywords then
    return {}
  end

  local lookup = {}

  for lang_name, lang_config in pairs(current_config.keywords) do
    local hl_group = resolve_highlight(lang_config.hl)
    for _, word in ipairs(lang_config.words) do
      lookup[word] = lookup[word] or {}
      table.insert(lookup[word], {
        language = lang_name,
        hl = hl_group,
      })
    end
  end

  return lookup
end

--- Build a lookup table for unique keywords per language (for heuristic detection)
---@internal
---@return table<string, string> Map of unique keyword to language name
local function build_unique_keyword_lookup()
  if not current_config.enable_language_detection then
    return {}
  end

  local lookup = {}
  -- A word that two languages both claim as "unique" identifies neither, so it
  -- is dropped rather than handed to whichever language `pairs()` happened to
  -- visit last. That made detection of a block containing e.g. `elif` (bash
  -- and python) or `namespace` (cpp and typescript) depend on table iteration
  -- order, and the two candidates paint with different highlight groups. The
  -- ordinary keyword lists still count these words; only the unique-word
  -- shortcut ignores them.
  local claimed_twice = {}

  for lang_name, lang_config in pairs(current_config.keywords) do
    if lang_config.unique_words then
      for _, word in ipairs(lang_config.unique_words) do
        if lookup[word] ~= nil and lookup[word] ~= lang_name then
          claimed_twice[word] = true
        else
          lookup[word] = lang_name
        end
      end
    end
  end

  for word in pairs(claimed_twice) do
    lookup[word] = nil
  end

  return lookup
end

---@internal
--- Drop the entries of `groups`, `keywords` and `overrides` the lookup builders
--- could not digest (a group without `chars`/`hl`, a language without `words`,
--- a non-table where a definition belongs, an override that is neither a
--- highlight name nor an attribute table), and say so. The schema leaves these
--- name-keyed tables open, and a thrown error in `on_change` would otherwise
--- leave the offending layer in place for every later `setup()`.
---@param cfg ColorMyAscii.Config The config being resolved (mutated)
---@param found string[] Issue lines to append to
---@return nil
local function drop_invalid_definitions(cfg, found)
  local function prune(section, valid, expected)
    local entries = cfg[section]
    if type(entries) ~= 'table' then
      return
    end
    local names = vim.tbl_keys(entries)
    table.sort(names, function(a, b)
      return tostring(a) < tostring(b)
    end)
    for _, name in ipairs(names) do
      if not valid(entries[name]) then
        found[#found + 1] = ('%s.%s has an invalid structure (expected %s), skipping'):format(
          section,
          tostring(name),
          expected
        )
        entries[name] = nil
      end
    end
  end
  prune('groups', function(def)
    return type(def) == 'table' and type(def.chars) == 'string' and def.hl ~= nil
  end, '{ chars = "...", hl = ... }')
  prune('keywords', function(def)
    return type(def) == 'table' and type(def.words) == 'table' and def.hl ~= nil
  end, '{ words = {...}, hl = ... }')
  prune('overrides', function(hl)
    return type(hl) == 'string' or type(hl) == 'table'
  end, 'a highlight group name or attribute table')
end

--- Merge user-declared `config.languages` into `current_config.keywords` - the
--- extension point for adding a language without a languages/*.lua file (see
--- |color_my_ascii-config-languages|). Same entry structure as the built-in
--- language files (`{ words, unique_words?, hl }`); an entry reusing a
--- built-in language's name overrides it. Invalid entries are skipped and
--- reported back to the caller instead of breaking keyword-lookup construction.
---@internal
---@param cfg ColorMyAscii.Config The config being resolved (mutated)
---@return string[] errors List of skipped-entry warnings (empty if none)
local function merge_user_languages(cfg)
  local user_languages = cfg.languages
  if type(user_languages) ~= 'table' or vim.tbl_isempty(user_languages) then
    return {}
  end

  local errors = {}
  local valid = {}
  for lang_name, lang_def in pairs(user_languages) do
    if type(lang_def) == 'table' and type(lang_def.words) == 'table' and lang_def.hl ~= nil then
      valid[lang_name] = lang_def
    else
      table.insert(
        errors,
        string.format(
          'languages.%s has an invalid structure (expected { words = {...}, hl = ... }), skipping',
          tostring(lang_name)
        )
      )
    end
  end

  -- Shallow extend: a name reused from a built-in language replaces that
  -- language's entry wholesale (words/unique_words/hl together), not a
  -- field-by-field deep merge - deep-extending would splice the user's
  -- `words` into the built-in array index-by-index instead of replacing it.
  cfg.keywords = vim.tbl_extend('force', cfg.keywords, valid)

  return errors
end

--- The config object (`lib.lua.config.new`), built on first use because its
--- defaults carry the bundled groups/languages. Layers, lowest first: the
--- `scheme` and the user's `setup` options.
---@type Lib.Config.Instance|nil
local store = nil

---@internal
---@return Lib.Config.Instance
local function get_store()
  if store then
    return store
  end
  local defs = bundled_defs()
  local defaults = vim.deepcopy(DEFAULTS)
  defaults.groups = defs.groups
  defaults.keywords = defs.languages

  store = require('lib.lua.config').new(defaults, {
    name = 'color_my_ascii',
    schema = SCHEMA,
    optional = OPTIONAL,
    layers = { 'scheme', 'setup' },
    -- A known key can carry an invalid VALUE the schema would only reject
    -- wholesale; numbers are clamped or defaulted first (ERR-22).
    normalize = function(opts, issues)
      degrade_number(
        opts,
        'language_detection_threshold',
        0,
        math.huge,
        DEFAULTS.language_detection_threshold,
        'language_detection_threshold',
        issues
      )
      degrade_number(
        opts.fence_line_highlight,
        'right_pad',
        0,
        20,
        DEFAULTS.fence_line_highlight.right_pad,
        'fence_line_highlight.right_pad',
        issues
      )
      degrade_number(
        opts.fence_content_highlight,
        'right_pad',
        0,
        20,
        DEFAULTS.fence_content_highlight.right_pad,
        'fence_content_highlight.right_pad',
        issues
      )
      degrade_number(
        opts.fence_content_highlight,
        'amount',
        0,
        100,
        DEFAULTS.fence_content_highlight.amount,
        'fence_content_highlight.amount',
        issues
      )
    end,
    resolve = function(cfg, found)
      drop_invalid_definitions(cfg, found)
      for _, err in ipairs(merge_user_languages(cfg)) do
        found[#found + 1] = err
      end
      -- A custom highlight spec becomes a real, named group
      if cfg.default_text_hl then
        cfg.default_text_hl = resolve_highlight(cfg.default_text_hl)
      end
    end,
    on_change = function(cfg)
      current_config = cfg
      M.char_lookup = build_char_lookup()
      M.keyword_lookup = build_keyword_lookup()
      M.unique_keyword_lookup = build_unique_keyword_lookup()
    end,
    notify = function(message)
      notify.warn(message)
    end,
  })
  return store
end

--- Setup the configuration with user options
---@param opts? ColorMyAscii.Config|{scheme: string} User configuration to merge with defaults
function M.setup(opts)
  generation = generation + 1

  -- Both bundled loaders return non-fatal error/warning lists rather than
  -- notifying themselves - setup() is the boundary that decides whether and
  -- how to surface them to the user.
  local defs = bundled_defs()
  local function notify_load_error(err)
    local level = err:match('^CRITICAL') and vim.log.levels.ERROR or vim.log.levels.WARN
    notify.notify(err, level)
  end
  for _, err in ipairs(defs.group_errors) do
    notify_load_error(err)
  end
  for _, err in ipairs(defs.language_errors) do
    notify_load_error(err)
  end

  local cfg = get_store()

  -- The scheme is a layer of its own below the user's options. An unknown one
  -- is reported and left out; the remaining options still apply.
  local user_opts = opts
  local scheme_config = nil
  if type(opts) == 'table' and opts.scheme ~= nil then
    user_opts = vim.tbl_extend('force', {}, opts)
    user_opts.scheme = nil
    local loaded, err = require('color_my_ascii.scheme_loader').load_scheme(opts.scheme)
    if loaded then
      scheme_config = loaded
    else
      notify.error(err)
    end
  end
  -- A layer is stored before the config is rebuilt from it, so a failure in
  -- the rebuild would otherwise keep failing every later setup(): start over
  -- from the defaults and let the caller see the error.
  local applied, apply_err = pcall(function()
    cfg.layer('scheme', scheme_config)
    cfg.setup(user_opts)
  end)
  if not applied then
    pcall(cfg.reset)
    error(apply_err, 0)
  end

  -- Initialize debug module if enabled
  if current_config.debug_enabled then
    local debug = require('color_my_ascii.debug')
    debug.setup({
      enabled = true,
      verbose = current_config.debug_verbose or false,
    })
  end
end

--- Get the current configuration.
---
--- Returns the module's live, shared table by reference, not a copy -- this
--- runs once per character in the highlight hot path, so copying on every
--- call is not the right trade-off (ERR-54). Treat the result as read-only:
--- sort/append/mutate a nested value (e.g. `cfg.keywords.lua.words`) and the
--- change sticks for the rest of the session, for every other consumer, and
--- a re-`require` of this module will not undo it (`package.loaded` caches
--- the same table). Copy it yourself first if you need to mutate.
---@return ColorMyAscii.Config
function M.get()
  return get_store().get()
end

--- Get the current config generation, incremented on every M.setup() call.
---@return integer
function M.generation()
  return generation
end

--- What the last `setup()` rejected or degraded: unknown/mistyped option
--- keys (ERR-50) and known keys whose value fell back to its default
--- (ERR-22), one human-readable line each. Empty when every key and value
--- was accepted as-is. For `:checkhealth color_my_ascii`.
---@return string[]
function M.issues()
  return get_store().issues()
end

--- Get the highlight group for a specific character
---@param char string Single character to look up
---@return string? highlight_group Highlight group name, or nil if using default
function M.get_char_highlight(char)
  return M.char_lookup[char]
end

--- Get possible languages for a keyword
---@param word string Keyword to look up
---@return table<integer, {language: string, hl: string}>? languages List of possible languages with their hl groups
function M.get_keyword_languages(word)
  return M.keyword_lookup[word]
end

--- Get language from unique keyword
---@param word string Keyword to check
---@return string? language Language name if keyword is unique to that language
function M.get_unique_language(word)
  return M.unique_keyword_lookup[word]
end

--- Get all available languages
---@return string[] languages List of language names
function M.get_available_languages()
  local langs = {}
  for lang_name, _ in pairs(M.get().keywords) do
    table.insert(langs, lang_name)
  end
  table.sort(langs)
  return langs
end

--- Check if function name detection is enabled
---@return boolean enabled True if function name detection is enabled
function M.is_function_detection_enabled()
  return M.get().enable_function_names
end

-- Initialize lookup tables (will be empty until setup() is called)
M.char_lookup = {}
M.keyword_lookup = {}
M.unique_keyword_lookup = {}

return M
