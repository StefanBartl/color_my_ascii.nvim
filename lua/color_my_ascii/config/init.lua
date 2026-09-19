---@module 'color_my_ascii.config'
--- Configuration management for color_my_ascii.nvim plugin.
--- Handles user configuration, defaults, and provides access to settings.
--- Supports modular language and group definitions, custom highlights, dynamic highlight groups,
--- and simplified scheme loading via string identifiers.

local M = {}

---@type fun(msg: string, level?: integer, opts?: table)
local notify = vim.notify
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
--- What the last `setup()` had to reject or degrade, one human-readable line
--- each, for `:checkhealth` -- an unknown/mistyped option key (ERR-50) or a
--- known key whose value was the wrong type/out of range and fell back to
--- its default (ERR-22). Empty when every key and value was accepted as-is.
---@type string[]
local _issues = {}

---@internal
--- Top-level keys `M.setup()` accepts and, for the fixed-schema tables among
--- them, their own direct keys (one level, not recursive -- see `sanitize()`).
--- `true` means "any key goes": `groups`/`keywords`/`languages`/`overrides`/
--- `fence_language_map` are name-keyed extension points (a language or group
--- name, a character, a fence tag), not a fixed option schema, so their own
--- keys are never known in advance. `keymaps`/`cache`/`debounce` are nil or
--- false by default and validated by their own modules at configure() time.
---@type table<string, true|table<string, true>>
local KNOWN = {
  debug_enabled = true,
  debug_verbose = true,
  scheme = true,
  groups = true,
  keywords = true,
  languages = true,
  overrides = true,
  default_hl = true,
  default_text_hl = true,
  enable_keywords = true,
  enable_language_detection = true,
  language_detection_threshold = true,
  treesitter = { enabled = true, block_detection = true, syntax_highlight = true },
  comment_ascii = { enable = true, filetypes = true },
  treat_empty_fence_as_ascii = true,
  enable_inline_code = true,
  enable_function_names = true,
  enable_bracket_highlighting = true,
  fence_language_map = true,
  fence_line_highlight = {
    enable = true,
    preset = true,
    open = true,
    close = true,
    apply_to = true,
    respect_indent = true,
    right_pad = true,
  },
  fence_content_highlight = {
    enable = true,
    preset = true,
    hl = true,
    shade = true,
    amount = true,
    apply_to = true,
    respect_indent = true,
    right_pad = true,
  },
  fence_export = {
    default_dir = true,
    open_after = true,
    open_cmd = true,
    replace = true,
    replace_format = true,
    ext_map = true,
  },
  fence_run = { runners = true },
  fence_format = { formatters = true },
  keymaps = true,
  cache = true,
  debounce = true,
  menu = { enable = true },
}

---@internal
--- `key` with the nearest known one as a hint when there is a plausible one
--- (edit distance <= 3).
---@param key any
---@param known table<string, any>
---@param prefix string
---@return string
local function describe_unknown(key, known, prefix)
  local levenshtein = require('lib.lua.strings.distance').levenshtein
  local name = tostring(key)
  local best, best_distance = nil, nil
  for candidate in pairs(known) do
    local d = levenshtein(name, candidate)
    if d <= 3 and (best_distance == nil or d < best_distance) then
      best, best_distance = candidate, d
    end
  end
  if best then
    return ("unknown option '%s%s' (did you mean '%s%s'?)"):format(prefix, name, prefix, best)
  end
  return ("unknown option '%s%s'"):format(prefix, name)
end

---@internal
--- Drop what cannot be merged, and say so, before the merge (ERR-50): a
--- misspelled key would otherwise land in the active config as a dead field
--- while the real option keeps its default, with no diagnostic anywhere.
---@param user_opts table
---@return table clean
---@return string[] issues
local function sanitize(user_opts)
  local clean, issues = {}, {}
  for key, value in pairs(user_opts) do
    local known = KNOWN[key]
    if known == nil then
      issues[#issues + 1] = describe_unknown(key, KNOWN, '')
    elseif type(DEFAULTS[key]) == 'table' and type(value) ~= 'table' then
      issues[#issues + 1] = ("option '%s' must be a table, got %s -- using the default"):format(key, type(value))
    elseif type(known) == 'table' and type(value) == 'table' then
      local nested = {}
      for sub_key, sub_value in pairs(value) do
        if known[sub_key] then
          nested[sub_key] = sub_value
        else
          issues[#issues + 1] = describe_unknown(sub_key, known, key .. '.')
        end
      end
      -- An empty table is what `config_to_merge`'s deep-extend would replace
      -- the whole key with -- if every sub-key the user gave was rejected
      -- above (e.g. a single typo'd sub-key), that would wipe every *other*
      -- default under `key` instead of leaving them alone. Only set the key
      -- at all when there is a real override left to apply.
      if next(nested) ~= nil then
        clean[key] = nested
      end
    else
      clean[key] = value
    end
  end
  table.sort(issues)
  return clean, issues
end

---@internal
--- Degrade a merged numeric option to `default` when the value is not a
--- number, or clamp it into `[min, max]` when it is a number but out of
--- range (ERR-22): a known key with a wrong-typed or out-of-range value must
--- not reach the code that consumes it as-is. `language_detection_threshold`
--- feeds a numeric comparison in `language_detector.lua` and a `%d` format in
--- `commands/config.lua` -- a non-numeric value there raises on every ASCII
--- block and on `:ColorMyAscii show-config`, not just a cosmetic glitch.
--- `fence_*_highlight.right_pad`/`fence_content_highlight.amount` were
--- already clamped where fence_hl.lua consumes them, but that left the
--- *reported* config value -- e.g. on `:checkhealth` -- silently wrong; this
--- corrects `cfg[key]` itself and reports it on the same `issues` list
--- ERR-50's key validation already surfaces there.
---@param cfg table Table to mutate in place (current_config or a nested sub-table of it)
---@param key string
---@param min number
---@param max number
---@param default number
---@param label string Dotted path used in the issue message
---@param issues string[]
---@return nil
local function degrade_number(cfg, key, min, max, default, label, issues)
  local raw = cfg[key]
  local n = tonumber(raw)
  local clamped = n and math.max(min, math.min(max, n))
  if n == nil or clamped ~= n then
    cfg[key] = clamped or default
    local range = max == math.huge and ('>= %s'):format(min) or ('%s-%s'):format(min, max)
    local issue = ("option '%s' must be a number (%s), got %s -- using %s"):format(
      label,
      range,
      vim.inspect(raw),
      tostring(cfg[key])
    )
    issues[#issues + 1] = issue
    notify('color_my_ascii: ' .. issue, vim.log.levels.WARN)
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

--- Default configuration (mutable copy; groups/keywords get populated at setup time)
---@type ColorMyAscii.Config
local defaults = vim.deepcopy(DEFAULTS)

--- Current configuration
---@type ColorMyAscii.Config
local current_config = vim.deepcopy(defaults)

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

--- Merge user-declared `config.languages` into `current_config.keywords` - the
--- extension point for adding a language without a languages/*.lua file (see
--- |color_my_ascii-config-languages|). Same entry structure as the built-in
--- language files (`{ words, unique_words?, hl }`); an entry reusing a
--- built-in language's name overrides it. Invalid entries are skipped and
--- reported back to the caller instead of breaking keyword-lookup construction.
---@internal
---@return string[] errors List of skipped-entry warnings (empty if none)
local function merge_user_languages()
  local user_languages = current_config.languages
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
  current_config.keywords = vim.tbl_extend('force', current_config.keywords, valid)

  return errors
end

--- Setup the configuration with user options
---@param opts? ColorMyAscii.Config|{scheme: string} User configuration to merge with defaults
function M.setup(opts)
  generation = generation + 1

  -- Load modular definitions (cached after the first call, see bundled_defs).
  -- Both loaders return non-fatal error/warning lists rather than notifying
  -- themselves - setup() is the boundary that decides whether and how to
  -- surface them to the user.
  local defs = bundled_defs()
  local loaded_groups, group_errors = defs.groups, defs.group_errors
  local loaded_languages, language_errors = defs.languages, defs.language_errors

  local function notify_load_error(err)
    local level = err:match('^CRITICAL') and vim.log.levels.ERROR or vim.log.levels.WARN
    notify('color_my_ascii: ' .. err, level)
  end
  for _, err in ipairs(group_errors) do
    notify_load_error(err)
  end
  for _, err in ipairs(language_errors) do
    notify_load_error(err)
  end

  defaults.groups = loaded_groups
  defaults.keywords = loaded_languages

  -- Validate user options before anything is merged (ERR-50): an unknown or
  -- mistyped key would otherwise land in current_config as dead data next to
  -- the default it was meant to override, with no diagnostic anywhere.
  local clean_opts, issues
  if opts == nil then
    clean_opts, issues = nil, {}
  elseif type(opts) ~= 'table' then
    clean_opts, issues = nil, { ('setup() expects a table, got %s -- using defaults'):format(type(opts)) }
  else
    clean_opts, issues = sanitize(opts)
  end
  _issues = issues
  for _, issue in ipairs(issues) do
    notify('color_my_ascii: ' .. issue, vim.log.levels.WARN)
  end

  -- Handle scheme parameter
  local config_to_merge = clean_opts
  if clean_opts and clean_opts.scheme then
    local scheme_loader = require('color_my_ascii.scheme_loader')
    local scheme_config, err = scheme_loader.load_scheme(clean_opts.scheme)

    if not scheme_config then
      notify(string.format('color_my_ascii: %s', err), vim.log.levels.ERROR)
      config_to_merge = vim.tbl_extend('force', {}, clean_opts)
      config_to_merge.scheme = nil -- Remove invalid scheme parameter
    else
      -- Merge user opts with scheme config (user opts take precedence)
      local user_opts = vim.tbl_extend('force', {}, clean_opts)
      user_opts.scheme = nil -- Remove scheme key from merge
      config_to_merge = vim.tbl_deep_extend('force', scheme_config, user_opts)
    end
  end

  if config_to_merge then
    current_config = vim.tbl_deep_extend('force', defaults, config_to_merge)
  else
    current_config = vim.deepcopy(defaults)
  end

  -- A known key can still carry an invalid VALUE through the merge above --
  -- unknown/mistyped *keys* are caught before the merge (ERR-50), but a
  -- wrong-typed or out-of-range value on a real key sails through
  -- `vim.tbl_deep_extend` unexamined. Degrade those here, before anything
  -- reads `current_config` (ERR-22).
  degrade_number(
    current_config,
    'language_detection_threshold',
    0,
    math.huge,
    defaults.language_detection_threshold,
    'language_detection_threshold',
    _issues
  )
  degrade_number(
    current_config.fence_line_highlight,
    'right_pad',
    0,
    20,
    defaults.fence_line_highlight.right_pad,
    'fence_line_highlight.right_pad',
    _issues
  )
  degrade_number(
    current_config.fence_content_highlight,
    'right_pad',
    0,
    20,
    defaults.fence_content_highlight.right_pad,
    'fence_content_highlight.right_pad',
    _issues
  )
  degrade_number(
    current_config.fence_content_highlight,
    'amount',
    0,
    100,
    defaults.fence_content_highlight.amount,
    'fence_content_highlight.amount',
    _issues
  )

  for _, err in ipairs(merge_user_languages()) do
    notify('color_my_ascii: ' .. err, vim.log.levels.WARN)
  end

  -- Resolve default_text_hl if it's a custom highlight
  if current_config.default_text_hl then
    current_config.default_text_hl = resolve_highlight(current_config.default_text_hl)
  end

  -- Rebuild lookup tables after configuration change
  M.char_lookup = build_char_lookup()
  M.keyword_lookup = build_keyword_lookup()
  M.unique_keyword_lookup = build_unique_keyword_lookup()

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
  return current_config
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
  return vim.list_extend({}, _issues)
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
  for lang_name, _ in pairs(current_config.keywords) do
    table.insert(langs, lang_name)
  end
  table.sort(langs)
  return langs
end

--- Check if function name detection is enabled
---@return boolean enabled True if function name detection is enabled
function M.is_function_detection_enabled()
  return current_config.enable_function_names
end

-- Initialize lookup tables (will be empty until setup() is called)
M.char_lookup = {}
M.keyword_lookup = {}
M.unique_keyword_lookup = {}

return M
