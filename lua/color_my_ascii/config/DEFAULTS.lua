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
  -- Extension point for adding your own language without a languages/*.lua
  -- file in the plugin itself. Same entry shape as the built-ins ({ words,
  -- unique_words?, hl }); merged into `keywords` at setup() (a name that
  -- matches a built-in language overrides it). Malformed entries are skipped
  -- with a warning rather than breaking keyword-lookup construction.
  languages = {},
  overrides = {},
  default_hl = 'Normal',
  default_text_hl = nil,
  enable_keywords = true,
  enable_language_detection = true,
  language_detection_threshold = 2,
  -- Optional treesitter-based block detection and syntax highlighting.
  -- On by default: both sub-features silently fall back to heuristic-only
  -- behavior when the relevant parser isn't installed, so there's no downside
  -- to leaving this enabled even without treesitter set up at all.
  treesitter = {
    enabled = true,
    block_detection = true,
    syntax_highlight = true,
  },
  -- Optional detection/highlighting of explicitly-marked ASCII blocks inside
  -- code comments, outside markdown - `-- ascii` ... `-- /ascii` (using the
  -- buffer's own line-comment prefix). Off by default: unlike most other
  -- features, enabling this activates the plugin on non-markdown filetypes.
  -- Highlighting only - the :Fence toolkit and fence-line/-content
  -- background highlighting remain markdown-only.
  comment_ascii = {
    enable = false,
    filetypes = {
      'lua',
      'python',
      'javascript',
      'typescript',
      'go',
      'rust',
      'c',
      'cpp',
      'sh',
      'bash',
      'zsh',
      'ruby',
      'java',
      'kotlin',
      'scala',
      'swift',
      'dart',
      'elixir',
      'haskell',
      'perl',
      'r',
      'clojure',
      'groovy',
      'php',
      'csharp',
    },
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
    vim = 'vim',
    vimscript = 'vim',
    viml = 'vim',
    bash = 'bash',
    sh = 'bash',
    shell = 'bash',
    zsh = 'bash',
    c = 'c',
    cpp = 'cpp',
    ['c++'] = 'cpp',
    csharp = 'csharp',
    ['c#'] = 'csharp',
    cs = 'csharp',
    lua = 'lua',
    python = 'python',
    py = 'python',
    ruby = 'ruby',
    rb = 'ruby',
    php = 'php',
    perl = 'perl',
    pl = 'perl',
    java = 'java',
    kotlin = 'kotlin',
    kt = 'kotlin',
    scala = 'scala',
    groovy = 'groovy',
    clojure = 'clojure',
    clj = 'clojure',
    javascript = 'javascript',
    js = 'javascript',
    typescript = 'typescript',
    ts = 'typescript',
    html = 'html',
    css = 'css',
    json = 'json',
    go = 'go',
    golang = 'go',
    rust = 'rust',
    rs = 'rust',
    zig = 'zig',
    swift = 'swift',
    dart = 'dart',
    elixir = 'elixir',
    ex = 'elixir',
    haskell = 'haskell',
    hs = 'haskell',
    r = 'r',
    sql = 'sql',
    powershell = 'powershell',
    ps1 = 'powershell',
    llvm = 'llvm',
  },
  -- Full-line highlight of fenced-block delimiter lines (the ```lang opening
  -- line and its closing ``` line). On by default. `apply_to` selects which
  -- blocks get it: "all" fenced blocks or only "ascii" ones. `preset` picks the
  -- look: "auto" (match the current colorscheme, see theme_presets.lua), the
  -- generic "subtle"/"accent"/"underline"/"bar", or a specific theme name.
  -- `open`/`close` override per-delimiter and accept either an existing
  -- highlight-group name (string) or an attribute table
  -- (ColorMyAscii.CustomHighlight, forwarded to nvim_set_hl).
  fence_line_highlight = {
    enable = true,
    preset = 'auto', -- "auto" | "subtle" | "accent" | "underline" | "bar" | <theme>
    open = nil,
    close = nil,
    apply_to = 'all', -- "all" | "ascii"
    -- Keep the highlight within an indented block's own left indentation and
    -- stop it at the block's widest line (preserving Neovim's small right-edge
    -- gap) instead of painting the entire screen line. Opt out with `false`.
    respect_indent = true,
  },
  -- Full-width background highlight of a fenced block's *interior* (the lines
  -- between the delimiters), so the whole block reads as one visual region.
  -- Uses `line_hl_group` extmarks, same as fence_line_highlight, so it covers
  -- trailing whitespace and blank lines too, not just characters. On by
  -- default; opt out with `enable = false`.
  -- `preset` (nil by default) falls back to fence_line_highlight.preset, then
  -- that resolved color is shaded darker/lighten by `amount`% (`shade`
  -- controls the direction; "auto" darkens on dark backgrounds, lightens on
  -- light ones) so the interior reads as a related-but-distinguishable tint
  -- of the delimiter lines. `hl` bypasses shading with an explicit override.
  fence_content_highlight = {
    enable = true,
    preset = nil, -- nil = follow fence_line_highlight.preset; else same values as fence_line_highlight.preset
    hl = nil, -- override: hl-group name (string) or attr table; skips shading
    shade = 'auto', -- "auto" | "darken" | "lighten" | "none"
    amount = 6, -- 0-100
    apply_to = 'all', -- "all" | "ascii"
    -- Same as fence_line_highlight.respect_indent, for the interior rows: keep
    -- the tint inside the block's indentation and end it at the widest line.
    respect_indent = true,
  },
  -- `:Fence export` behaviour (buffer-local command in markdown buffers).
  -- default_dir: where the suggested export path lives ("buffer" dir or "cwd").
  -- open_after/open_cmd: open the exported file afterwards (--open forces it).
  -- replace/replace_format: swap the fenced block for a link reference
  --   ("literate tangle"; --replace forces it). Format args: (filename, relpath).
  -- ext_map: language-tag -> file-extension overrides on top of the built-ins.
  fence_export = {
    default_dir = 'buffer', -- "buffer" | "cwd"
    open_after = false,
    open_cmd = 'vsplit', -- "edit" | "split" | "vsplit" | "tabedit"
    replace = false,
    replace_format = '[%s](%s)',
    ext_map = {},
  },
  -- `:Fence run` — interpreter per language tag (string or string[]); the temp
  -- file with the block content is appended as the last argument. Merged on top
  -- of the built-in runners; set a language to false semantics via omission.
  fence_run = {
    runners = {},
  },
  -- `:Fence format` — stdin/stdout formatter per language tag (string[]). Merged
  -- on top of the built-in formatters (stylua/black/prettier/gofmt/...).
  fence_format = {
    formatters = {},
  },
  -- Optional default keymaps (see lua/color_my_ascii/bindings/keymaps.lua).
  -- Deliberately off by default, unlike most other features: keymaps claim a
  -- slot in the user's global keymap namespace and can silently collide with
  -- mappings the user already has, which a purely visual/heuristic feature
  -- toggle can't. Pass a table to enable and customize individual mappings.
  keymaps = false,
  -- Optional overrides for cache_manager/debounce_manager defaults.
  -- nil = use the plugin's built-in defaults.
  cache = nil,
  debounce = nil,
  -- Right-click context menu (nvzone/menu, soft dependency; entries from
  -- color_my_ascii.integrations.menu). Off automatically when nvzone/menu
  -- isn't installed - this only gates whether M.items()/M.submenu() return
  -- entries at all.
  menu = {
    enable = true,
  },
}
