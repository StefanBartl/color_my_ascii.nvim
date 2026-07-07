# color_my_ascii.nvim

```
    ╔══════════════════════════════════════════╗
    ║   c o l o r _ m y _ a s c i i . n v i m   ║
    ║   ┌─┐ → ★ ┌─┐   function() end   ┌─┐      ║
    ╚══════════════════════════════════════════╝
```

> See also: [markdown.nvim](https://github.com/StefanBartl/markdown.nvim) - a companion
> plugin for working with Markdown files, pairs well with the ASCII highlighting here.

![version](https://img.shields.io/badge/version-0.2-blue.svg)
![State](https://img.shields.io/badge/status-beta-orange.svg)
![Lazy.nvim compatible](https://img.shields.io/badge/lazy.nvim-supported-success)
![Neovim](https://img.shields.io/badge/Neovim-0.9+-success.svg)
![Lua](https://img.shields.io/badge/language-Lua-yellow.svg)

> 🔧 Beta stage – under active development. Changes possible.

A Neovim plugin for colorful highlighting of ASCII art in Markdown code blocks with automatic language detection, custom highlights, and predefined color schemes.

## Table of content

  - [Features](#features)
    - [Core Features](#core-features)
    - [Extended Features](#extended-features)
  - [Installation](#installation)
    - [With lazy.nvim](#with-lazynvim)
    - [With packer.nvim](#with-packernvim)
  - [Quick Start](#quick-start)
    - [Minimal Setup](#minimal-setup)
    - [Example](#example)
  - [Configuration](#configuration)
    - [Default Configuration](#default-configuration)
    - [Treesitter Integration](#treesitter-integration)
    - [With Color Scheme](#with-color-scheme)
    - [Custom Highlights](#custom-highlights)
    - [All Features Enabled](#all-features-enabled)
  - [Supported Languages](#supported-languages)
  - [Command](#command)
    - [Core Commands](#core-commands)
    - [Fence Management](#fence-management)
    - [Scheme Management](#scheme-management)
    - [Keybinding Examples](#keybinding-examples)
  - [Documentation](#documentation)
    - [Features](#features-1)
    - [Guides](#guides)
    - [Reference](#reference)
  - [Color Schemes](#color-schemes)
    - [Matrix (Hacker Style)](#matrix-hacker-style)
    - [Nord](#nord)
    - [Gruvbox](#gruvbox)
    - [Dracula](#dracula)
    - [Create Your Own Scheme](#create-your-own-scheme)
  - [Performance](#performance)
  - [Troubleshooting](#troubleshooting)
    - [No Highlights Visible](#no-highlights-visible)
    - [Wrong Language Detected](#wrong-language-detected)
    - [Performance Issues](#performance-issues)
  - [Contributing](#contributing)
    - [Add a New Language](#add-a-new-language)
    - [Add a New Character Group](#add-a-new-character-group)
  - [Credits](#credits)
  - [See Also](#see-also)

---

## Features

### Core Features

- ✅ **Automatic Detection** of `ascii` code blocks in Markdown files
- ✅ **Modular Language Definitions**: 31 predefined languages (C, C++, C#, Lua, Go, Rust, TypeScript, JavaScript, Python, Bash, Zig, LLVM IR, Vimscript, Java, PHP, Ruby, Kotlin, Swift, Scala, Dart, Elixir, Haskell, Perl, R, Clojure, Groovy, PowerShell, SQL, JSON, HTML, CSS)
- ✅ **Intelligent Language Detection**:
  - Explicit via ````ascii-c`, ````ascii lua`, ````ascii:python`
  - Standard markdown fence tags via `fence_language_map` (e.g., ` ```vim `)
  - Heuristic based on keyword frequency
  - Fallback to buffer filetype
- ✅ **Modular Character Groups**: Customizable groups for lines, blocks, arrows, symbols, operators
- ✅ **Custom Highlights with RGB/Hex**: Full color and style control
- ✅ **Predefined Color Schemes**: Default, Matrix, Nord, Gruvbox, Dracula,...
- ✅ **Non-intrusive**: Uses extmarks, no buffer modification

---

### Extended Features

- ✅ **Function Name Detection**: Heuristic for `word()` pattern
- ✅ **Bracket Highlighting**: Automatic highlighting of `()[]{}`
- ✅ **Inline Code Highlighting**: Keywords and symbols backticks highlighted: `` `...` ``
- ✅ **Empty Fenced Blocks**: Optionally treat ``` without language as ASCII
- ✅ **Default Text Color**: Dimmed representation for normal text
- ✅ **Fence-line Highlighting**: Full-line highlight of ` ``` ` delimiter lines, on by default — `auto` preset matches your colorscheme (17 bundled themes) — see below
- ✅ **Public Fence API**: `require("color_my_ascii").fences` — reusable fenced-block detection for other plugins (see below)
- ✅ **`:Fence` actions**: e.g. `:Fence export` — extract a fenced block into a standalone file (`--open`, `--replace`)
- ✅ **Health Check**: `:checkhealth color_my_ascii`
- ✅ **Fence Validation**: `:ColorMyAsciiCheckFences` to detect unmatched blocks
- ✅ **Vim Help**: `:h color_my_ascii`

---

## Installation

**Loading strategy**: the plugin is loaded via `ft = 'markdown'`, i.e. only once a
Markdown buffer is opened. This is the recommended trigger for this plugin - more
precise than a blanket `event = "VeryLazy"`, since there is nothing to do until a
Markdown file is actually being edited.

### With lazy.nvim
````lua
{
  'StefanBartl/color_my_ascii.nvim',
  ft = 'markdown',
  dependencies = { 'StefanBartl/lib.nvim' }, -- optional, enables graceful keymap/notify integration
  opts = {
    -- Optional: Configuration here
  }
}
````

---

### With packer.nvim
````lua
use {
  'StefanBartl/color_my_ascii.nvim',
  ft = 'markdown',
  requires = { 'StefanBartl/lib.nvim' }, -- optional, enables graceful keymap/notify integration
  config = function()
    require('color_my_ascii').setup({
      -- Optional: Configuration here
    })
  end
}
````

---

## Quick Start

### Minimal Setup
````lua
require('color_my_ascii').setup()
````

The plugin activates automatically for Markdown files.

---

### Example
````markdown
```ascii
┌─────────────────────┐
│  Hello World!       │
└─────────────────────┘
```
````

→ Box-drawing characters are automatically highlighted in color

---

## Configuration

### Default Configuration
````lua
require('color_my_ascii').setup({
  debug_enabled = false,
  debug_verbose = false,
  scheme = 'default',

  -- Character-specific overrides (highest priority)
  overrides = {},

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

  -- Full-line highlight of fence delimiter lines (see "Fence-line highlighting"
  -- below). On by default; preset "auto" matches the current colorscheme.
  fence_line_highlight = {
    enable   = true,
    preset   = 'auto',     -- 'auto' | 'subtle' | 'accent' | 'underline' | 'bar' | <theme>
    open     = nil,        -- override: hl-group name (string) or attr table
    close    = nil,        -- override: hl-group name (string) or attr table
    apply_to = 'all',      -- 'all' fenced blocks | 'ascii' only
  },
})
````

---

### Treesitter Integration

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

### With Color Scheme
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

---

### Custom Highlights
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

### All Features Enabled
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
  },
})
````

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

## Fence API (for plugin authors)

color_my_ascii owns robust, CommonMark-compatible fenced-block detection
(heuristic state machine + treesitter). Other plugins can consume it instead of
reimplementing fence parsing — this is how
[markdown.nvim](https://github.com/StefanBartl/markdown.nvim) implements its
"treat a `` ```markdown `` block as its own document scope" feature.

````lua
local fences = require('color_my_ascii').fences   -- available without setup()

-- Every fenced block in a buffer, in document order.
-- Each block: { open_row, close_row, content_start, content_end (0-indexed,
-- content is the half-open range [content_start, content_end)), lang,
-- fence_char, fence_len, is_ascii, fence_line, lines? }
local blocks = fences.list_blocks(bufnr, {
  lines    = 'none',       -- 'none' | 'ascii' | 'all' (collect content lines?)
  markdown = false,        -- true = only markdown-family langs
  lang     = nil,          -- string | string[] filter
  filter   = nil,          -- fun(block): boolean
})

-- The innermost block whose *interior* contains a row (0-indexed; defaults to
-- the cursor row). include_fence = true also matches the delimiter lines.
local block = fences.block_at(bufnr, row, { markdown = true })

-- Classify a fence language tag as markdown-family (markdown/md/mdx/…).
fences.is_markdown_lang('mdx')  -- true
````

Range-only queries (`lines = 'none'`) are cached per buffer `changedtick`, so
`block_at` is cheap to call on every keystroke.

---

## Supported Languages

The plugin includes predefined keyword definitions for:

| Language | Unique Keywords | Example |
|----------|----------------|---------|
| C | `restrict`, `_Bool`, `_Complex` | `int`, `void`, `char` |
| C++ | `class`, `namespace`, `template` | `virtual`, `override`, `nullptr` |
| C# | `foreach`, `delegate`, `sealed` | `class`, `async`, `await` |
| Lua | `then`, `elseif`, `end` | `function`, `local`, `nil` |
| Go | `func`, `chan`, `defer` | `go`, `:=`, `<-` |
| Rust | `fn`, `mut`, `impl` | `trait`, `match`, `loop` |
| TypeScript | `interface`, `namespace` | `async`, `await`, `Promise` |
| JavaScript | `console`, `NaN`, `globalThis` | `function`, `async`, `await` |
| Python | `def`, `elif`, `pass` | `lambda`, `self`, `yield` |
| Bash | `fi`, `esac`, `done` | `if`, `then`, `else` |
| Zig | `comptime`, `errdefer` | `anytype`, `unreachable` |
| LLVM IR | `getelementptr`, `phi` | `alloca`, `icmp`, `zext` |
| Vimscript | `endif`, `endfunction`, `nnoremap` | `augroup`, `echom`, `setlocal` |
| Java | `implements`, `throws`, `synchronized` | `class`, `public`, `static` |
| PHP | `echo`, `require_once`, `isset` | `function`, `class`, `foreach` |
| Ruby | `elsif`, `unless`, `attr_accessor` | `def`, `end`, `module` |
| Kotlin | `fun`, `companion`, `suspend` | `val`, `var`, `class` |
| Swift | `guard`, `fileprivate`, `deinit` | `func`, `var`, `let` |
| Scala | `trait`, `implicit`, `object` | `def`, `val`, `case` |
| Dart | `mixin`, `covariant`, `late` | `void`, `class`, `async` |
| Elixir | `defmodule`, `defp`, `defmacro` | `def`, `do`, `end` |
| Haskell | `newtype`, `deriving`, `Maybe` | `data`, `type`, `where` |
| Perl | `bless`, `wantarray`, `qw` | `my`, `sub`, `if` |
| R | `sapply`, `lapply`, `ifelse` | `function`, `TRUE`, `FALSE` |
| Clojure | `defn`, `recur`, `deref` | `let`, `fn`, `def` |
| Groovy | `println`, `findAll`, `GString` | `def`, `class`, `closure` |
| PowerShell | `param`, `trap` | `function`, `foreach`, `try` |
| SQL | `SELECT`, `INSERT`, `JOIN` | `WHERE`, `FROM`, `UPDATE` |
| JSON | *(none - explicit tag only)* | `true`, `false`, `null` |
| HTML | `DOCTYPE`, `textarea`, `thead` | `div`, `span`, `class` |
| CSS | `keyframes`, `rgba`, `important` | `display`, `flex`, `color` |

### Standard Fence Tag Support

Blocks with a standard markdown fence language tag are automatically
highlighted when that tag is listed in `fence_language_map` - this includes
**every language above under its common tag(s)** by default (e.g. ` ```go `,
` ```js `/` ```javascript `, ` ```py `/` ```python `, ` ```rb `/` ```ruby `, ...),
not just the `ascii`-prefixed formats:

````markdown
```vim
function! MyFunc()
  ┌──────────────────────────┐
  │  nnoremap <leader>w :w<CR>│
  └──────────────────────────┘
endfunction
```
````

See [config/DEFAULTS.lua](lua/color_my_ascii/config/DEFAULTS.lua) for the full
default map (aliases like `sh`/`py`/`ts`/`rs`/`kt`/`cs` included). Add or
override entries in your own setup:

````lua
require('color_my_ascii').setup({
  fence_language_map = {
    myasciitag = 'python',  -- add a custom tag on top of the defaults
  },
})
````

Additional languages can be easily added (see [Contributing](#contributing)).

---

## Command

### Core Commands

| Command | Description |
|---------|-------------|
| `:ColorMyAscii` | Manually update highlighting |
| `:ColorMyAsciiToggle` | Enable/disable plugin |
| `:ColorMyAsciiDebug` | Show debug information (basic) |
| `:ColorMyAsciiShowConfig` | Show detailed configuration |
| `:checkhealth color_my_ascii` | Run health check |
| `:h color_my_ascii` | Open Vim help |

---

### Fence Management

| Command | Description |
|---------|-------------|
| `:ColorMyAsciiCheckFences` | Check for unmatched fences |
| `:ColorMyAsciiEnsureBlankLines` | Ensure blank lines around code blocks |

---

### Fence actions — `:Fence` (buffer-local, markdown)

Actions on the fenced code block **under the cursor**, built on the fence API.
Registered buffer-local in markdown buffers.

| Command | Description |
|---------|-------------|
| `:Fence export [path] [--open] [--replace]` | Extract the block's content into a standalone file |

- **Path** may be quoted or bare: `:Fence export "src/a.js"`, `:Fence export 'a b.py'`,
  `:Fence export a.lua`. Omit it to get a prompt with a suggested filename and
  file-path completion. The suggested extension is derived from the fence
  language (`javascript → .js`, `python → .py`, …).
- **`--open`** opens the exported file afterwards (`open_cmd`, default `vsplit`).
- **`--replace`** replaces the fenced block with a link reference to the new file
  (literate-tangle style; format via `fence_export.replace_format`).
- Argument completion suggests the subcommand, the flags, and file paths.

````lua
require('color_my_ascii').setup({
  fence_export = {
    default_dir    = "buffer",   -- "buffer" | "cwd"
    open_after     = false,      -- always open after export
    open_cmd       = "vsplit",   -- "edit" | "split" | "vsplit" | "tabedit"
    replace        = false,      -- always replace with a reference
    replace_format = "[%s](%s)", -- (filename, relative-path)
    ext_map        = {},         -- language-tag -> extension overrides
  },
})
````

### Syntax highlighting inside fences

A `` ```javascript `` block is highlighted by Neovim's **native treesitter
injections** (install the parser with `:TSInstall javascript` and enable
`nvim-treesitter` highlight). For languages color_my_ascii knows
(`fence_language_map`), it additionally overlays the real grammar via
`treesitter.syntax_highlight` (on by default). `:checkhealth color_my_ascii`
reports which fence languages in the buffer are missing a parser.

Full LSP inside fences (completion/hover/diagnostics) is on the roadmap — see
[docs/ROADMAP/lsp_integration_fence.md](docs/ROADMAP/lsp_integration_fence.md).

---

### Scheme Management

| Command | Description |
|---------|-------------|
| `:ColorMyAsciiListSchemes` | List available color schemes |
| `:ColorMyAsciiSwitchScheme <name>` | Switch to a different scheme |
| `:ColorMyAsciiSchemes` | Pick scheme with Telescope (live preview) |

---

#### Available Schemes

- `default`    - Built-in Neovim highlights
- `matrix`     - Green hacker style
- `nord`       - Cool blue/cyan
- `gruvbox`    - Warm retro colors
- `dracula`    - Vibrant purple/pink
- `catppuccin` - Soft pastel colors
- `onedark`    - Dark theme with subtle highlights
- `solarized`  - Solarized color palette
- `tokyonight` - Dark theme with blue accents
- `monokai`    - # Classic Monokai color scheme

### Keybinding Examples

Keymaps are **opt-in** and disabled by default. Enable and customize them via the
`keymaps` option in `setup()`:

```lua
require('color_my_ascii').setup({
  keymaps = {
    highlight           = '<leader>ah',
    toggle              = '<leader>at',
    schemes             = '<leader>as',
    ensure_blank_lines  = '<leader>af',
    show_config         = '<leader>ac',
    debug               = '<leader>ad',
    check_fences        = '<leader>ax',
  },
})
```

Each mapping is set with a `desc`, so [which-key.nvim](https://github.com/folke/which-key.nvim)
picks them up automatically without extra configuration. If
[lib.nvim](https://github.com/StefanBartl/lib.nvim) is installed, it is used for the
underlying keymap registration; otherwise the plugin falls back to `vim.keymap.set`.

See [docs/BINDINGS.md](docs/BINDINGS.md) for the full cheatsheet of user commands,
keymap actions, and autocommands.

---

## Documentation

### Features

- [Custom Highlights](docs/features/custom-highlights.md) - RGB/Hex colors and styles
- [Function Detection](docs/features/function-detection.md) - Automatic function name detection
- [Bracket Highlighting](docs/features/bracket-highlighting.md) - Highlight brackets
- [Inline Code](docs/features/inline-code.md) - Highlighting in `` `...` ``

---

### Guides

- [Quickstart](docs/QUICKSTART.md) - Getting started
- [Test File](docs/dev/TEST.md) - Test all features
- [Color Schemes](docs/schemes.md) - Create custom schemes
- [Bindings Cheatsheet](docs/BINDINGS.md) - All commands, keymaps, and autocommands
- [Roadmap](docs/ROADMAP.md) - Planned and considered future work

---

### Reference

- [Vim Help](doc/color_my_ascii.txt) - Complete reference
- [Changelog](docs/CHANGELOG.md) - Version history

---

## Color Schemes

Pick one scheme from the list of [available schemes](#available-schemes) and set it in the initialization like:

Example with Matrix Scheme:

````lua
require('color_my_ascii').setup({
  scheme = "matrix",
})
````

Dark background with bright green elements. All features enabled.

---

### Create Your Own Scheme
````lua
require('color_my_ascii').setup({
  groups = {
    box_drawing = {
      chars = "─│┌┐└┘",
      hl = { fg = '#00ff00', bold = true },
    },
  },
  overrides = {
    ['★'] = { fg = '#ffff00' },
  },
  enable_keywords = true,
})
````

See [Color Schemes Guide](docs/schemes.md) for details.

---

## Performance

The plugin uses:
- Extmarks for non-intrusive highlights
- Debounced updates (100ms) on text changes
- Efficient lookup tables (O(1) access)
- Lazy-loading for Markdown files

Even large documents (>1000 lines) should not cause performance issues.

**Note**: `enable_inline_code` may cause slowdowns in very large files (>5000 lines).

---

## Troubleshooting

### No Highlights Visible

1. Plugin loaded?
````vim
:ColorMyAsciiDebug
````

2. Buffer is Markdown?
````vim
:set filetype?
````

3. Run health check
````vim
:checkhealth color_my_ascii
````

---

### Wrong Language Detected

Use explicit language specification:
````markdown
```ascii-c
int x = 42;
```
````

Or use a standard fence tag if the language is in `fence_language_map`:
````markdown
```vim
nnoremap <leader>w :w<CR>
```
````

Or adjust detection threshold:
````lua
require('color_my_ascii').setup({
  language_detection_threshold = 3,  -- Stricter
})
````

---

### Performance Issues

Disable features:
````lua
require('color_my_ascii').setup({
  enable_function_names = false,
  enable_inline_code = false,
})
````

---

## Contributing

Issues and pull requests are welcome. For major changes, please open an issue first.

---

### Add a New Language

1. Create file: `lua/color_my_ascii/languages/NAME.lua`
2. Define keywords:
````lua
---@module 'color_my_ascii.languages.NAME'
---@type ColorMyAscii.KeywordGroup
return {
  words = { 'keyword1', 'keyword2', ... },
  unique_words = { 'unique1', 'unique2', ... },
  hl = 'Function',
}
````

3. Reload plugin

---

### Add a New Character Group

1. Create file: `lua/color_my_ascii/groups/NAME.lua`
2. Define characters:
````lua
---@module 'color_my_ascii.groups.NAME'
---@type ColorMyAscii.CharGroup
local group = {
  chars = '',
  hl = 'Keyword',
}

local chars = { '⚡', '★', '☆' }
group.chars = table.concat(chars, '')

return group
````

3. Reload plugin

---

## Credits

- Inspired by various ASCII art highlighting plugins
- Color schemes based on popular Vim/Neovim themes
- Thanks to all contributors

---

## See Also

- [Neovim Documentation](https://neovim.io/doc/)
- [Extmarks API](https://neovim.io/doc/user/api.html#api-extmarks)
- [Markdown Syntax](https://www.markdownguide.org/basic-syntax/)

---
