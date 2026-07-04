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
  -- Optional treesitter-based block detection and syntax highlighting.
  -- Off by default (enabled = false): the plugin behaves exactly as without treesitter.
  treesitter = {
    enabled = false,
    block_detection = true,
    syntax_highlight = true,
  },
  treat_empty_fence_as_ascii = true,
  enable_inline_code = true,
  enable_function_names = true,
  enable_bracket_highlighting = true,
  -- Maps standard markdown fence language identifiers to plugin language names.
  -- Fences whose language appears here are treated as ASCII blocks and highlighted
  -- with the corresponding language definition - not just ```ascii-prefixed ones.
  -- Covers every language in languages/*.lua under its common fence tag(s).
  fence_language_map = {
    vim = 'vim', vimscript = 'vim', viml = 'vim',
    bash = 'bash', sh = 'bash', shell = 'bash', zsh = 'bash',
    c = 'c',
    cpp = 'cpp', ['c++'] = 'cpp',
    csharp = 'csharp', ['c#'] = 'csharp', cs = 'csharp',
    lua = 'lua',
    python = 'python', py = 'python',
    ruby = 'ruby', rb = 'ruby',
    php = 'php',
    perl = 'perl', pl = 'perl',
    java = 'java',
    kotlin = 'kotlin', kt = 'kotlin',
    scala = 'scala',
    groovy = 'groovy',
    clojure = 'clojure', clj = 'clojure',
    javascript = 'javascript', js = 'javascript',
    typescript = 'typescript', ts = 'typescript',
    html = 'html',
    css = 'css',
    json = 'json',
    go = 'go', golang = 'go',
    rust = 'rust', rs = 'rust',
    zig = 'zig',
    swift = 'swift',
    dart = 'dart',
    elixir = 'elixir', ex = 'elixir',
    haskell = 'haskell', hs = 'haskell',
    r = 'r',
    sql = 'sql',
    powershell = 'powershell', ps1 = 'powershell',
    llvm = 'llvm',
  },
  -- Optional default keymaps (see lua/color_my_ascii/bindings/keymaps.lua).
  -- false = no keymaps are set. Pass a table to enable and customize individual mappings.
  keymaps = false,
  -- Optional overrides for cache_manager/debounce_manager defaults.
  -- nil = use the plugin's built-in defaults.
  cache = nil,
  debounce = nil,
}
