# Configuration

Full reference for `require('color_my_ascii').setup({ ... })`, including the
default configuration table, treesitter integration, color schemes, custom
highlights, and the fence-line / fence-content highlighting features.

## Table of content

  - [Default Configuration](#default-configuration)
  - [Custom Languages](#custom-languages)
  - [Treesitter Integration](#treesitter-integration)
  - [With Color Scheme](#with-color-scheme)
  - [Custom Highlights](#custom-highlights)
  - [All Features Enabled](#all-features-enabled)
  - [Fence-line highlighting](#fence-line-highlighting)
    - [Presets](#presets)
    - [Theme-matched presets](#theme-matched-presets)
    - [Overrides](#overrides)
  - [Fence-content highlighting](#fence-content-highlighting)
  - [ASCII Blocks in Code Comments](#ascii-blocks-in-code-comments)

---

## Default Configuration
````lua
require('color_my_ascii').setup({
  debug_enabled = false,
  debug_verbose = false,
  scheme = 'default',

  -- Character-specific overrides (highest priority)
  overrides = {},

  -- Your own language(s), merged into the built-in set (see "Custom
  -- Languages" below). Empty by default.
  languages = {},

  -- Default highlighting for unmatched characters
  default_hl = 'Normal',

  -- Optional: Default highlighting for normal text in blocks
  default_text_hl = nil,  -- e.g., 'Comment' for dimmed display

  -- Feature toggles
  enable_keywords = true,
  enable_language_detection = true,
  language_detection_threshold = 2,
  enable_function_names = true,
  enable_bracket_highlighting = true,
  treat_empty_fence_as_ascii = true,
  enable_inline_code = true,

  -- Standard markdown fence tags treated as ASCII blocks.
  -- Maps the fence language identifier to the plugin's language name.
  fence_language_map = {
    vim = 'vim',
    vimscript = 'vim',
    viml = 'vim',
  },

  -- Optional treesitter integration, on by default (see "Treesitter Integration" below)
  treesitter = {
    enabled = true,
    block_detection = true,
    syntax_highlight = true,
  },

  -- Optional ASCII blocks inside code comments outside markdown, off by
  -- default (see "ASCII Blocks in Code Comments" below).
  comment_ascii = {
    enable = false,
    filetypes = { 'lua', 'python', 'javascript', --[[ ... ]] },
  },

  -- Full-line highlight of fence delimiter lines (see "Fence-line highlighting"
  -- below). On by default; preset "auto" matches the current colorscheme.
  fence_line_highlight = {
    enable   = true,
    preset   = 'auto',     -- 'auto' | 'subtle' | 'accent' | 'underline' | 'bar' | <theme>
    open     = nil,        -- override: hl-group name (string) or attr table
    close    = nil,        -- override: hl-group name (string) or attr table
    apply_to = 'all',      -- 'all' fenced blocks | 'ascii' only
    respect_indent = true, -- start the paint at an indented block's own indent
                           -- column, not column 0; false paints the whole line
    right_pad = 1,         -- columns to hold off the window's right edge
  },

  -- Full-width background highlight of a fenced block's interior (see
  -- "Fence-content highlighting" below). On by default, independent of
  -- fence_line_highlight; shades that resolved color darker/lighter.
  fence_content_highlight = {
    enable   = true,
    preset   = nil,        -- nil = follow fence_line_highlight.preset
    hl       = nil,        -- override: hl-group name (string) or attr table; skips shading
    shade    = 'auto',     -- 'auto' | 'darken' | 'lighten' | 'none'
    amount   = 6,          -- 0-100
    apply_to = 'all',      -- 'all' fenced blocks | 'ascii' only
    respect_indent = true, -- as fence_line_highlight.respect_indent, for the interior
    right_pad = 1,         -- as fence_line_highlight.right_pad, for the interior
  },
})
````

---

## Custom Languages

The plugin ships 31 languages as `languages/*.lua` files (see
[Supported Languages](languages.md)). `languages` in `setup()` is the
extension point for adding your own without forking the plugin - same entry
shape as those files:

````lua
require('color_my_ascii').setup({
  languages = {
    mylang = {
      words        = { 'foo', 'bar', 'baz' }, -- highlighted with `hl`
      unique_words = { 'foo' },               -- optional: drives heuristic language detection
      hl           = 'Function',              -- hl-group name or a CustomHighlight table
    },
  },
})
````

Entries are merged into the built-in language set at `setup()` time. Reusing
a built-in name (e.g. `lua`) **replaces** that language's entry wholesale -
`words`/`unique_words`/`hl` together, not a field-by-field merge. A
malformed entry (missing `words` or `hl`) is skipped with a warning; the
rest of your languages (and all built-ins) still load normally.

Calling `setup()` again - e.g. from a keymap after editing a `languages`
entry - re-highlights every already-open, plugin-managed buffer immediately,
so a changed definition takes effect without touching the buffer or
restarting Neovim.

To also recognize a markdown fence tag as your language (not just
```` ```ascii-mylang ````), add it to `fence_language_map` too - see
[Standard Fence Tag Support](languages.md#standard-fence-tag-support).

---

## Treesitter Integration

On by default. Both sub-features fall back silently to heuristic-only
behavior when the relevant parser isn't installed, so there's no downside to
leaving this enabled even without treesitter set up at all - set
`enabled = false` to fully disable and behave exactly as without treesitter.
The two sub-flags below can also be toggled independently:

- **`block_detection`**: use Neovim's markdown treesitter grammar to find fenced
  code blocks instead of the built-in line scanner. More robust for edge cases
  (nested fences, unusual indentation). Requires a `markdown` parser
  (`:TSInstall markdown`); falls back to the heuristic scanner if unavailable.
- **`syntax_highlight`**: additionally highlight a block's content using the real
  grammar of its detected language (e.g. real Lua/Python/C syntax via `@`-prefixed
  highlight groups), on top of the existing character/keyword highlighting. This is
  best-effort - ASCII art is usually not valid syntax, so this only has a visible
  effect on blocks (or portions of blocks) that happen to contain real, parseable
  code. Requires a parser for that language (`:TSInstall <language>`); silently
  does nothing where unavailable or unparseable.

```lua
-- Disable entirely
require('color_my_ascii').setup({
  treesitter = { enabled = false },
})

-- Or keep block detection but skip the (more expensive) syntax highlighting pass
require('color_my_ascii').setup({
  treesitter = { syntax_highlight = false },
})
```

`:checkhealth color_my_ascii` reports whether the required parsers are installed.

---

## With Color Scheme
````lua
-- Matrix style (green hacker look)
require('color_my_ascii').setup(
  require('color_my_ascii.schemes.matrix')
)

-- Nord theme (cool blue/cyan)
require('color_my_ascii').setup(
  require('color_my_ascii.schemes.nord')
)

-- Gruvbox (warm retro colors)
require('color_my_ascii').setup(
  require('color_my_ascii.schemes.gruvbox')
)

-- Dracula (vibrant purple/pink)
require('color_my_ascii').setup(
  require('color_my_ascii.schemes.dracula')
)
````

See [Color Schemes](schemes.md) for the full list of built-in schemes and how
to create your own.

---

## Custom Highlights
````lua
require('color_my_ascii').setup({
  overrides = {
    -- String: Built-in highlight group
    ['┌'] = 'Special',

    -- Table: Custom definition with RGB/Hex
    ['└'] = { fg = '#ff0000', bold = true },
    ['→'] = { fg = '#00ff00', italic = true },
  },

  -- Dimmed text in blocks
  default_text_hl = { fg = '#808080' },
})
````

---

## All Features Enabled
````lua
require('color_my_ascii').setup({
  enable_keywords = true,
  enable_language_detection = true,
  enable_function_names = true,
  enable_bracket_highlighting = true,
  treat_empty_fence_as_ascii = true,
  enable_inline_code = true,
  default_text_hl = 'Comment',
})
````

---

## Fence-line highlighting

Paints the **whole** opening (`` ```lang ``) and closing (`` ``` ``) line of
fenced code blocks, as a visual boundary:

```javascript   ← this whole line
// ...
```            ← and this whole line

**On by default** with `preset = "auto"` (matches your colorscheme). Pick a
different look, or turn it off:

````lua
require('color_my_ascii').setup({
  fence_line_highlight = {
    enable   = true,
    preset   = 'auto',     -- see the presets below
    apply_to = 'all',      -- 'all' fenced blocks, or 'ascii' only
    respect_indent = true, -- see "Indented blocks" below
    right_pad = 1,         -- see "Indented blocks" below
  },
})
````

### Indented blocks

The fill is a `line_hl_group` extmark, so every cell of every row — the
backticks, the language tag, the code, blank interior lines, trailing
whitespace — shares the fence background.

`respect_indent = true` (the default) then carves the paint into a
rectangle: it starts at the block's own indent column — the opening
fence's first backtick — on every row (closing fence and blank interior
lines included) rather than at column 0, and holds `right_pad` columns
(default `1`) off the window's right edge so the highlight never quite
touches the border. `right_pad` needs the buffer to be visible in a window
and is recomputed when the window is resized; set it to `0` to run flush
to the edge.

Set `respect_indent = false` to skip the rectangle and paint the whole
screen line from column 0. Both options also exist on
`fence_content_highlight` for the interior rows.

### Presets

| Preset | Look |
|--------|------|
| `auto` | **default** — match the current colorscheme (see below), fall back to `subtle` |
| `subtle` | links to `CursorLine` (soft full-line tint) |
| `accent` | links to `Visual` (prominent tint) |
| `underline` | underlines the fence line |
| `bar` | links to `ColorColumn` (bar-like block) |

### Theme-matched presets

`preset = "auto"` reads `vim.g.colors_name`, substring-matches it (so
`catppuccin-mocha`, `tokyonight-storm`, `gruvbox-material` all match their base),
and applies a hand-tuned palette; it re-matches automatically on `:colorscheme`.
On a light background or an unknown theme it falls back to `subtle`. You can also
name a theme directly, e.g. `preset = "tokyonight"`.

Bundled themes: `catppuccin`, `tokyonight`, `gruvbox`, `gruvbox-material`,
`nord`, `onedark`, `dracula`, `kanagawa`, `rose-pine`, `everforest`, `nightfox`,
`material`, `sonokai`, `monokai`, `solarized`, `github`, `oxocarbon`.

### Overrides

For full control, `open` / `close` each accept either an existing highlight
group name (string, linked) **or** an attribute table forwarded to
`nvim_set_hl`:

````lua
fence_line_highlight = {
  enable = true,
  open   = 'Title',                           -- link to an existing group
  close  = { fg = '#5c6370', italic = true }, -- custom attributes
  apply_to = 'all',
}
````

The highlight lives in its own extmark namespace (priority below the character
highlights, so tokens stay visible), refreshes on edit, and re-resolves its
groups on `:colorscheme` changes.

> **Tip — value completion.** `preset` is a typed string enum
> (`ColorMyAscii.FencePreset`), so `lua_ls` offers the preset names as you type
> `preset = "…"`. It only kicks in when the plugin's types are on the LSP path —
> e.g. via `folke/lazydev.nvim` (add `"color_my_ascii.nvim"` to its `library`)
> or by annotating the table: `---@type ColorMyAscii.Config` above your `opts`.

---

## Fence-content highlighting

Paints the **interior** of a fenced block - every line between the delimiters,
blank lines and trailing whitespace included (not just where there are
characters). For an indented block the paint starts at the block's indent
column and holds `right_pad` off the window edge by default (`respect_indent`
/ `right_pad`, see "Indented blocks" above); `respect_indent = false` paints
from column 0:

```javascript
// this whole region, incl. the blank line and the line's trailing space →
                                                                            ←
```

**On by default**, independent of fence-line highlighting above. By default it
shades the *resolved* fence-line color darker (dark backgrounds) or lighter
(light backgrounds), so the interior reads as a related-but-distinguishable
tint of its own delimiter lines - no second palette to hand-tune:

````lua
require('color_my_ascii').setup({
  fence_content_highlight = {
    enable   = true,
    preset   = nil,      -- nil = follow fence_line_highlight.preset
    shade    = 'auto',   -- 'auto' | 'darken' | 'lighten' | 'none'
    amount   = 6,         -- 0-100 blend strength toward black/white
    apply_to = 'all',     -- 'all' fenced blocks, or 'ascii' only
    respect_indent = true, -- as fence_line_highlight; start at the indent column
    right_pad = 1,          -- as fence_line_highlight; hold off the right edge
  },
})
````

For full control, `hl` bypasses shading entirely and accepts either an
existing highlight-group name (string, linked) or an attribute table:

````lua
fence_content_highlight = {
  enable = true,
  hl     = { bg = '#1e1e2e' },
}
````

Turn it off with `enable = false` if you only want the delimiter-line
highlight above.

---

## ASCII Blocks in Code Comments

Everything above activates on markdown (` ``` ` fences). `comment_ascii`
extends detection to code comments in **other** filetypes, via an explicit
marker instead - there's no fence syntax to anchor to outside markdown:

````lua
require('color_my_ascii').setup({
  comment_ascii = {
    enable    = true,
    filetypes = { 'lua', 'python' }, -- default: a broad built-in list, see DEFAULTS.lua
  },
})
````

```lua
local function foo()
  -- ascii
  -- ┌────┐
  -- │ hi │
  -- └────┘
  -- /ascii
  return 1
end
```

The marker (`ascii` / `ascii-<lang>`, same tag syntax as a markdown fence)
must be on its own comment line, using the buffer's own line-comment prefix
(`vim.bo.commentstring`); `/ascii` closes it, same open/close symmetry as a
` ``` ` fence. A non-comment line before `/ascii` ends the scan without a
match, so an accidentally-unclosed block is silently skipped rather than
swallowing the rest of the file.

**Off by default** - unlike most other features, enabling this activates the
plugin on non-markdown filetypes. **Highlighting only**: the `:Fence` toolkit
and fence-line/fence-content background highlighting remain markdown-only;
comment blocks only get character/keyword/treesitter-overlay highlighting.
Only single-line comment syntax is supported (the `commentstring` prefix
before `%s`), not block comments (`/* ... */`).

---

## See Also

- [../README.md](../README.md) — project overview and quickstart
- [Commands](commands.md) — commands and `:Fence` actions that build on this configuration
- [Color Schemes](schemes.md) — built-in schemes and creating your own
