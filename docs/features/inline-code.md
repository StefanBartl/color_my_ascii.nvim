# Inline Code Highlighting

The plugin can highlight keywords and symbols in inline code (`` `...` ``).

## Table of content

  - [Activation](#activation)
  - [How It Works](#how-it-works)
  - [What Gets Highlighted?](#what-gets-highlighted)
  - [Examples](#examples)
    - [Keywords](#keywords)
    - [Symbols and Arrows](#symbols-and-arrows)
    - [Operators](#operators)
    - [Function Names](#function-names)
  - [Priority](#priority)
  - [Use Cases](#use-cases)
    - [Documentation](#documentation)
  - [API Reference](#api-reference)
    - [Code Explanations](#code-explanations)
    - [Inline Diagrams](#inline-diagrams)
  - [Configuration](#configuration)
    - [With Dimmed Text](#with-dimmed-text)
    - [With All Features](#with-all-features)
    - [Only Symbols, No Keywords](#only-symbols-no-keywords)
  - [Performance](#performance)
    - [Overhead](#overhead)
    - [Debouncing](#debouncing)
  - [Limitations](#limitations)
    - [Escaped Backticks](#escaped-backticks)
    - [Nested Backticks](#nested-backticks)
    - [Code Spans Across Lines](#code-spans-across-lines)
  - [Combination with ASCII Blocks](#combination-with-ascii-blocks)
  - [Language Detection](#language-detection)
  - [Best Practices](#best-practices)
    - [When to Enable?](#when-to-enable)
    - [Combination with Colorschemes](#combination-with-colorschemes)
    - [With default_text_hl](#with-default_text_hl)
  - [Troubleshooting](#troubleshooting)
    - [Inline Code Not Highlighted](#inline-code-not-highlighted)
    - [Too Many False Positives](#too-many-false-positives)
    - [Performance Issues](#performance-issues)
  - [See Also](#see-also)

---

## Activation

```lua
require('color_my_ascii').setup({
  enable_inline_code = true,
})
```

**Default**: `false` (disabled)

---

## How It Works

The plugin scans Markdown lines for inline code segments between backticks and applies the same highlighting rules as for ASCII blocks.

---

## What Gets Highlighted?

In inline code, the following elements are recognized:

1. **Special Characters**: From character groups (arrows, symbols, etc.)
2. **Keywords**: From all loaded languages
3. **Function Names**: If `enable_function_names = true`
4. **Operators**: If defined in character groups

---

## Examples

### Keywords

```markdown
Use `func` for functions in Go and `local` in Lua.
```

**Result**:
- `func` → Go keyword, highlighted
- `local` → Lua keyword, highlighted

---

### Symbols and Arrows

```markdown
Data flow: `A → B → C` with checkpoint `★`.
```

**Result**:
- `→` → Arrow, highlighted (Special)
- `★` → Symbol, highlighted (Delimiter)

---

### Operators

```markdown
Go uses `:=` for declarations and `<-` for channels.
```

**Result**:
- `:=` → Go operator
- `<-` → Go operator

---

### Function Names

```markdown
Use `calculate(x)` for computation.
```

**With `enable_function_names = true`**:
- `calculate` → highlighted as function

---

## Priority

The highlighting priority in inline code is identical to ASCII blocks:

1. `default_text_hl` (lowest, if set)
2. Character highlights
3. Function names
4. Keywords (highest)

---

## Use Cases

### Documentation

Inline code in technical documentation:

```markdown
## API Reference

The function `init()` initializes the system.
Use `→` for references and `★` for important points.
```

---

### Code Explanations

```markdown
In Rust, use `fn` instead of `function` and `let` instead of `var`.
The operator `::` separates namespaces, `->` shows return types.
```

---

### Inline Diagrams

```markdown
Flow: `start → process → end`

States: `idle ● running ● done ✓`
```

---

## Configuration

### With Dimmed Text

```lua
require('color_my_ascii').setup({
  enable_inline_code = true,
  default_text_hl = { fg = '#808080' },  -- Gray text
})
```

**Result**: Normal text in inline code becomes gray, keywords remain colorful.

---

### With All Features

```lua
require('color_my_ascii').setup({
  enable_inline_code = true,
  enable_function_names = true,
  enable_bracket_highlighting = true,
  enable_keywords = true,
})
```

---

### Only Symbols, No Keywords

```lua
require('color_my_ascii').setup({
  enable_inline_code = true,
  enable_keywords = false,  -- Keywords off
})
```

**Result**: Only symbols (→, ★, etc.) are highlighted, no words.

---

## Performance

### Overhead

Inline code highlighting scans **every line** in the buffer:
- O(n) for number of lines
- O(m) for line length
- Efficient through pattern matching

**Recommendation**: For very large documents (>5000 lines), consider disabling the feature.

---

### Debouncing

Like ASCII blocks, inline code highlighting is also debounced:
- 100ms delay after text change
- Prevents flickering while typing

---

## Limitations

### Escaped Backticks

Escaped backticks are not handled correctly:

```markdown
Use \`code\` for inline  → Not recognized as inline code
```

This is a limitation of the current parser.

---

### Nested Backticks

Not supported:

```markdown
``nested `code` here``  → Does not work correctly
```

---

### Code Spans Across Lines

Inline code spanning multiple lines is not recognized:

```markdown
`start
end`  → Not recognized as inline code
```

This is intentional, as Markdown inline code is typically single-line.

---

## Combination with ASCII Blocks

Both features can be active simultaneously:

Flow Diagram:

```ascii
┌──────┐
│ Start│ → Process → End
└──────┘

Use `→` for arrows.
```

**Result**:
- ASCII block: All elements highlighted
- Inline `→`: Also highlighted

---

## Language Detection

Unlike ASCII blocks, there is **no language detection** for inline code:

**Reason**: Inline code is too short for reliable heuristic analysis.

**Consequence**: All keywords from all languages are checked.

Example:

```markdown
`func` and `function` are both highlighted (Go and Lua).
```

---

## Best Practices

### When to Enable?

**Enable** when:
- Documentation contains many inline code examples
- Keywords and symbols in prose should be highlighted
- Consistent highlighting between blocks and inline code is desired

**Disable** when:
- Documentation is very large (>5000 lines)
- Inline code mainly contains variables/placeholders (no keywords)
- Performance is critical

---

### Combination with Colorschemes

```lua
-- Matrix scheme has enable_inline_code = true
require('color_my_ascii').setup(
  require('color_my_ascii.schemes.matrix')
)
```

Custom adjustment:

```lua
local config = require('color_my_ascii.schemes.nord')
config.enable_inline_code = true  -- If disabled in scheme
require('color_my_ascii').setup(config)
```

---

### With default_text_hl

For better readability:

```lua
require('color_my_ascii').setup({
  enable_inline_code = true,
  default_text_hl = 'Comment',  -- Dimmed text
})
```

**Effect**: Keywords stand out more clearly.

---

## Troubleshooting

### Inline Code Not Highlighted

1. Feature enabled?

```lua
local config = require('color_my_ascii.config').get()
print(config.enable_inline_code)
```

2. Buffer is Markdown?

```vim
:set filetype?
```

3. Backticks correct?

```markdown
`code`  ✓ Works
'code'  ✗ Wrong quotes
```

---

### Too Many False Positives

Inline code highlights all possible keywords:

**Solution 1**: Disable keywords

```lua
require('color_my_ascii').setup({
  enable_inline_code = true,
  enable_keywords = false,  -- Only symbols
})
```

**Solution 2**: Disable feature

```lua
require('color_my_ascii').setup({
  enable_inline_code = false,
})
```

---

### Performance Issues

For very large files:

1. Disable feature
2. Or: Only activate for specific buffers

```lua
vim.api.nvim_create_autocmd('BufEnter', {
  pattern = '*.md',
  callback = function()
    local lines = vim.api.nvim_buf_line_count(0)
    if lines < 1000 then
      -- Only activate for small files
      require('color_my_ascii.config').get().enable_inline_code = true
    end
  end
})
```

---

## See Also

- [Language Detection](./language-detection.md)
- [Function Detection](./function-detection.md)
- [Performance](../performance.md)

---
