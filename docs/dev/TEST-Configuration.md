# Test Configuration for color_my_ascii.nvim

This configuration enables ALL features for comprehensive testing.

## Table of content

  - [Full Feature Configuration](#full-feature-configuration)
  - [Alternative: Minimal Test Configuration](#alternative-minimal-test-configuration)
  - [Alternative: Keywords Only](#alternative-keywords-only)
  - [Alternative: All Detection Features](#alternative-all-detection-features)
  - [Alternative: All Text Features](#alternative-all-text-features)
  - [Test Matrix](#test-matrix)
  - [Testing Checklist](#testing-checklist)
    - [Basic Functionality](#basic-functionality)
    - [Keywords](#keywords)
    - [Function Detection](#function-detection)
    - [Bracket Highlighting](#bracket-highlighting)
    - [Inline Code](#inline-code)
    - [Empty Fences](#empty-fences)
    - [Edge Cases](#edge-cases)
  - [Performance Testing](#performance-testing)
  - [Debug Output Example](#debug-output-example)
  - [See Also](#see-also)

---

## Full Feature Configuration

```lua
require('color_my_ascii').setup({
  -- Enable all features
  enable_keywords = true,
  enable_language_detection = true,
  enable_function_names = true,
  enable_bracket_highlighting = true,
  enable_inline_code = true,
  treat_empty_fence_as_ascii = true,

  -- Optional: Dimmed text for better contrast
  default_text_hl = 'Comment',

  -- Custom overrides for testing
  overrides = {
    ['┌'] = { fg = '#ff0000', bold = true },  -- Red corners
    ['└'] = { fg = '#00ff00', bold = true },  -- Green corners
  },
})

-- Debug function for testing inline code
local function debug_inline_code()
  local line = "Use `func`, `→`, and `:=` in Go."
  local parser = require('color_my_ascii.parser')
  local config = require('color_my_ascii.config')

  print("=== DEBUG: Inline Code ===")
  print("Line:", line)

  -- Parse inline codes
  local inline_codes = {}
  local i = 1
  while i <= #line do
    local start_pos = line:find("`", i, true)
    if not start_pos then break end

    local end_pos = line:find("`", start_pos + 1, true)
    if not end_pos then break end

    local content = line:sub(start_pos + 1, end_pos - 1)
    table.insert(inline_codes, {
      content = content,
      start_col = start_pos - 1,
      end_col = end_pos,
    })

    i = end_pos + 1
  end

  print("\nFound inline codes:", #inline_codes)
  for _, ic in ipairs(inline_codes) do
    print(string.format("  '%s' [%d-%d]", ic.content, ic.start_col, ic.end_col))

    -- Check each character
    local chars = vim.fn.split(ic.content, '\\zs')
    for _, char in ipairs(chars) do
      local hl = config.get_char_highlight(char)
      if hl then
        print(string.format("    Char '%s' -> %s", char, hl))
      end
    end

    -- Check keywords
    local tokens = parser.tokenize_line(ic.content)
    for _, token in ipairs(tokens) do
      local kw = config.get_keyword_languages(token)
      if kw then
        print(string.format("    Keyword '%s' -> %s", token, kw[1].hl))
      end
    end
  end
end

-- Debug function for brackets
local function debug_brackets()
  local config = require('color_my_ascii.config')

  print("=== DEBUG: Brackets ===")
  print("enable_bracket_highlighting:", config.get().enable_bracket_highlighting)

  local brackets = { '(', ')', '[', ']', '{', '}', '=' }
  for _, bracket in ipairs(brackets) do
    local hl = config.get_char_highlight(bracket)
    print(string.format("  '%s' -> %s", bracket, hl or "nil"))
  end
end

-- Debug function for fence checking
local function debug_fences()
  require('color_my_ascii.commands.fence_check').check_current_buffer()
end

-- Register debug commands
vim.api.nvim_create_user_command('DebugInlineCode', debug_inline_code, {})
vim.api.nvim_create_user_command('DebugBrackets', debug_brackets, {})
vim.api.nvim_create_user_command('DebugFences', debug_fences, {})

print([[
Test configuration loaded!

Debug commands:
  :DebugInlineCode  - Show inline code parsing
  :DebugBrackets    - Show bracket highlighting
  :DebugFences      - Check fence matching
  :ColorMyAsciiDebug - Show plugin status
]])
```

---

## Alternative: Minimal Test Configuration

```lua
-- Test ONLY character highlighting
require('color_my_ascii').setup({
  enable_keywords = false,
  enable_language_detection = false,
  enable_function_names = false,
  enable_bracket_highlighting = false,
  enable_inline_code = false,
  treat_empty_fence_as_ascii = false,
})
```

---

## Alternative: Keywords Only

```lua
-- Test ONLY keyword highlighting
require('color_my_ascii').setup({
  enable_keywords = true,
  enable_language_detection = true,
  enable_function_names = false,
  enable_bracket_highlighting = false,
  enable_inline_code = false,
  treat_empty_fence_as_ascii = false,
})
```

---

## Alternative: All Detection Features

```lua
-- Test detection features
require('color_my_ascii').setup({
  enable_keywords = true,
  enable_language_detection = true,
  enable_function_names = true,
  enable_bracket_highlighting = false,
  enable_inline_code = false,
  treat_empty_fence_as_ascii = false,
})
```

---

## Alternative: All Text Features

```lua
-- Test inline and text features
require('color_my_ascii').setup({
  enable_keywords = true,
  enable_language_detection = true,
  enable_function_names = true,
  enable_bracket_highlighting = true,
  enable_inline_code = true,
  treat_empty_fence_as_ascii = true,

  -- Dim normal text
  default_text_hl = { fg = '#666666' },
})
```

---

## Test Matrix

| Configuration | Keywords | Lang Detect | Functions | Brackets | Inline | Empty Fence |
|---------------|----------|-------------|-----------|----------|--------|-------------|
| Full          | ✓        | ✓           | ✓         | ✓        | ✓      | ✓           |
| Minimal       | ✗        | ✗           | ✗         | ✗        | ✗      | ✗           |
| Keywords Only | ✓        | ✓           | ✗         | ✗        | ✗      | ✗           |
| Detection     | ✓        | ✓           | ✓         | ✗        | ✗      | ✗           |
| Text Features | ✓        | ✓           | ✓         | ✓        | ✓      | ✓           |

---

## Testing Checklist

### Basic Functionality

- [ ] ASCII blocks are detected
- [ ] Box-drawing characters highlighted
- [ ] Arrows highlighted
- [ ] Symbols highlighted
- [ ] Operators highlighted

---

### Keywords

- [ ] Language-specific keywords highlighted
- [ ] Explicit language (`ascii-c`) works
- [ ] Auto-detection works
- [ ] Multiple languages in one block

---

### Function Detection

- [ ] Function names detected: `func()`
- [ ] Methods detected: `obj.method()`
- [ ] No false positives on keywords

---

### Bracket Highlighting

- [ ] Parentheses highlighted: `()`
- [ ] Square brackets highlighted: `[]`
- [ ] Curly braces highlighted: `{}`
- [ ] Priority: Overrides > Groups > Feature

---

### Inline Code

- [ ] Keywords highlighted in `` `code` ``
- [ ] Symbols highlighted in inline code
- [ ] Function names in inline code
- [ ] No highlighting outside backticks

---

### Empty Fences

- [ ] Empty fences treated as ASCII (if enabled)
- [ ] Non-ASCII blocks ignored correctly
- [ ] No false highlighting outside blocks

---

### Edge Cases

- [ ] Nested fences (non-ASCII in ASCII)
- [ ] Unclosed blocks warning
- [ ] Very long lines
- [ ] Unicode characters
- [ ] Empty blocks

---

## Performance Testing

```lua
-- Benchmark highlighting
local start = vim.loop.hrtime()
require('color_my_ascii').highlight_buffer()
local elapsed = (vim.loop.hrtime() - start) / 1e6  -- Convert to ms
print(string.format("Highlighting took %.2f ms", elapsed))
```

---

## Debug Output Example

```
=== color_my_ascii.nvim Debug Info ===
Languages loaded: 10
  bash, c, cpp, go, llvm, lua, python, rust, typescript, zig
Groups loaded: 5
  arrows, blocks, box_drawing, operators, symbols
Character lookup entries: 150+
Keyword lookup entries: 600+
Language detection: true
Keywords enabled: true
Function names enabled: true
Bracket highlighting enabled: true
Inline code enabled: true
Empty fence as ASCII: true
```

---

## See Also

- [TEST.md](./TEST.md) - Test document with examples
- [QUICKSTART.md](../QUICKSTART.md) - Quick start guide
- [README.md](../../README.md) - Full documentation

---
