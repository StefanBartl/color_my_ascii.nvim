# Group Configuration

This guide explains how to configure and customize character groups for ASCII art highlighting.

## Table of content

  - [What are Groups?](#what-are-groups)
  - [Quick Start](#quick-start)
  - [Customizing Existing Groups](#customizing-existing-groups)
  - [Creating New Groups](#creating-new-groups)
  - [Group Definition Structure](#group-definition-structure)
    - [Characters String](#characters-string)
    - [Highlight Specification](#highlight-specification)
  - [Practical Examples](#practical-examples)
    - [Minimal Box Drawing](#minimal-box-drawing)
    - [Extended Unicode Blocks](#extended-unicode-blocks)
    - [Mathematical Symbols](#mathematical-symbols)
    - [Currency Symbols](#currency-symbols)
    - [Emoji Support](#emoji-support)
  - [Combining Groups](#combining-groups)
  - [Group Priority](#group-priority)
  - [Overrides vs Groups](#overrides-vs-groups)
  - [Disabling Built-in Groups](#disabling-built-in-groups)
  - [Extending Built-in Groups](#extending-built-in-groups)
  - [Building Character Strings](#building-character-strings)
  - [Theme Compatibility](#theme-compatibility)
  - [Performance](#performance)
  - [Tips](#tips)
  - [Common Use Cases](#common-use-cases)
    - [Programming Diagrams](#programming-diagrams)
    - [Flow Charts](#flow-charts)
    - [Network Diagrams](#network-diagrams)
  - [See Also](#see-also)

---

## What are Groups?

Groups are collections of related characters that share the same highlight style:

- **box_drawing**: `─│┌┐└┘├┤┬┴┼`
- **blocks**: `█▓▒░▀▄▌▐`
- **arrows**: `←→↑↓⇐⇒⇑⇓`
- **symbols**: `•★☆✓✔✗✘`
- **operators**: `+-*/%=<>!&|`

---

## Quick Start

```lua
require('color_my_ascii').setup({
  groups = {
    box_drawing = {
      chars = "─│┌┐└┘",
      hl = { fg = '#00ff00', bold = true },
    }
  }
})
```

---

## Customizing Existing Groups

Override built-in group definitions:

```lua
require('color_my_ascii').setup({
  groups = {
    arrows = {
      chars = "←→↑↓",              -- Subset of arrows
      hl = { fg = '#ff0000' },     -- Red color
    },
    symbols = {
      chars = "★☆✓✔",              -- Custom selection
      hl = 'Special',              -- Built-in highlight
    },
  }
})
```

---

## Creating New Groups

Add custom groups for specific use cases:

```lua
require('color_my_ascii').setup({
  groups = {
    my_stars = {
      chars = "★☆✦✧✶",
      hl = { fg = '#ffff00', bold = true },
    },
    my_math = {
      chars = "∑∏∫√∞",
      hl = { fg = '#00ffff', italic = true },
    },
  }
})
```

---

## Group Definition Structure

Each group requires two properties:

```lua
{
  chars = "string_of_characters",  -- Characters in the group
  hl = "HighlightGroup" or { }     -- Highlight specification
}
```

---

### Characters String

The `chars` field contains all characters for this group:

```lua
chars = "─│┌┐└┘├┤┬┴┼"  -- No separators needed
```

Characters can be:
- ASCII: `+-*/`
- Unicode: `→←↑↓`
- Emojis: `😀😃😄`
- Any UTF-8 character

---

### Highlight Specification

Two options for `hl`:

#### Built-in highlight group

```lua
hl = 'Keyword'
hl = 'Function'
hl = 'Special'
```

#### Custom colors

```lua
hl = {
  fg = '#ff0000',
  bg = '#000000',
  bold = true,
  italic = true,
  underline = true,
}
```

---

## Practical Examples

### Minimal Box Drawing

Only corners and lines:

```lua
require('color_my_ascii').setup({
  groups = {
    box_drawing = {
      chars = "─│┌┐└┘",
      hl = 'Keyword',
    }
  }
})
```

---

### Extended Unicode Blocks

```lua
require('color_my_ascii').setup({
  groups = {
    blocks = {
      chars = "█▓▒░▀▄▌▐▖▗▘▝▞▟■□▪▫",
      hl = { fg = '#00ff00' },
    }
  }
})
```

---

### Mathematical Symbols

```lua
require('color_my_ascii').setup({
  groups = {
    math = {
      chars = "∑∏∫√∞≈≠≤≥±×÷",
      hl = { fg = '#00ffff', bold = true },
    }
  }
})
```

---

### Currency Symbols

```lua
require('color_my_ascii').setup({
  groups = {
    currency = {
      chars = "$€£¥₹₽¢",
      hl = { fg = '#ffff00', bold = true },
    }
  }
})
```

---

### Emoji Support

```lua
require('color_my_ascii').setup({
  groups = {
    emoji = {
      chars = "😀😃😄😁😅😂🤣",
      hl = { fg = '#ff69b4' },
    }
  }
})
```

---

## Combining Groups

Multiple groups can be defined together:

```lua
require('color_my_ascii').setup({
  groups = {
    box_drawing = {
      chars = "─│┌┐└┘├┤┬┴┼",
      hl = 'Keyword',
    },
    arrows = {
      chars = "←→↑↓",
      hl = 'Special',
    },
    symbols = {
      chars = "★☆✓✔",
      hl = 'Function',
    },
  }
})
```

---

## Group Priority

When characters overlap between groups, the **last defined group wins**:

```lua
require('color_my_ascii').setup({
  groups = {
    group1 = {
      chars = "★☆",
      hl = 'Keyword',      -- Lower priority
    },
    group2 = {
      chars = "★",         -- Overlaps with group1
      hl = 'Special',      -- Higher priority - wins!
    },
  }
})
```

Result: `★` uses 'Special', `☆` uses 'Keyword'.

---

## Overrides vs Groups

Use **overrides** for individual characters:

```lua
require('color_my_ascii').setup({
  groups = {
    box_drawing = {
      chars = "─│┌┐└┘",
      hl = 'Keyword',
    }
  },
  overrides = {
    ['┌'] = 'Special',  -- Override just the top-left corner
  }
})
```

Overrides have **higher priority** than groups.

---

## Disabling Built-in Groups

Replace all built-in groups:

```lua
require('color_my_ascii').setup({
  groups = {
    my_group = {
      chars = "─│┌┐",
      hl = 'Keyword',
    }
  }
})
```

This disables all default groups and uses only your custom groups.

---

## Extending Built-in Groups

Load defaults, then add custom groups:

```lua
local config = require('color_my_ascii.schemes.default')

config.groups.my_custom = {
  chars = "★☆✦✧",
  hl = { fg = '#ffff00' },
}

require('color_my_ascii').setup(config)
```

---

## Building Character Strings

For readability, build complex char strings:

```lua
local box_chars = {
  -- Light box drawing
  "─", "│", "┌", "┐", "└", "┘",
  -- Heavy box drawing
  "═", "║", "╔", "╗", "╚", "╝",
}

require('color_my_ascii').setup({
  groups = {
    box_drawing = {
      chars = table.concat(box_chars, ""),
      hl = 'Keyword',
    }
  }
})
```

---

## Theme Compatibility

Use built-in highlights for automatic theme adaptation:

```lua
require('color_my_ascii').setup({
  groups = {
    box_drawing = {
      chars = "─│┌┐└┘",
      hl = 'Keyword',  -- Adapts to colorscheme
    }
  }
})
```

---

## Performance

Groups are converted to lookup tables at setup:
- O(1) character lookup
- No runtime overhead
- Efficient even with large groups

Large groups (hundreds of characters) are fine:

```lua
groups = {
  all_unicode = {
    chars = "...1000+ characters...",
    hl = 'Keyword',
  }
}
```

---

## Tips

1. **Group related characters** - easier to maintain
2. **Use meaningful names** - self-documenting
3. **Test with real content** - verify coverage
4. **Consider overlaps** - last definition wins
5. **Start with defaults** - extend rather than replace

---

## Common Use Cases

### Programming Diagrams

```lua
groups = {
  box_drawing = { chars = "─│┌┐└┘├┤┬┴┼", hl = 'Keyword' },
  arrows = { chars = "→←↑↓", hl = 'Special' },
  operators = { chars = "+-*/=<>", hl = 'Operator' },
}
```

---

### Flow Charts

```lua
groups = {
  shapes = { chars = "○□◇△▽", hl = 'Type' },
  connections = { chars = "─│├┤┬┴┼", hl = 'Keyword' },
  arrows = { chars = "→↓←↑", hl = 'Special' },
}
```

---

### Network Diagrams

```lua
groups = {
  nodes = { chars = "●○◉◎", hl = 'Function' },
  connections = { chars = "─│╱╲", hl = 'Keyword' },
  arrows = { chars = "→←↔", hl = 'Special' },
}
```

---

## See Also

- [Custom Colors](./custom-colors.md) - Individual character colors
- [Custom Highlights](./custom-highlights.md) - Advanced styling

---
