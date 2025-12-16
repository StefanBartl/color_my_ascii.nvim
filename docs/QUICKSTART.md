# Quickstart Guide

Quick introduction to color_my_ascii.nvim with all important features.

## Table of content

  - [Installation](#installation)
    - [With lazy.nvim](#with-lazynvim)
    - [With packer.nvim](#with-packernvim)
  - [First Steps](#first-steps)
    - [1. Open Markdown File](#1-open-markdown-file)
    - [2. Insert ASCII Code Block](#2-insert-ascii-code-block)
  - [Basic Configuration](#basic-configuration)
    - [Minimal](#minimal)
    - [With Features](#with-features)
    - [With Color Scheme](#with-color-scheme)
  - [Feature Examples](#feature-examples)
    - [1. Language Detection](#1-language-detection)
    - [2. Custom Highlights](#2-custom-highlights)
    - [3. Function Names](#3-function-names)
    - [4. Inline Code](#4-inline-code)
    - [5. Empty Fences](#5-empty-fences)
  - [Available Color Schemes](#available-color-schemes)
    - [Load Scheme](#load-scheme)
    - [Customize Scheme](#customize-scheme)
  - [Useful Commands](#useful-commands)
  - [Typical Configurations](#typical-configurations)
    - [For Developers](#for-developers)
    - [For Documentation](#for-documentation)
    - [Minimalist](#minimalist)
    - [Maximum Features](#maximum-features)
  - [Common Issues](#common-issues)
    - [No Highlights](#no-highlights)
    - [Wrong Colors](#wrong-colors)
    - [Performance Issues](#performance-issues)
  - [Next Steps](#next-steps)
  - [Getting Help](#getting-help)
  - [See Also](#see-also)

---

## Installation

### With lazy.nvim

```lua
{
  'StefanBartl/color_my_ascii.nvim',
  ft = 'markdown',
  config = function()
    require('color_my_ascii').setup()
  end
}
```

---

### With packer.nvim

```lua
use {
  'StefanBartl/color_my_ascii.nvim',
  ft = 'markdown',
  config = function()
    require('color_my_ascii').setup()
  end
}
```

---

## First Steps

### 1. Open Markdown File

```vim
:e test.md
```

---

### 2. Insert ASCII Code Block

```ascii
┌─────────────────────┐
│  Hello World!       │
└─────────────────────┘
```

Box-drawing characters should be automatically highlighted in color.

---

## Basic Configuration

### Minimal

```lua
require('color_my_ascii').setup()
```

Automatically loads:
- 10 languages (C, C++, Lua, Go, Rust, TypeScript, Python, Bash, Zig, LLVM)
- 5 character groups (Box-Drawing, Blocks, Arrows, Symbols, Operators)

---

### With Features

```lua
require('color_my_ascii').setup({
  enable_keywords = true,              -- Highlight keywords
  enable_language_detection = true,    -- Automatic language detection
  enable_function_names = false,       -- Detect function names
  enable_bracket_highlighting = false, -- Highlight brackets
  enable_inline_code = false,          -- Highlight inline code
  treat_empty_fence_as_ascii = false,  -- ``` without language = ASCII
})
```

---

### With Color Scheme

```lua
-- Matrix style (green on black)
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
```

---

## Feature Examples

### 1. Language Detection

**Explicit**:

```ascii-c
┌──────────────┐
│ int x = 42;  │
└──────────────┘
```

**Automatic** (via keywords):

```ascii
┌─────────────────────┐
│ function counter()  │
│   local count = 0   │
│   return count      │
│ end                 │
└─────────────────────┘
```

→ Detects Lua through `function`, `local`, `end`

---

### 2. Custom Highlights

```lua
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
```

---

### 3. Function Names

```lua
require('color_my_ascii').setup({
  enable_function_names = true,
})
```

```ascii-c
┌────────────────┐
│ init()         │
│ process(data)  │
│ cleanup()      │
└────────────────┘
```

→ `init`, `process`, `cleanup` are highlighted as functions

---

### 4. Inline Code

```lua
require('color_my_ascii').setup({
  enable_inline_code = true,
})
```

```markdown
Use `func` in Go and `→` for arrows.
```
→ `func` and `→` are highlighted

---

### 5. Empty Fences

```lua
require('color_my_ascii').setup({
  treat_empty_fence_as_ascii = true,
})
```

```
┌────┐
│ OK │
└────┘
```

→ Treated like ```ascii

---

## Available Color Schemes

| Scheme | Style | Features |
|--------|-------|----------|
| `default` | Built-in highlights | Minimal, compatible |
| `matrix` | Green on black | All enabled |
| `nord` | Blue/Cyan | Function names |
| `gruvbox` | Warm/Retro | Brackets, Inline |
| `dracula` | Purple/Pink | All enabled |

---

### Load Scheme

```lua
local scheme = require('color_my_ascii.schemes.matrix')
require('color_my_ascii').setup(scheme)
```

---

### Customize Scheme

```lua
local scheme = require('color_my_ascii.schemes.nord')
scheme.enable_inline_code = true  -- Add feature
scheme.default_text_hl = 'Comment'  -- Dim text
require('color_my_ascii').setup(scheme)
```

---

## Useful Commands

```vim
" Show debug info
:ColorMyAsciiDebug

" Manually highlight
:ColorMyAscii

" Toggle plugin on/off
:ColorMyAsciiToggle

" Health check
:checkhealth color_my_ascii

" Check fence matching
:ColorMyAsciiCheckFences

" Help
:h color_my_ascii
```

---

## Typical Configurations

### For Developers

```lua
require('color_my_ascii').setup({
  enable_keywords = true,
  enable_language_detection = true,
  enable_function_names = true,
  enable_bracket_highlighting = true,
})
```

---

### For Documentation

```lua
require('color_my_ascii').setup({
  enable_inline_code = true,
  treat_empty_fence_as_ascii = true,
  default_text_hl = 'Comment',
})
```

---

### Minimalist

```lua
require('color_my_ascii').setup({
  enable_keywords = false,
  enable_language_detection = false,
  -- Only character highlighting
})
```

---

### Maximum Features

```lua
require('color_my_ascii').setup({
  enable_keywords = true,
  enable_language_detection = true,
  enable_function_names = true,
  enable_bracket_highlighting = true,
  enable_inline_code = true,
  treat_empty_fence_as_ascii = true,
  default_text_hl = 'Comment',
})
```

---

## Common Issues

### No Highlights

1. Plugin loaded?

```vim
:ColorMyAsciiDebug
```

2. Filetype correct?

```vim
:set filetype?  " Should be markdown
```

3. Syntax correct?

\```ascii  ✓ Correct
\```asci   ✗ Typo

---

### Wrong Colors

1. True color enabled?

```lua
vim.opt.termguicolors = true
```

2. Theme loads after plugin?

```lua
-- In init.lua: Load plugin BEFORE theme
```

---

### Performance Issues

Disable features:

```lua
require('color_my_ascii').setup({
  enable_function_names = false,  -- Can be slow
  enable_inline_code = false,     -- For large files
})
```

---

## Next Steps

1. **Read feature documentation**:
   - [Custom Highlights](features/custom-highlights.md)
   - [Function Detection](features/function-detection.md)
   - [Bracket Highlighting](features/bracket-highlighting.md)
   - [Inline Code](features/inline-code.md)

2. **Try test file**:
   - Open [TEST.md](TEST.md)
   - Test all features systematically

3. **Create custom scheme**:
   - Base on existing scheme
   - Customize colors
   - Save as own file

4. **Add new language**:
   - See [README.md](../README.md#contributing)

---

## Getting Help

1. **Vim Help**: `:h color_my_ascii`
2. **Health Check**: `:checkhealth color_my_ascii`
3. **Debug Info**: `:ColorMyAsciiDebug`
4. **Fence Check**: `:ColorMyAsciiCheckFences`
5. **GitHub Issues**: Open issue with details

---

## See Also

- [README.md](../README.md) - Complete documentation
- [TEST.md](TEST.md) - Test all features
- [doc/color_my_ascii.txt](../doc/color_my_ascii.txt) - Vim help

---
