# color_my_ascii.nvim

A Neovim plugin for syntax highlighting ASCII art in Markdown code blocks with automatic language detection, custom highlights, and predefined color schemes.

## Features

### Core Features

- ✅ **Automatic Detection** of `ascii` code blocks in Markdown files
- ✅ **Modular Language Definitions**: 10 predefined languages (C, C++, Lua, Go, Rust, TypeScript, Python, Bash, Zig, LLVM IR)
- ✅ **Intelligent Language Detection**:
  - Explicit via ````ascii-c`, ````ascii lua`, ````ascii:python`
  - Heuristic detection based on keyword frequency
  - Fallback to buffer filetype
- ✅ **Modular Character Groups**: Customizable groups for lines, blocks, arrows, symbols, operators
- ✅ **Custom Highlights with RGB/Hex**: Full color and style control
- ✅ **10 Predefined Color Schemes**: Default, Matrix, Nord, Gruvbox, Dracula, Catppuccin, Tokyo Night, Solarized, One Dark, Monokai
- ✅ **Non-intrusive**: Uses extmarks, no buffer modification

---

### Advanced Features

- ✅ **Function Name Detection**: Heuristic for `word()` patterns
- ✅ **Bracket Highlighting**: Automatic highlighting of `()[]{}`
- ✅ **Inline Code Highlighting**: Keywords and symbols in `` `...` ``
- ✅ **Empty Fenced Blocks**: Optional ``` without language as ASCII
- ✅ **Default Text Color**: Dimmed display for normal text
- ✅ **Health Check**: `:checkhealth color_my_ascii`
- ✅ **Vim Help**: `:h color_my_ascii`

---

## Installation

### With lazy.nvim

```lua
{
  'StefanBartl/color_my_ascii.nvim',
  ft = 'markdown',
  opts = {
    -- Optional: Configuration here
  }
}
```

---

### With packer.nvim

```lua
use {
  'StefanBartl/color_my_ascii.nvim',
  ft = 'markdown',
  config = function()
    require('color_my_ascii').setup({
      -- Optional: Configuration here
    })
  end
}
```

---

## Quick Start

### Minimal Setup

```lua
require('color_my_ascii').setup()
```

The plugin activates automatically for Markdown files.

---

### Example

```ascii
┌─────────────────────┐
│  Hello World!       │
└─────────────────────┘
```

→ Box characters are automatically highlighted

---

## Configuration

### Default Configuration

```lua
require('color_my_ascii').setup({
  -- Character-specific overrides (highest priority)
  overrides = {},

  -- Default highlighting for unmapped characters
  default_hl = 'Normal',

  -- Optional: Default highlighting for normal text in blocks
  default_text_hl = nil,  -- e.g. 'Comment' for dimmed display

  -- Feature toggles
  enable_keywords = true,
  enable_language_detection = true,
  language_detection_threshold = 2,
  enable_function_names = false,
  enable_bracket_highlighting = false,
  treat_empty_fence_as_ascii = false,
  enable_inline_code = false,
})
```

---

### With Color Scheme

```lua
-- Simplified scheme loading
require('color_my_ascii').setup({ scheme = 'matrix' })
require('color_my_ascii').setup({ scheme = 'nord' })
require('color_my_ascii').setup({ scheme = 'catppuccin' })

-- Or load scheme module directly
require('color_my_ascii').setup(
  require('color_my_ascii.schemes.gruvbox')
)
```

---

### Custom Highlights

```lua
require('color_my_ascii').setup({
  overrides = {
    -- String: Built-in highlight group
    ['┌'] = 'Special',

    -- Table: Custom definition with RGB/hex
    ['└'] = { fg = '#ff0000', bold = true },
    ['→'] = { fg = '#00ff00', italic = true },
  },

  -- Dimmed text in blocks
  default_text_hl = { fg = '#808080' },
})
```

---

### All Features Enabled

```lua
require('color_my_ascii').setup({
  scheme = 'tokyonight',
  enable_keywords = true,
  enable_language_detection = true,
  enable_function_names = true,
  enable_bracket_highlighting = true,
  treat_empty_fence_as_ascii = true,
  enable_inline_code = true,
  default_text_hl = 'Comment',
})
```

---

## Supported Languages

The plugin includes predefined keyword definitions for:

| Language | Unique Keywords | Examples |
|---------|----------------|----------|
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

Additional languages can be easily added (see [Documentation](docs/features/)).

---

## Commands

| Command | Description |
|--------|--------------|
| `:ColorMyAscii` | Manually update highlighting |
| `:ColorMyAsciiToggle` | Enable/disable plugin |
| `:ColorMyAsciiDebug` | Show debug information |
| `:checkhealth color_my_ascii` | Run health check |
| `:h color_my_ascii` | Open Vim help |

---

## Documentation

### Features

- [Custom Colors](docs/features/custom-colors.md) - RGB/hex colors and styles
- [Keyword Configuration](docs/features/keyword-configuration.md) - Language keyword setup
- [Group Configuration](docs/features/group-configuration.md) - Character group customization
- [Custom Highlights](docs/features/custom-highlights.md) - Advanced highlighting
- [Function Detection](docs/features/function-detection.md) - Automatic function name detection
- [Bracket Highlighting](docs/features/bracket-highlighting.md) - Bracket highlighting
- [Inline Code](docs/features/inline-code.md) - Highlighting in `` `...` ``

---

### Guides

- [Quickstart](docs/QUICKSTART.md) - Getting started
- [Test File](docs/TEST.md) - Test all features

---

### Reference

- [Vim Help](doc/color_my_ascii.txt) - Complete reference

---

## Color Schemes

### Available Schemes

| Scheme | Style | Features |
|--------|------|----------|
| `default` | Built-in highlights | Minimal, compatible |
| `matrix` | Green on black | All features |
| `nord` | Blue/cyan | Function names |
| `gruvbox` | Warm/retro | Brackets, inline |
| `dracula` | Purple/pink | All features |
| `catppuccin` | Soft pastels | Function names, inline |
| `tokyonight` | Deep blue night | All features |
| `solarized` | Precision colors | Minimal |
| `onedark` | Atom-inspired | All features |
| `monokai` | High contrast | All features |

---

### Loading Schemes

```lua
-- Simple string identifier
require('color_my_ascii').setup({ scheme = 'catppuccin' })

-- Or load module directly
require('color_my_ascii').setup(
  require('color_my_ascii.schemes.tokyonight')
)
```

---

### Customizing Schemes

```lua
require('color_my_ascii').setup({
  scheme = 'nord',
  enable_inline_code = true,  -- Enable feature
  default_text_hl = 'Comment',  -- Dim text
  overrides = {
    ['★'] = { fg = '#ffff00', bold = true },  -- Custom override
  }
})
```

---

### Creating Custom Schemes

```lua
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
```

---

## Performance

The plugin uses:
- Extmarks for non-intrusive highlights
- Debounced updates (100ms) on text changes
- Efficient lookup tables (O(1) access)
- Lazy-loading for Markdown files

Even large documents (>1000 lines) should not cause performance issues.

**Note**: `enable_inline_code` can slow down very large files (>5000 lines).

---

## Troubleshooting

### No Highlights Visible

1. Plugin loaded?
```vim
:ColorMyAsciiDebug
```

2. Buffer is Markdown?
```vim
:set filetype?
```

3. Run health check
```vim
:checkhealth color_my_ascii
```

---

### Wrong Language Detected

Use explicit language specification:

```ascii-c
int x = 42;
```

Or adjust detection threshold:


```lua
require('color_my_ascii').setup({
  language_detection_threshold = 3,  -- More strict
})
```

---

### Performance Issues

Disable features:

```lua
require('color_my_ascii').setup({
  enable_function_names = false,
  enable_inline_code = false,
})
```

---

## Contributing

Issues and pull requests are welcome. For major changes, please open an issue first.

---

### Adding a New Language

1. Create file: `lua/color_my_ascii/languages/NAME.lua`
2. Define keywords:

```lua
---@module 'color_my_ascii.languages.NAME'
---@type ColorMyAscii.KeywordGroup
return {
  words = { 'keyword1', 'keyword2', ... },
  unique_words = { 'unique1', 'unique2', ... },
  hl = 'Function',
}
```

3. Reload plugin

---

### Adding a New Character Group

1. Create file: `lua/color_my_ascii/groups/NAME.lua`
2. Define characters:

```lua
---@module 'color_my_ascii.groups.NAME'
---@type ColorMyAscii.CharGroup
local group = {
  chars = '',
  hl = 'Keyword',
}

local chars = { '⚡', '★', '☆' }
group.chars = table.concat(chars, '')

return group
```

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

