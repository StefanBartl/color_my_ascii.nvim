---@module 'color_my_ascii.config.DEFAULTS'
--- Default configuration values for color_my_ascii.nvim.
--- `groups` and `keywords` are populated at runtime from the languages/ and groups/
--- directories in config/init.lua's setup().

---@type ColorMyAscii.Config
return {
  debug_enabled = false,
  debug_verbose = false,
  scheme = 'default',
  groups = {},
  keywords = {},
  overrides = {},
  default_hl = 'Normal',
  default_text_hl = nil,
  enable_keywords = true,
  enable_language_detection = true,
  language_detection_threshold = 2,
  enable_treesitter = false,
  treat_empty_fence_as_ascii = true,
  enable_inline_code = true,
  enable_function_names = true,
  enable_bracket_highlighting = true,
  -- Maps standard markdown fence language identifiers to plugin language names.
  -- Fences whose language appears here are treated as ASCII blocks and highlighted
  -- with the corresponding language definition.
  fence_language_map = {
    vim = 'vim',
    vimscript = 'vim',
    viml = 'vim',
  },
  -- Optional default keymaps (see lua/color_my_ascii/bindings/keymaps.lua).
  -- false = no keymaps are set. Pass a table to enable and customize individual mappings.
  keymaps = false,
  -- Optional overrides for cache_manager/debounce_manager defaults.
  -- nil = use the plugin's built-in defaults.
  cache = nil,
  debounce = nil,
}
