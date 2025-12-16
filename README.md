# color_my_ascii.nvim

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
  - [License](#license)
  - [Credits](#credits)
  - [See Also](#see-also)

---

## Features

### Core Features

- ✅ **Automatic Detection** of `ascii` code blocks in Markdown files
- ✅ **Modular Language Definitions**: 10 predefined languages (C, C++, Lua, Go, Rust, TypeScript, Python, Bash, Zig, LLVM IR)
- ✅ **Intelligent Language Detection**:
  - Explicit via ````ascii-c`, ````ascii lua`, ````ascii:python`
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

### With lazy.nvim
````lua
{
  'StefanBartl/color_my_ascii.nvim',
  ft = 'markdown',
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
})
````

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
| Lua | `then`, `elseif`, `end` | `function`, `local`, `nil` |
| Go | `func`, `chan`, `defer` | `go`, `:=`, `<-` |
| Rust | `fn`, `mut`, `impl` | `trait`, `match`, `loop` |
| TypeScript | `interface`, `namespace` | `async`, `await`, `Promise` |
| Python | `def`, `elif`, `pass` | `lambda`, `self`, `yield` |
| Bash | `fi`, `esac`, `done` | `if`, `then`, `else` |
| Zig | `comptime`, `errdefer` | `anytype`, `unreachable` |
| LLVM IR | `getelementptr`, `phi` | `alloca`, `icmp`, `zext` |

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

```lua
-- Scheme switcher
vim.keymap.set('n', '<leader>as', '<cmd>ColorMyAsciiSchemes<cr>', {
  desc = 'Switch color scheme'
})

-- Format code blocks
vim.keymap.set('n', '<leader>af', '<cmd>ColorMyAsciiEnsureBlankLines<cr>', {
  desc = 'Format code blocks'
})

-- Show config
vim.keymap.set('n', '<leader>ac', '<cmd>ColorMyAsciiShowConfig<cr>', {
  desc = 'Show config'
})
```

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
- [Test File](docs/TEST.md) - Test all features
- [Color Schemes](docs/schemes.md) - Create custom schemes

---

### Reference

- [Vim Help](doc/color_my_ascii.txt) - Complete reference
- [Changelog](docs/CHANGELOG.md) - Version history

---

## Color Schemes

Pick one scheme from the list of [available schemes](#available-schemes) and set it in the initialization like:

Example with Matrix Scheme:

````lua
require('color_my_ascii').setup(
  scheme = "matrix",
)
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

## License

[MIT](./LICENSE)

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
