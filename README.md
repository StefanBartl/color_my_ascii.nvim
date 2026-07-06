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
