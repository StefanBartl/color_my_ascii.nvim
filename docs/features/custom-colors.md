# Custom Colors

This guide shows how to customize colors for individual characters, groups, or keywords.

## Quick Start

```lua
require('color_my_ascii').setup({
  overrides = {
    ['┌'] = { fg = '#ff0000', bold = true },  -- Red corner
    ['→'] = 'Special',                        -- Built-in highlight
  }
})
```

## Individual Character Colors

Override specific characters with custom colors:

```lua
require('color_my_ascii').setup({
  overrides = {
    -- Custom RGB/hex colors
    ['┌'] = { fg = '#ff0000', bold = true },
    ['└'] = { fg = '#00ff00', italic = true },
    ['→'] = { fg = '#0000ff', underline = true },

    -- Built-in highlight groups
    ['★'] = 'Special',
    ['●'] = 'Keyword',
  }
})
```

## Available Style Options

Custom highlights support these properties:

```lua
{
  fg = '#ff0000',           -- Foreground color (hex)
  bg = '#000000',           -- Background color (optional)
  bold = true,              -- Bold text
  italic = true,            -- Italic text
  underline = true,         -- Underlined text
  undercurl = true,         -- Wavy underline
  strikethrough = true,     -- Strikethrough text
}
```

## Group Colors

Customize entire character groups:

```lua
require('color_my_ascii').setup({
  groups = {
    box_drawing = {
      chars = "─│┌┐└┘",
      hl = { fg = '#00ff00', bold = true },
    },
    arrows = {
      chars = "←→↑↓",
      hl = 'Special',  -- Or built-in highlight
    },
  }
})
```

## Keyword Colors

Change colors for programming language keywords:

```lua
require('color_my_ascii').setup({
  keywords = {
    lua = {
      words = { 'function', 'local', 'end' },
      hl = { fg = '#ff00ff', bold = true },
    },
    go = {
      words = { 'func', 'package', 'import' },
      hl = 'Function',
    },
  }
})
```

## Priority Order

Highlights are applied in this order (highest to lowest):

1. **Overrides** (individual characters) - highest priority
2. **Groups** (character groups)
3. **Keywords** (language keywords)
4. **Default** (fallback highlight) - lowest priority

Example showing priority:

```lua
require('color_my_ascii').setup({
  groups = {
    box_drawing = {
      chars = "─│┌┐└┘",
      hl = 'Keyword',           -- Lower priority
    },
  },
  overrides = {
    ['┌'] = 'Special',          -- Higher priority - wins!
  }
})
```

Result: `┌` uses 'Special', all other box chars use 'Keyword'.

## Default Text Color

Dim normal text to highlight important elements:

```lua
require('color_my_ascii').setup({
  default_text_hl = { fg = '#808080' },  -- Gray text
})
```

This creates better contrast:
- Normal text: dimmed (gray)
- Keywords: highlighted (colorful)
- Special chars: highlighted (colorful)

## Practical Examples

### Matrix Style (Green Corners)

```lua
require('color_my_ascii').setup({
  overrides = {
    ['┌'] = { fg = '#00ff00', bold = true },
    ['┐'] = { fg = '#00ff00', bold = true },
    ['└'] = { fg = '#00ff00', bold = true },
    ['┘'] = { fg = '#00ff00', bold = true },
  },
  default_text_hl = { fg = '#004400' },
})
```

### Rainbow Arrows

```lua
require('color_my_ascii').setup({
  overrides = {
    ['←'] = { fg = '#ff0000' },  -- Red
    ['→'] = { fg = '#00ff00' },  -- Green
    ['↑'] = { fg = '#0000ff' },  -- Blue
    ['↓'] = { fg = '#ffff00' },  -- Yellow
  }
})
```

### Language-Specific Keywords

```lua
require('color_my_ascii').setup({
  keywords = {
    rust = {
      words = { 'fn', 'impl', 'trait', 'mut' },
      hl = { fg = '#ff6347', bold = true },  -- Tomato red
    },
  }
})
```

## Combining with Schemes

Override scheme defaults:

```lua
require('color_my_ascii').setup({
  scheme = 'nord',
  overrides = {
    ['★'] = { fg = '#ffff00', bold = true },  -- Yellow star
  }
})
```

Scheme provides base colors, overrides customize specific elements.

## Tips

1. **Use hex colors** for precise control: `#ff0000` instead of `'red'`
2. **Test with real content** to verify readability
3. **Keep it simple** - too many colors can be distracting
4. **Use built-in highlights** when possible for theme compatibility
5. **Dim default text** to make highlights stand out

## Color Format

Hex colors must include the `#` prefix:

```lua
{ fg = '#ff0000' }  -- ✓ Correct
{ fg = 'ff0000' }   -- ✗ Wrong
```

## See Also

- [Schemes Documentation](../schemes.md) - Pre-configured color schemes
- [Custom Highlights](custom-highlights.md) - Advanced highlight techniques
- [Character Groups](character-groups.md) - Built-in group reference
