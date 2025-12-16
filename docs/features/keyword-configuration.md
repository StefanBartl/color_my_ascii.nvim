# Keyword Configuration

This guide explains how to customize keyword highlighting for programming languages in ASCII art blocks.

## Table of content

  - [Quick Start](#quick-start)
  - [Adding New Languages](#adding-new-languages)
    - [Word List](#word-list)
    - [Unique Words](#unique-words)
  - [Customizing Existing Languages](#customizing-existing-languages)
  - [Highlight Options](#highlight-options)
  - [Language Detection](#language-detection)
    - [Detection Threshold](#detection-threshold)
  - [Disabling Keywords](#disabling-keywords)
  - [Practical Examples](#practical-examples)
    - [Adding Swift Support](#adding-swift-support)
    - [Custom Highlight per Language](#custom-highlight-per-language)
    - [Minimal Keyword Set](#minimal-keyword-set)
  - [Language Priority](#language-priority)
  - [Common Patterns](#common-patterns)
    - [Domain-Specific Language](#domain-specific-language)
    - [Configuration Language](#configuration-language)
  - [Combining with Schemes](#combining-with-schemes)
  - [Performance Considerations](#performance-considerations)
  - [Tips](#tips)
  - [Troubleshooting](#troubleshooting)
    - [Keywords not highlighting](#keywords-not-highlighting)
    - [Wrong language detected](#wrong-language-detected)
    - [Custom language not loaded](#custom-language-not-loaded)
  - [See Also](#see-also)

---

## Quick Start

```lua
require('color_my_ascii').setup({
  enable_keywords = true,
  keywords = {
    mylang = {
      words = { 'func', 'var', 'return' },
      hl = 'Function',
    }
  }
})
```

---

## Adding New Languages

Define keywords for a language not included by default:

```lua
require('color_my_ascii').setup({
  keywords = {
    ruby = {
      words = { 'def', 'class', 'module', 'end', 'if', 'else' },
      unique_words = { 'def', 'end' },  -- For language detection
      hl = 'Function',
    }
  }
})
```

---

### Word List

The `words` array contains all keywords to highlight:

```lua
words = {
  'if', 'else', 'for', 'while',  -- Control flow
  'function', 'return',           -- Functions
  'var', 'let', 'const',          -- Variables
}
```

---

### Unique Words

`unique_words` helps with automatic language detection:

```lua
unique_words = { 'def', 'elsif', 'begin' }  -- Ruby-specific
```

These should be keywords that **uniquely identify** the language.

---

## Customizing Existing Languages

Override built-in language definitions:

```lua
require('color_my_ascii').setup({
  keywords = {
    lua = {
      words = { 'function', 'local', 'end', 'if', 'then' },
      hl = { fg = '#ff00ff', bold = true },  -- Custom color
    }
  }
})
```

This replaces the default Lua keyword configuration.

---

## Highlight Options

Keywords can use built-in or custom highlights:

```lua
-- Built-in highlight group
hl = 'Function'

-- Custom colors
hl = {
  fg = '#ff0000',
  bg = '#000000',
  bold = true,
  italic = true,
}
```

---

## Language Detection

The plugin uses `unique_words` for automatic language detection:

```ascii
┌─────────────────┐
│ def hello()     │  ← Detects Ruby (def is unique)
│   puts "Hi"     │
│ end             │
└─────────────────┘
```

---

### Detection Threshold

Control how many unique keywords are needed:

```lua
require('color_my_ascii').setup({
  enable_language_detection = true,
  language_detection_threshold = 2,  -- At least 2 unique keywords
})
```

Lower = more lenient detection, Higher = more strict detection.

---

## Disabling Keywords

Disable keyword highlighting entirely:

```lua
require('color_my_ascii').setup({
  enable_keywords = false,
})
```

Or disable for specific blocks by using explicit language markers:

```ascii-none
No keyword highlighting here
```

---

## Practical Examples

### Adding Swift Support

```lua
require('color_my_ascii').setup({
  keywords = {
    swift = {
      words = {
        'func', 'var', 'let', 'class', 'struct', 'enum',
        'if', 'else', 'guard', 'switch', 'case',
        'return', 'break', 'continue',
        'import', 'init', 'self',
      },
      unique_words = { 'func', 'guard', 'inout' },
      hl = 'Function',
    }
  }
})
```

---

### Custom Highlight per Language

```lua
require('color_my_ascii').setup({
  keywords = {
    rust = {
      words = { 'fn', 'impl', 'trait', 'mut', 'let' },
      hl = { fg = '#ff6347', bold = true },  -- Orange-red
    },
    go = {
      words = { 'func', 'package', 'import', 'type' },
      hl = { fg = '#00add8', bold = true },  -- Go blue
    },
  }
})
```

---

### Minimal Keyword Set

Only highlight most common keywords:

```lua
require('color_my_ascii').setup({
  keywords = {
    javascript = {
      words = { 'function', 'const', 'let', 'return' },
      hl = 'Function',
    }
  }
})
```

---

## Language Priority

When multiple languages match, the plugin uses:

1. **Explicit marker** (highest priority)
2. **Unique keyword count** (heuristic)
3. **First match** (fallback)

Example:

```ascii-c
int x = 42;  ← Uses C keywords (explicit)
```

```ascii
func main() {  ← Detects Go (unique keyword "func")
}
```

---

## Common Patterns

### Domain-Specific Language

```lua
require('color_my_ascii').setup({
  keywords = {
    sql = {
      words = {
        'SELECT', 'FROM', 'WHERE', 'JOIN', 'INSERT',
        'UPDATE', 'DELETE', 'CREATE', 'TABLE',
      },
      unique_words = { 'SELECT', 'FROM' },
      hl = 'Special',
    }
  }
})
```

---

### Configuration Language

```lua
require('color_my_ascii').setup({
  keywords = {
    yaml = {
      words = { 'true', 'false', 'null', 'yes', 'no' },
      unique_words = {},  -- No unique detection
      hl = 'Constant',
    }
  }
})
```

---

## Combining with Schemes

Schemes may define keywords, but you can override:

```lua
require('color_my_ascii').setup({
  scheme = 'nord',
  keywords = {
    lua = {
      words = { 'function', 'local', 'end' },
      hl = { fg = '#88c0d0', bold = true },  -- Override Nord color
    }
  }
})
```

---

## Performance Considerations

Large keyword lists don't impact performance significantly:
- Lookup is O(1) using hash tables
- Keywords are only checked in ASCII blocks
- Detection runs once per block

However, for best performance:
- Include only relevant keywords
- Use unique_words for faster detection
- Disable language detection if not needed

---

## Tips

1. **Start small** - add most common keywords first
2. **Test detection** - verify unique_words work correctly
3. **Use built-in highlights** for theme compatibility
4. **Consider case sensitivity** - keywords are case-sensitive
5. **Group related keywords** - easier to maintain

---

## Troubleshooting

### Keywords not highlighting

Check if keywords are enabled:
```lua
local config = require('color_my_ascii.config').get()
print(config.enable_keywords)
```

---

### Wrong language detected

Add more unique keywords or use explicit markers:

```ascii-rust
fn main() {}  ← Forces Rust detection
```

---

### Custom language not loaded

Verify syntax:

```lua
:lua print(vim.inspect(require('color_my_ascii.config').get().keywords))
```

---

## See Also

- [Language Detection](language-detection.md) - How detection works
- [Custom Colors](custom-colors.md) - Styling keywords
- [Built-in Languages](../languages.md) - Default language support

---
