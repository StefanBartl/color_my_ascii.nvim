# Color Schemes

This guide explains how color schemes work and how to create your own.

## Table of content

  - [Overview](#overview)
  - [Built-in Schemes](#built-in-schemes)
    - [Default](#default)
    - [Matrix](#matrix)
    - [Nord](#nord)
    - [Gruvbox](#gruvbox)
    - [Dracula](#dracula)
  - [Loading a Scheme](#loading-a-scheme)
  - [Customizing a Scheme](#customizing-a-scheme)
  - [Creating a Custom Scheme](#creating-a-custom-scheme)
    - [Basic Structure](#basic-structure)
    - [Step-by-Step Guide](#step-by-step-guide)
      - [1. Create File](#1-create-file)
      - [2. Define Groups](#2-define-groups)
      - [3. Add Overrides (Optional)](#3-add-overrides-optional)
      - [4. Configure Features](#4-configure-features)
      - [5. Load Your Scheme](#5-load-your-scheme)
  - [Color Palette Guide](#color-palette-guide)
    - [Choosing Colors](#choosing-colors)
    - [Accessibility](#accessibility)
  - [Advanced Techniques](#advanced-techniques)
    - [Conditional Schemes](#conditional-schemes)
    - [Dynamic Colors](#dynamic-colors)
    - [Inheritance](#inheritance)
  - [Scheme Gallery](#scheme-gallery)
    - [Solarized Light](#solarized-light)
    - [Monokai](#monokai)
    - [Tokyo Night](#tokyo-night)
  - [Best Practices](#best-practices)
  - [Troubleshooting](#troubleshooting)
    - [Colors Don't Match Colorscheme](#colors-dont-match-colorscheme)
    - [Scheme Not Loading](#scheme-not-loading)
    - [Colors Look Different in Terminal](#colors-look-different-in-terminal)
  - [See Also](#see-also)

---

## Overview

A color scheme is a complete configuration that defines:
- Character group highlights
- Keyword highlights (optional)
- Custom overrides (optional)
- Feature flags
- Default highlights

---

## Built-in Schemes

### Default

```lua
require('color_my_ascii.schemes.default')
```

**Style**: Uses built-in Neovim highlight groups
**Features**: Minimal configuration, maximum compatibility
**Use case**: Default setup, compatible with any colorscheme

---

### Matrix

```lua
require('color_my_ascii.schemes.matrix')
```

**Style**: Dark with bright green (hacker style)
**Features**: All features enabled
**Colors**:
* Box-drawing: Bright green (#00ff00), bold
* Arrows: Bright green, bold
* Text: Dark green (#004400)

---

### Nord

```lua
require('color_my_ascii.schemes.nord')
```

**Style**: Cool blue/cyan colors
**Features**: Function names enabled
**Colors**:
- Box-drawing: Cyan (#88c0d0)
- Arrows: Bright cyan (#8fbcbb), bold
- Corners: Cyan, bold (custom overrides)
- Text: Dimmed gray (#616e88)

---

### Gruvbox

```lua
require('color_my_ascii.schemes.gruvbox')
```

**Style**: Warm, retro colors
**Features**: Brackets and inline code enabled
**Colors**:
- Box-drawing: Yellow (#fabd2f)
- Arrows: Red (#fb4934), bold
- Blocks: Orange (#fe8019)
- Text: Gray (#928374)

---

### Dracula

```lua
require('color_my_ascii.schemes.dracula')
```

**Style**: Vibrant purple and pink
**Features**: All features enabled
**Colors**:
- Box-drawing: Purple (#bd93f9)
- Arrows: Pink (#ff79c6), bold
- Blocks: Blue-gray (#6272a4)
- Text: Comment color (#6272a4)

---

## Loading a Scheme

```lua
-- Method 1: Direct
require('color_my_ascii').setup(
  require('color_my_ascii.schemes.matrix')
)

-- Method 2: Store in variable
local scheme = require('color_my_ascii.schemes.nord')
require('color_my_ascii').setup(scheme)
```

---

## Customizing a Scheme

```lua
-- Load scheme
local scheme = require('color_my_ascii.schemes.nord')

-- Modify settings
scheme.enable_inline_code = true
scheme.default_text_hl = 'Comment'

-- Add custom overrides
scheme.overrides = {
  ['★'] = { fg = '#ffff00', bold = true },
}

-- Apply
require('color_my_ascii').setup(scheme)
```

---

## Creating a Custom Scheme

### Basic Structure

```lua
---@module 'color_my_ascii.schemes.custom'
---@type ColorMyAscii.Config
return {
  -- Character groups
  groups = {
    box_drawing = {
      chars = "─│┌┐└┘├┤┬┴┼═║╔╗╚╝╠╣╦╩╬",
      hl = { fg = '#00ff00' },
    },
    -- Add more groups...
  },

  -- Optional: Keywords (loads from languages/ by default)
  keywords = {},

  -- Optional: Custom overrides
  overrides = {
    ['┌'] = { fg = '#ff0000', bold = true },
  },

  -- Default highlights
  default_hl = 'Normal',
  default_text_hl = nil,  -- or { fg = '#808080' }

  -- Feature flags
  enable_keywords = true,
  enable_language_detection = true,
  enable_function_names = false,
  enable_bracket_highlighting = false,
  enable_inline_code = false,
  treat_empty_fence_as_ascii = false,
}
```

---

### Step-by-Step Guide

#### 1. Create File

```bash
lua/color_my_ascii/schemes/mytheme.lua
```

---

#### 2. Define Groups

```lua
---@module 'color_my_ascii.schemes.mytheme'
---@type ColorMyAscii.Config
local scheme = {
  groups = {
    box_drawing = {
      chars = "─│┌┐└┘├┤┬┴┼═║╔╗╚╝╠╣╦╩╬╒╓╕╖╘╙╛╜╞╟╡╢╤╥╧╨╪╫╭╮╯╰╱╲╳╴╵╶╷",
      hl = { fg = '#your_color', bold = true },
    },
    blocks = {
      chars = "█▓▒░▀▄▌▐▖▗▘▝▞▟■□▪▫▬▭▮▯▰▱",
      hl = { fg = '#your_color' },
    },
    arrows = {
      chars = "←→↑↓⇐⇒⇑⇓↖↗↘↙⇖⇗⇘⇙⇠⇢⇡⇣⟵⟶⟷↰↱↲↳↴↵⤴⤵↼⇀↽⇁↶↷↺↻↔⇔⇄⇅⇆⇵➔➘➙➚➛➜➝➞➟➠➡➢➣➤➥➦➧➨",
      hl = { fg = '#your_color', bold = true },
    },
    symbols = {
      chars = "•·∙●○◦‣▸▹►▻◂◃◄◅▲△▴▵▶▷▼▽▾▿◀◁◆◇★☆✦✧✶✴✵✷✸✓✔✗✘✕✖♠♣♥♦♩♪♫♬⊕⊗⊙⊚⊛※⁂⁎⁕℃℉°∞√∑∏∫≈≠≤≥",
      hl = { fg = '#your_color' },
    },
    operators = {
      chars = "+-*/%=<>!&|^~()[]{}:;,.?\"'`@#\\",
      hl = { fg = '#your_color' },
    },
  },
}

return scheme
```

---

#### 3. Add Overrides (Optional)

```lua
scheme.overrides = {
  -- Highlight corners specially
  ['┌'] = { fg = '#ff0000', bold = true },
  ['┐'] = { fg = '#ff0000', bold = true },
  ['└'] = { fg = '#00ff00', bold = true },
  ['┘'] = { fg = '#00ff00', bold = true },

  -- Special symbols
  ['→'] = { fg = '#00ffff', bold = true },
  ['★'] = { fg = '#ffff00', bold = true },
}
```

---

#### 4. Configure Features

```lua
-- Feature flags
scheme.enable_keywords = true
scheme.enable_language_detection = true
scheme.enable_function_names = true
scheme.enable_bracket_highlighting = true
scheme.enable_inline_code = true
scheme.treat_empty_fence_as_ascii = false

-- Default highlights
scheme.default_hl = 'Normal'
scheme.default_text_hl = { fg = '#808080' }  -- Dim normal text
```

---

#### 5. Load Your Scheme

```lua
require('color_my_ascii').setup(
  require('color_my_ascii.schemes.mytheme')
)
```

---

## Color Palette Guide

### Choosing Colors

**Analogous colors** (adjacent on color wheel):
```lua
-- Blue theme
box_drawing = { fg = '#0066cc' },
arrows      = { fg = '#0099ff' },
symbols     = { fg = '#00ccff' },
```

**Complementary colors** (opposite on color wheel):
```lua
-- Blue/Orange
box_drawing = { fg = '#0066cc' },
arrows      = { fg = '#ff6600' },
```

**Monochromatic** (same hue, different saturation):
```lua
-- Green shades
box_drawing = { fg = '#00ff00' },  -- Bright
arrows      = { fg = '#00cc00' },  -- Medium
symbols     = { fg = '#009900' },  -- Dark
```

---

### Accessibility

Ensure sufficient contrast:
- Light background: Use dark colors (#000000-#666666)
- Dark background: Use light colors (#999999-#ffffff)

**Test contrast ratio**: Aim for at least 4.5:1 (WCAG AA)

---

## Advanced Techniques

### Conditional Schemes

```lua
-- Load scheme based on colorscheme
local function get_scheme()
  local colorscheme = vim.g.colors_name

  if colorscheme == 'gruvbox' then
    return require('color_my_ascii.schemes.gruvbox')
  elseif colorscheme == 'nord' then
    return require('color_my_ascii.schemes.nord')
  else
    return require('color_my_ascii.schemes.default')
  end
end

require('color_my_ascii').setup(get_scheme())
```

---

### Dynamic Colors

```lua
-- Extract colors from current colorscheme
local scheme = require('color_my_ascii.schemes.default')

local function get_hl_color(group, attr)
  local hl = vim.api.nvim_get_hl(0, { name = group })
  return hl[attr] and string.format('#%06x', hl[attr]) or nil
end

-- Use colors from current theme
scheme.groups.box_drawing.hl = {
  fg = get_hl_color('Keyword', 'fg'),
  bold = true,
}

require('color_my_ascii').setup(scheme)
```

---

### Inheritance

```lua
-- Base on existing scheme
local base = require('color_my_ascii.schemes.nord')

-- Create variant
local scheme = vim.tbl_deep_extend('force', base, {
  groups = {
    arrows = {
      chars = base.groups.arrows.chars,
      hl = { fg = '#ff0000', bold = true },  -- Override arrow color
    },
  },
})

require('color_my_ascii').setup(scheme)
```

---

## Scheme Gallery

### Solarized Light

```lua
return {
  groups = {
    box_drawing = { chars = "...", hl = { fg = '#268bd2' } },  -- Blue
    arrows      = { chars = "...", hl = { fg = '#2aa198' } },  -- Cyan
    symbols     = { chars = "...", hl = { fg = '#859900' } },  -- Green
  },
  default_text_hl = { fg = '#586e75' },  -- Base01
}
```

---

### Monokai

```lua
return {
  groups = {
    box_drawing = { chars = "...", hl = { fg = '#66d9ef' } },  -- Cyan
    arrows      = { chars = "...", hl = { fg = '#f92672' } },  -- Pink
    symbols     = { chars = "...", hl = { fg = '#a6e22e' } },  -- Green
  },
  default_text_hl = { fg = '#75715e' },  -- Comment
}
```

---

### Tokyo Night

```lua
return {
  groups = {
    box_drawing = { chars = "...", hl = { fg = '#7aa2f7' } },  -- Blue
    arrows      = { chars = "...", hl = { fg = '#bb9af7' } },  -- Purple
    symbols     = { chars = "...", hl = { fg = '#9ece6a' } },  -- Green
  },
  default_text_hl = { fg = '#565f89' },  -- Comment
}
```

---

## Best Practices

1. **Test with different backgrounds**: Ensure colors work on both light and dark backgrounds
2. **Use semantic naming**: Name schemes after their style/theme, not colors
3. **Document color choices**: Add comments explaining color palette
4. **Provide variants**: Offer light/dark versions if applicable
5. **Consider colorblindness**: Avoid red/green-only distinctions

---

## Troubleshooting

### Colors Don't Match Colorscheme

If colors clash with your colorscheme:

```lua
-- Option 1: Use built-in highlight groups
groups = {
  box_drawing = { chars = "...", hl = 'Keyword' },  -- Adapts to theme
}

-- Option 2: Extract colors dynamically (see Advanced Techniques)
```

---

### Scheme Not Loading

Check file path:

```lua
-- File: lua/color_my_ascii/schemes/mytheme.lua
-- Load: require('color_my_ascii.schemes.mytheme')
```

---

### Colors Look Different in Terminal

Enable true color:

```lua
vim.opt.termguicolors = true
```

---

## See Also

- [Custom Highlights](./features/custom-highlights.md)
- [Configuration](../README.md#configuration)

---
