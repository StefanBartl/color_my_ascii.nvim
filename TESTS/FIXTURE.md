# Test file for color_my_ascii.nvim

This document tests all of the plugin's features systematically.

## Test 1: simple ASCII art without a language

```ascii
┌─────────────────────┐
│  Hello World!       │
└─────────────────────┘
```

**Expectation**: box characters get highlighted (keyword group)

---

## Test 2: ASCII art with an explicit language (C)

```ascii-c
Struct in memory:
┌─────────────────────────────────────┐
│ int id          (4 bytes)           │
├─────────────────────────────────────┤
│ char* name      (8 bytes)           │
├─────────────────────────────────────┤
│ void* data      (8 bytes)           │
└─────────────────────────────────────┘
```

**Expectation**: keywords `int`, `char`, `void` get highlighted (function group)

---

## Test 3: ASCII art with automatic language detection (Lua)

```ascii
Lua Closure:
┌─────────────────────┐
│ function counter()  │
│   local count = 0   │
│   return function() │
│     count = count+1 │
│     return count    │
│   end               │
│ end                 │
└─────────────────────┘
```

**Expectation**: keywords `function`, `local`, `return`, `end` get highlighted

---

## Test 4: arrows and symbols

```ascii
Process Flow:
┌────────┐     ┌────────┐     ┌────────┐
│ Start  │ ──→ │ Middle │ ──→ │  End   │
└────────┘     └────────┘     └────────┘
    ↓              ↓              ↓
  ★ OK         ● Running      ✓ Done
```

**Expectation**:
- arrows `→`, `↓` get highlighted (special group)
- symbols `★`, `●`, `✓` get highlighted (delimiter group)

---

## Test 5: Go with operators

```ascii go
Channel Communication:
┌─────────────────────┐
│ chan int            │
│   ↓                 │
│ goroutine           │
│   func() {          │
│     data := <-ch    │
│   }                 │
└─────────────────────┘
```

**Expectation**:
- keywords `chan`, `int`, `func` highlighted
- the operators `:=` and `<-` highlighted

---

## Test 6: an empty fence (only with treat_empty_fence_as_ascii = true)

```
┌────────────┐
│ Empty Box  │
└────────────┘
```

**Expectation**:
- **when enabled**: box characters get highlighted
- **when disabled**: no highlighting

---

## Test 7: inline code (only with enable_inline_code = true)

One uses `func` for functions in Go and `→` for arrows.
The `:=` syntax is unmistakably Go-specific.

**Expectation**:
- **when enabled**: `func`, `→`, `:=` get highlighted
- **when disabled**: no highlighting

---

## Test 8: operators and brackets

```ascii-c
Expression Evaluation:
┌───────────────────────┐
│ if (x >= 10 && y != 0) │
│   result = x / y;      │
│ else                   │
│   result = 0;          │
└───────────────────────┘
```

**Expectation**:
- keywords `if`, `else` highlighted
- **with enable_bracket_highlighting = true**: `()` highlighted
- the operators `>=`, `&&`, `!=`, `/` highlighted (from the operators group)

---

## Test 9: function-name detection (only with enable_function_names = true)

```ascii-c
Function Call Chain:
┌─────────────────────────┐
│ result = calculate(x);  │
│ process(result);        │
│ display(result);        │
└─────────────────────────┘
```

**Expectation**:
- **when enabled**: `calculate`, `process`, `display` highlighted as functions
- **when disabled**: plain text only

---

## Test 10: blocks and shading

```ascii
Progress Bar:
┌──────────────────────┐
│ ████████████░░░░░░░░ │ 60%
└──────────────────────┘
```

**Expectation**: block characters `█`, `░` highlighted (type group)

---

## Test 11: Custom Highlights Testing

This test only works with a manual configuration:

```lua
require('color_my_ascii').setup({
  overrides = {
    ['┌'] = { fg = '#ff0000', bold = true },
    ['└'] = { fg = '#00ff00', bold = true },
  },
  default_text_hl = { fg = '#808080' },
})
```

```ascii
┌─────────────────────┐
│  Custom Colors!     │
└─────────────────────┘
```

**Expectation**:
- the top-left corner `┌` in red and bold
- the bottom-left corner `└` in green and bold
- ordinary text muted in grey

---

## Test 12: a multi-language block

```ascii
Polyglot Example:
┌──────────────────────────────────┐
│ Python: def hello():             │
│ Go:     func hello()             │
│ Rust:   fn hello()               │
│ C++:    void hello()             │
└──────────────────────────────────┘
```

**Expectation**:
- `def` (Python), `func` (Go), `fn` (Rust), `void` (C++) all highlighted
- the plugin uses the first language it finds, or all keywords

---

## Test 13: complex diagrams

```ascii
State Machine:
       ┌─────────┐
   ┌──→│  Start  │
   │   └─────────┘
   │        ↓
   │   ┌─────────┐
   │   │ Process │←──┐
   │   └─────────┘   │
   │        ↓        │
   │   ┌─────────┐   │
   └───│  Error  │   │
       └─────────┘   │
            ↓        │
       ┌─────────┐   │
       │  Retry  │───┘
       └─────────┘
```

**Expectation**: all lines and arrows highlighted correctly

---

## Test 14: Rust with the type system

```ascii rust
Memory Layout:
┌────────────────────────────┐
│ struct Person {            │
│   name: String,            │
│   age: u32,                │
│ }                          │
│                            │
│ impl Person {              │
│   fn new() -> Self { }     │
│ }                          │
└────────────────────────────┘
```

**Expectation**:
* keywords `struct`, `impl`, `fn`, `u32` highlighted
* the function name `new` highlighted (with enable_function_names = true)

---

## Debug commands

After opening this file in Neovim:

```vim
" show plugin information
:ColorMyAsciiDebug

" force highlighting by hand
:ColorMyAscii

" switch the plugin on/off
:ColorMyAsciiToggle

" run the health check
:checkhealth color_my_ascii
```

## Expected debug output

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
Function names enabled: false
Bracket highlighting enabled: false
Inline code enabled: false
Empty fence as ASCII: false
```

## Feature matrix

| Feature | Default | Tested in |
|---------|---------|-------------|
| box characters | ✓ | Test 1 |
| language keywords | ✓ | Test 2, 3 |
| arrows/symbols | ✓ | Test 4 |
| operators | ✓ | Test 5, 8 |
| empty fences | ✗ | Test 6 |
| inline code | ✗ | Test 7 |
| function names | ✗ | Test 9 |
| brackets | ✗ | Test 8 |
| custom highlights | ✗ | Test 11 |
| default text HL | ✗ | Test 11 |
