# Custom Highlights

The plugin supports fully customizable highlight definitions with RGB/Hex colors and text styles.

## Table of content

  - [Overview](#overview)
  - [String Highlights](#string-highlights)
  - [Custom Highlight Tables](#custom-highlight-tables)
  - [Supported Color Formats](#supported-color-formats)
    - [Hex Colors](#hex-colors)
    - [Color Names](#color-names)
  - [Text Styles](#text-styles)
    - [Available Styles](#available-styles)
  - [Use Cases](#use-cases)
    - [Character-Specific Overrides](#character-specific-overrides)
    - [Default Text Highlighting](#default-text-highlighting)
    - [Combined Usage](#combined-usage)
  - [Character Groups with Custom Highlights](#character-groups-with-custom-highlights)
  - [Keyword Highlights](#keyword-highlights)
  - [Practical Examples](#practical-examples)
    - [Matrix Style (Green Hacker Look)](#matrix-style-green-hacker-look)
    - [Rainbow Corners](#rainbow-corners)
    - [Subtle Dimming Effects](#subtle-dimming-effects)
  - [Troubleshooting](#troubleshooting)
    - [Colors Not Displaying](#colors-not-displaying)
    - [Styles Not Working](#styles-not-working)
    - [Performance Issues](#performance-issues)
  - [Best Practices](#best-practices)
  - [See Also](#see-also)

---

## Overview

Highlights can be specified in two ways:

1. **String**: Name of an existing Neovim highlight group
2. **Table**: Custom definition with colors and styles

---

## String Highlights

Use existing Neovim highlight groups:

```lua
require('color_my_ascii').setup({
  overrides = {
    ['┌'] = 'Special',      -- Built-in highlight group
    ['→'] = 'Function',     -- Other highlight group
  }
})
```

Advantages:
- Compatible with colorschemes
- Automatically adapts to theme
- No additional configuration

---

## Custom Highlight Tables

Define custom colors and styles:

```lua
require('color_my_ascii').setup({
  overrides = {
    ['┌'] = {
      fg = '#ff0000',           -- Foreground color (Hex)
      bg = '#000000',           -- Background color (optional)
      bold = true,              -- Bold (optional)
      italic = false,           -- Italic (optional)
      underline = false,        -- Underline (optional)
      undercurl = false,        -- Undercurl (optional)
      strikethrough = false,    -- Strikethrough (optional)
    },
  }
})
```

---

## Supported Color Formats

### Hex Colors

```lua
fg = '#ff0000'    -- Red
fg = '#00ff00'    -- Green
fg = '#0000ff'    -- Blue
fg = '#ffffff'    -- White
fg = '#000000'    -- Black
```

---

### Color Names

The plugin uses Neovim's internal color processing, so color names work:

```lua
fg = 'red'
fg = 'blue'
fg = 'green'
```

**Note**: Hex values are more precise and portable.

---

## Text Styles

All styles can be combined:

```lua
{
  fg = '#ff0000',
  bold = true,
  italic = true,
  underline = true,
}
```

---

### Available Styles

| Style | Description | Example |
|-------|-------------|---------|
| `bold` | Bold text | `bold = true` |
| `italic` | Italic text | `italic = true` |
| `underline` | Underlined text | `underline = true` |
| `undercurl` | Wavy underline | `undercurl = true` |
| `strikethrough` | Strikethrough text | `strikethrough = true` |

---

## Use Cases

### Character-Specific Overrides

Highlight specific characters:

```lua
require('color_my_ascii').setup({
  overrides = {
    -- Corners in red and bold
    ['┌'] = { fg = '#ff0000', bold = true },
    ['┐'] = { fg = '#ff0000', bold = true },
    ['└'] = { fg = '#ff0000', bold = true },
    ['┘'] = { fg = '#ff0000', bold = true },

    -- Arrows in green
    ['→'] = { fg = '#00ff00' },
    ['←'] = { fg = '#00ff00' },

    -- Symbols in blue with underline
    ['★'] = { fg = '#0000ff', underline = true },
  }
})
```

---

### Default Text Highlighting

Dim normal text in blocks:

```lua
require('color_my_ascii').setup({
  default_text_hl = { fg = '#808080' },  -- Gray text
})
```

This achieves:
- Normal text becomes gray
- Keywords remain colorfully highlighted
- Symbols remain colorfully highlighted
- Good contrast between important and unimportant elements

---

### Combined Usage

Combine string highlights and custom highlights:

```lua
require('color_my_ascii').setup({
  overrides = {
    ['┌'] = 'Special',                    -- Built-in highlight
    ['→'] = { fg = '#00ff00', bold = true }, -- Custom
  },
  default_text_hl = 'Comment',            -- Built-in highlight
})
```

---

## Character Groups with Custom Highlights

Groups can also use custom highlights:

```lua
require('color_my_ascii').setup({
  groups = {
    box_drawing = {
      chars = "─│┌┐└┘├┤┬┴┼",
      hl = { fg = '#00ff00', bold = true },
    },
    arrows = {
      chars = "←→↑↓",
      hl = 'Special',  -- Or string
    },
  }
})
```

---

## Keyword Highlights

Keywords can also use custom highlights:

```lua
require('color_my_ascii').setup({
  keywords = {
    my_language = {
      words = { 'function', 'return', 'if' },
      hl = { fg = '#ff00ff', bold = true },
    }
  }
})
```

---

## Practical Examples

### Matrix Style (Green Hacker Look)

```lua
require('color_my_ascii').setup({
  groups = {
    box_drawing = {
      chars = "─│┌┐└┘├┤┬┴┼",
      hl = { fg = '#00ff00', bold = true },
    },
  },
  default_text_hl = { fg = '#004400' },  -- Dark green
})
```

---

### Rainbow Corners

```lua
require('color_my_ascii').setup({
  overrides = {
    ['┌'] = { fg = '#ff0000' },  -- Red
    ['┐'] = { fg = '#ff7f00' },  -- Orange
    ['└'] = { fg = '#00ff00' },  -- Green
    ['┘'] = { fg = '#0000ff' },  -- Blue
  }
})
```

---

### Subtle Dimming Effects

```lua
require('color_my_ascii').setup({
  default_text_hl = { fg = '#666666' },  -- Dimmed text
  overrides = {
    -- Important symbols bright
    ['→'] = { fg = '#ffffff', bold = true },
    ['★'] = { fg = '#ffff00', bold = true },
  }
})
```

---

## Troubleshooting

### Colors Not Displaying

1. Terminal supports true color:
```lua
vim.opt.termguicolors = true
```

2. Theme overrides custom highlights:
   - Load plugin after theme
   - Use higher priority

---

### Styles Not Working

Some terminals don't support all styles:
- `bold` and `italic` usually work
- `undercurl` requires special terminal support
- `strikethrough` isn't available everywhere

---

### Performance Issues

Custom highlights are created once at setup and cached:
- No performance penalty compared to string highlights
- Lookup is O(1)

---

## Best Practices

1. **Consistency**: Use similar colors for similar element types
2. **Contrast**: Ensure text remains readable
3. **Moderation**: Too many colors can be distracting
4. **Theme Compatibility**: Consider using string highlights when possible

---

## See Also

- [Language Detection](./language-detection.md)
- [Color Schemes](../color-schemes.md)

---
