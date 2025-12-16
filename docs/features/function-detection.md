# Function Detection

The plugin can automatically detect and highlight function names using pattern-based heuristics.

## Table of content

  - [Activation](#activation)
  - [How It Works](#how-it-works)
    - [Detection Rules](#detection-rules)
    - [Examples](#examples)
  - [Highlight Group](#highlight-group)
  - [Interaction with Keywords](#interaction-with-keywords)
  - [Use Cases](#use-cases)
    - [Code Flow Diagrams](#code-flow-diagrams)
    - [API Documentation](#api-documentation)
    - [Method Calls](#method-calls)
  - [Limitations](#limitations)
    - [Heuristic-Based](#heuristic-based)
    - [No Type Information](#no-type-information)
    - [Language Agnostic](#language-agnostic)
  - [Configuration Examples](#configuration-examples)
    - [With All Features](#with-all-features)
    - [Only Functions](#only-functions)
    - [Custom Function Highlight](#custom-function-highlight)
  - [Performance](#performance)
  - [Combination with Other Features](#combination-with-other-features)
    - [With Keywords](#with-keywords)
    - [With Language Detection](#with-language-detection)
    - [With Custom Highlights](#with-custom-highlights)
  - [Best Practices](#best-practices)
    - [When to Enable?](#when-to-enable)
    - [Reduce False Positives](#reduce-false-positives)
  - [Troubleshooting](#troubleshooting)
    - [Functions Not Highlighted](#functions-not-highlighted)
    - [Too Many False Positives](#too-many-false-positives)
  - [Examples](#examples-1)
    - [Before/After](#beforeafter)
  - [See Also](#see-also)

---

## Activation

```lua
require('color_my_ascii').setup({
  enable_function_names = true,
})
```

**Default**: `false` (disabled)

---

## How It Works

The plugin uses a simple heuristic to detect function names:

**Pattern**: `word followed by opening parenthesis`

```
identifier(
```

---

### Detection Rules

1. **Word character sequence** (`[%w_]+`)
2. **Optional whitespace**
3. **Opening parenthesis** `(`

---

### Examples
```c
result = calculate(x);     // "calculate" detected
process(data);             // "process" detected
obj.method(arg);           // "method" detected
func ();                   // "func" detected (with space)
```

---

## Highlight Group

Function names are highlighted with the `Function` highlight group.

---

## Interaction with Keywords

If a detected name is also a keyword, the **keyword takes precedence**:
```lua
function counter()         // "function" = keyword (not detected as function name)
  return function() end    // second "function" also keyword
end
```

This prevents false positives where language keywords appear before parentheses.

---

## Use Cases

### Code Flow Diagrams

```ascii-c
Function Call Chain:
┌─────────────────────────┐
│ result = calculate(x);  │
│ process(result);        │
│ display(result);        │
└─────────────────────────┘
```

**Result**: `calculate`, `process`, `display` highlighted as functions

---

### API Documentation

```ascii
API Structure:
┌──────────────────────┐
│ init()               │
│ configure(options)   │
│ run()                │
│ cleanup()            │
└──────────────────────┘
```

**Result**: All function names highlighted

---

### Method Calls

```ascii-java
Object Lifecycle:
┌────────────────────┐
│ obj.create()       │
│ obj.process()      │
│ obj.destroy()      │
└────────────────────┘
```

**Result**: `create`, `process`, `destroy` highlighted

---

## Limitations

### Heuristic-Based

The detection is **not syntax-aware**:

```
// False positives possible:
if (condition)        // "if" is keyword, not detected ✓
array[index]          // "array" not detected (no parenthesis) ✓
func (x)              // "func" detected (space before paren) ✓
word(text)            // "word" detected even if not a function
```

---

### No Type Information

The plugin cannot distinguish:
- Functions vs. macros
- Methods vs. constructors
- Actual functions vs. look-alike patterns

---

### Language Agnostic

Works the same for all languages:
- C/C++ functions
- Python functions
- Lua functions
- etc.

---

## Configuration Examples

### With All Features

```lua
require('color_my_ascii').setup({
  enable_keywords = true,
  enable_function_names = true,
  enable_bracket_highlighting = true,
})
```

---

### Only Functions

```lua
require('color_my_ascii').setup({
  enable_keywords = false,          -- No keyword highlighting
  enable_function_names = true,     -- Only function names
  enable_bracket_highlighting = false,
})
```

---

### Custom Function Highlight

```lua
require('color_my_ascii').setup({
  enable_function_names = true,
  -- Override Function highlight group
  overrides = {
    -- Note: This won't work directly
    -- You need to set vim highlight instead:
  }
})

-- Set custom Function highlight globally
vim.api.nvim_set_hl(0, 'Function', {
  fg = '#ff00ff',
  bold = true,
})
```

---

## Performance

Function detection has **minimal overhead**:
- Simple regex pattern match per line
- Only executed for lines in ASCII blocks
- No complex parsing or AST analysis

For typical documents (<1000 lines), impact is negligible.

---

## Combination with Other Features

### With Keywords

Keywords have **higher priority** than function names:

```lua
require('color_my_ascii').setup({
  enable_keywords = true,           -- Priority 1
  enable_function_names = true,     -- Priority 2
})
```

```c
if (check())      // "if" = keyword, "check" = function
return init()     // "return" = keyword, "init" = function
```

---

### With Language Detection

Function detection works with detected languages:

```ascii-python
def process():
    calculate()
    validate()
```

- `def` highlighted as keyword
- `process`, `calculate`, `validate` as functions

---

### With Custom Highlights

Combine with character highlights:

```lua
require('color_my_ascii').setup({
  enable_function_names = true,
  overrides = {
    ['→'] = { fg = '#00ff00' },
  }
})
```

---

## Best Practices

### When to Enable?

**Enable** when:
- Diagrams show function calls
- API documentation with function lists
- Call hierarchies or flow charts

**Disable** when:
- No function calls in ASCII art
- False positives are distracting
- Performance is critical (very large files)

---

### Reduce False Positives

1. Use explicit language markers:

```ascii-c
// C functions only
```

2. Disable for non-code diagrams:

```lua
-- Only enable for code-heavy projects
enable_function_names = false,
```

---

## Troubleshooting

### Functions Not Highlighted

1. Feature enabled?

```lua
local config = require('color_my_ascii.config').get()
print(config.enable_function_names)
```

2. Is it a keyword?

```lua
-- Keywords take precedence
-- "function" in Lua won't be detected as function name
```

3. Pattern matches?

```lua
-- Must be: word(
-- Not: word [
-- Not: word {
```

---

### Too Many False Positives

Disable the feature:

```lua
require('color_my_ascii').setup({
  enable_function_names = false,
})
```

Or use more explicit documentation:

```ascii
Functions:
- calculate()   // Explicitly marked
- process()
```

---

## Examples

### Before/After

**Without function detection**:

```
result = calculate(x);
```
- `result` = normal text
- `calculate` = normal text
- `x` = normal text

**With function detection**:
```
result = calculate(x);
```
- `result` = normal text
- `calculate` = **highlighted**
- `x` = normal text

---

## See Also

- [Language Detection](./language-detection.md)
- [Keyword Highlighting](./keyword-highlighting.md)
- [Custom Highlights](./custom-highlights.md)

---
