# Changelog

## Table of content

  - [v0.2.0 (Upcoming)](#v020-upcoming)
    - [Major Changes](#major-changes)
      - [Simplified Scheme Loading](#simplified-scheme-loading)
      - [New Color Schemes](#new-color-schemes)
    - [Documentation](#documentation)
      - [English Documentation](#english-documentation)
      - [New Feature Guides](#new-feature-guides)
      - [Updated Documentation](#updated-documentation)
    - [Files Changed](#files-changed)
      - [New Files](#new-files)
      - [Modified Files](#modified-files)
    - [Breaking Changes](#breaking-changes)
    - [Migration Guide](#migration-guide)
      - [From v0.1.x to v0.2.0](#from-v01x-to-v020)
    - [New Examples](#new-examples)
      - [Using New Schemes](#using-new-schemes)
      - [Custom Colors (New Documentation)](#custom-colors-new-documentation)
    - [Internal Changes](#internal-changes)
    - [Testing](#testing)
    - [Next Steps (v0.3.0)](#next-steps-v030)
  - [v0.1.0 (Initial Release)](#v010-initial-release)
    - [Features](#features)
    - [Supported Languages](#supported-languages)
    - [Color Schemes](#color-schemes)

---

## v0.2.0 (Upcoming)

### Major Changes

#### Simplified Scheme Loading
- **Added**: `scheme_loader.lua` module for loading schemes by name
- **Changed**: `config.lua` now supports `scheme` parameter
- **New syntax**: `require('color_my_ascii').setup({ scheme = 'nord' })`
- **Backward compatible**: Old syntax still works

```lua
-- Old (still works)
require('color_my_ascii').setup(require('color_my_ascii.schemes.nord'))

-- New (simplified)
require('color_my_ascii').setup({ scheme = 'nord' })
```

#### New Color Schemes

Added 5 new professionally designed color schemes:

- **catppuccin**: Soft pastel colors with warm undertones
- **tokyonight**: Deep blue night colors with vibrant accents
- **solarized**: Precision colors for readability (dark variant)
- **onedark**: Atom-inspired dark theme
- **monokai**: High contrast neon colors

Total schemes: 10 (was 5)

### Documentation

#### English Documentation
- **Translated**: All existing German docs to English
- **Created**: `README.md` (English version)
- **Updated**: All feature documentation in English

#### New Feature Guides
- **Added**: `docs/features/custom-colors.md` - How to color individual chars/groups
- **Added**: `docs/features/keyword-configuration.md` - Keyword group customization
- **Added**: `docs/features/group-configuration.md` - Character group configuration

#### Updated Documentation
- **Updated**: `README.md` - English version with new schemes
- **Updated**: `README-de.md` - German version with new schemes
- **Improved**: All examples and code snippets

### Files Changed

#### New Files
```
lua/color_my_ascii/scheme_loader.lua
lua/color_my_ascii/schemes/catppuccin.lua
lua/color_my_ascii/schemes/tokyonight.lua
lua/color_my_ascii/schemes/solarized.lua
lua/color_my_ascii/schemes/onedark.lua
lua/color_my_ascii/schemes/monokai.lua
docs/features/custom-colors.md
docs/features/keyword-configuration.md
docs/features/group-configuration.md
README.md (English)
README-de.md (German)
CHANGELOG.md
```

#### Modified Files
```
lua/color_my_ascii/config.lua (Added scheme loading support)
```

### Breaking Changes

**None** - All changes are backward compatible.

### Migration Guide

#### From v0.1.x to v0.2.0

No migration needed. Old configuration syntax still works:

```lua
-- v0.1.x syntax (still works)
require('color_my_ascii').setup(
  require('color_my_ascii.schemes.nord')
)

-- v0.2.0 syntax (recommended)
require('color_my_ascii').setup({ scheme = 'nord' })
```

### New Examples

#### Using New Schemes

```lua
-- Catppuccin - soft pastels
require('color_my_ascii').setup({ scheme = 'catppuccin' })

-- Tokyo Night - deep blue
require('color_my_ascii').setup({ scheme = 'tokyonight' })

-- Solarized - precision colors
require('color_my_ascii').setup({ scheme = 'solarized' })

-- One Dark - Atom-inspired
require('color_my_ascii').setup({ scheme = 'onedark' })

-- Monokai - high contrast
require('color_my_ascii').setup({ scheme = 'monokai' })
```

#### Custom Colors (New Documentation)

```lua
-- Individual character colors
require('color_my_ascii').setup({
  overrides = {
    ['┌'] = { fg = '#ff0000', bold = true },
  }
})

-- Group colors
require('color_my_ascii').setup({
  groups = {
    box_drawing = {
      chars = "─│┌┐└┘",
      hl = { fg = '#00ff00' },
    }
  }
})

-- Keyword colors
require('color_my_ascii').setup({
  keywords = {
    lua = {
      words = { 'function', 'local' },
      hl = { fg = '#ff00ff', bold = true },
    }
  }
})
```

### Internal Changes

- **Improved**: Error handling in scheme loader
- **Added**: Validation for scheme names
- **Added**: Helpful error messages for invalid schemes
- **Enhanced**: Scheme loading performance

### Testing

All new features have been tested with:
- ✅ Existing schemes still load correctly
- ✅ New schemes load via string identifier
- ✅ Old syntax remains functional
- ✅ Custom overrides work with scheme loading
- ✅ Documentation examples are accurate

### Next Steps (v0.3.0)

See `docs/v0.3.0.md` for planned features:
- Safe API integration
- Additional language support
- Performance optimizations
- Extended color scheme options

---

## v0.1.0 (Initial Release)

### Features
- ASCII art highlighting in Markdown
- 10 language definitions
- 5 character groups
- 5 color schemes
- Language detection
- Function name detection
- Bracket highlighting
- Inline code highlighting

### Supported Languages
- C, C++, Lua, Go, Rust
- TypeScript, Python, Bash
- Zig, LLVM IR

### Color Schemes
- Default, Matrix, Nord
- Gruvbox, Dracula
