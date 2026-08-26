# Bracket Highlighting

The plugin can automatically highlight brackets and braces if they aren't already defined in character groups.

## Table of content

  - [Activation](#activation)
  - [Supported Brackets](#supported-brackets)
  - [Highlight Group](#highlight-group)
  - [How It Works](#how-it-works)
    - [Automatic Detection](#automatic-detection)
    - [Priority](#priority)
  - [Examples](#examples)
    - [C Syntax](#c-syntax)
    - [Array Access](#array-access)
    - [Nested Structures](#nested-structures)
  - [Combination with Other Features](#combination-with-other-features)
    - [With Operators Group](#with-operators-group)
    - [With Custom Highlights](#with-custom-highlights)
  - [Use Cases](#use-cases)
    - [Code Diagrams](#code-diagrams)
    - [Minimal Configuration](#minimal-configuration)
    - [Bracket Pairing Visualization](#bracket-pairing-visualization)
  - [Performance](#performance)
  - [Limitations](#limitations)
    - [No Matching Logic](#no-matching-logic)
    - [No Context Awareness](#no-context-awareness)
  - [Best Practices](#best-practices)
    - [When to Enable?](#when-to-enable)
    - [Combination with Color Schemes](#combination-with-color-schemes)
  - [Troubleshooting](#troubleshooting)
    - [Brackets Not Highlighted](#brackets-not-highlighted)
    - [Wrong Highlight Color](#wrong-highlight-color)
  - [See Also](#see-also)

---

## Activation

```lua
require('color_my_ascii').setup({
  enable_bracket_highlighting = true,
})
```

**Default**: `false` (disabled)

---

## Supported Brackets

The feature highlights the following characters:

- `(` `)` — Parentheses
- `[` `]` — Square Brackets
- `{` `}` — Curly Braces

---

## Highlight Group

Brackets are highlighted with the `Operator` highlight group.

---

## How It Works

### Automatic Detection

The plugin checks if brackets are already defined in other groups:

**Example 1**: Operators group already contains brackets

```lua
groups = {
  operators = {
    chars = "+-*/()[]{}",  -- Contains brackets
    hl = 'Operator',
  }
}
```
→ `enable_bracket_highlighting` is **ignored** (already defined)

**Example 2**: No bracket definition

```lua
groups = {
  arrows = {
    chars = "←→↑↓",  -- No brackets
    hl = 'Special',
  }
}
```
→ `enable_bracket_highlighting = true` **adds brackets**

---

### Priority

If brackets are defined in both groups and via `enable_bracket_highlighting`:

**Groups have precedence** (Overrides > Groups > enable_bracket_highlighting)

---

## Examples

### C Syntax

```ascii-c
┌──────────────────────┐
│ if (x > 0) {         │
│   result = func(x);  │
│ }                    │
└──────────────────────┘
```

**With `enable_bracket_highlighting = true`**:
- `()`, `{}` are highlighted
- `if`, `result` as keywords
- `func` as function (if `enable_function_names = true`)

---

### Array Access

```ascii
┌─────────────────┐
│ array[0] = x    │
│ matrix[i][j]    │
└─────────────────┘
```

**Result**: `[]` are highlighted

---

### Nested Structures

```ascii-go
┌──────────────────────────┐
│ map[string][]int{        │
│   "key": {1, 2, 3},      │
│ }                        │
└──────────────────────────┘
```

Result**: All `[]`, `{}` are highlighted

---

## Combination with Other Features

### With Operators Group

If you already have an operators group:

**Option 1**: Define brackets in group

```lua
require('color_my_ascii').setup({
  groups = {
    operators = {
      chars = "+-*/()[]{}",
      hl = 'Operator',
    }
  },
  enable_bracket_highlighting = false,  -- Not needed
})
```

**Option 2**: Use feature only

```lua
require('color_my_ascii').setup({
  groups = {
    operators = {
      chars = "+-*/",  -- Without brackets
      hl = 'Operator',
    }
  },
  enable_bracket_highlighting = true,  -- Adds brackets
})
```

---

### With Custom Highlights

Style brackets individually:

```lua
require('color_my_ascii').setup({
  enable_bracket_highlighting = true,
  overrides = {
    ['('] = { fg = '#ff0000' },  -- Red
    [')'] = { fg = '#ff0000' },
    ['['] = { fg = '#00ff00' },  -- Green
    [']'] = { fg = '#00ff00' },
    ['{'] = { fg = '#0000ff' },  -- Blue
    ['}'] = { fg = '#0000ff' },
  }
})
```

**Result**: Overrides take precedence → Rainbow brackets

---

## Use Cases

### Code Diagrams

Brackets are often important in code visualizations:

```lua
require('color_my_ascii').setup({
  enable_bracket_highlighting = true,
  enable_function_names = true,
  enable_keywords = true,
})
```

---

### Minimal Configuration

Only brackets, no other operators:

```lua
require('color_my_ascii').setup({
  groups = {},  -- No predefined groups
  enable_bracket_highlighting = true,
})
```

---

### Bracket Pairing Visualization

Different colors for different bracket types:

```lua
require('color_my_ascii').setup({
  enable_bracket_highlighting = false,  -- Base feature off
  overrides = {
    -- Parentheses: Yellow
    ['('] = { fg = '#ffff00', bold = true },
    [')'] = { fg = '#ffff00', bold = true },
    -- Square brackets: Cyan
    ['['] = { fg = '#00ffff', bold = true },
    [']'] = { fg = '#00ffff', bold = true },
    -- Curly braces: Magenta
    ['{'] = { fg = '#ff00ff', bold = true },
    ['}'] = { fg = '#ff00ff', bold = true },
  }
})
```

---

## Performance

The feature has **minimal overhead**:
- Brackets are inserted into lookup table at setup
- Lookup is O(1) like for all other characters
- No runtime overhead

---

## Limitations

### No Matching Logic

The feature highlights **all** brackets without checking if they match:

```
( ] { )  → All are highlighted, even if incorrectly paired
```

For matching logic, use a separate plugin like:
- `rainbow-delimiters.nvim`
- `nvim-ts-rainbow`

---

### No Context Awareness

Brackets are highlighted everywhere:

```
"text (in quotes)"  → () are highlighted (even in strings)
# comment [test]    → [] are highlighted (even in comments)
```

This is intentional, as ASCII art often exists outside normal syntax rules.

---

## Best Practices

### When to Enable?

**Enable** when:
- Code structures with brackets are visualized
- Arrays, maps, or nested structures are shown
- Function calls appear in diagrams

**Disable** when:
- No brackets appear in ASCII art
- Operators group already defines brackets
- Individual bracket styles via overrides are desired

---

### Combination with Color Schemes

Some predefined schemes already have bracket highlighting:

```lua
-- Matrix scheme has enable_bracket_highlighting = true
require('color_my_ascii').setup(
  require('color_my_ascii.schemes.matrix')
)

-- Override if desired
local matrix = require('color_my_ascii.schemes.matrix')
matrix.enable_bracket_highlighting = false
require('color_my_ascii').setup(matrix)
```

---

## Troubleshooting

### Brackets Not Highlighted

1. Feature enabled?

```lua
local config = require('color_my_ascii.config').get()
print(config.enable_bracket_highlighting)
```

2. Already defined in groups?

```lua
local lookup = require('color_my_ascii.config').char_lookup
print(lookup['('])  -- Should show highlight group
```

3. Overrides present?

```lua
local config = require('color_my_ascii.config').get()
print(vim.inspect(config.overrides))
```

---

### Wrong Highlight Color

Check priority:
1. Overrides (highest)
2. Groups
3. enable_bracket_highlighting (lowest)

Adjust accordingly:

```lua
-- Remove brackets from groups
groups = {
  operators = {
    chars = "+-*/",  -- Without ()[]{}
  }
},
-- Then enable_bracket_highlighting works
enable_bracket_highlighting = true,
```

---

## See Also

- [Custom Highlights](./custom-highlights.md)
- [Operators Group](../groups/operators.md)

---
