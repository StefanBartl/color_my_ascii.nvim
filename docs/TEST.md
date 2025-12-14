# Test File für color_my_ascii.nvim

Dieses Dokument testet alle Features des Plugins systematisch.

## Test 1: Einfaches ASCII-Art ohne Sprache

```ascii
┌─────────────────────┐
│  Hello World!       │
└─────────────────────┘
```

**Erwartung**: Box-Zeichen werden hervorgehoben (Keyword-Gruppe)

---

## Test 2: ASCII-Art mit expliziter Sprache (C)

```ascii-c
Struct im Speicher:
┌─────────────────────────────────────┐
│ int id          (4 bytes)           │
├─────────────────────────────────────┤
│ char* name      (8 bytes)           │
├─────────────────────────────────────┤
│ void* data      (8 bytes)           │
└─────────────────────────────────────┘
```

**Erwartung**: Keywords `int`, `char`, `void` werden hervorgehoben (Function-Gruppe)

---

## Test 3: ASCII-Art mit automatischer Sprach-Erkennung (Lua)

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

**Erwartung**: Keywords `function`, `local`, `return`, `end` werden hervorgehoben

---

## Test 4: Pfeile und Symbole

```ascii
Process Flow:
┌────────┐     ┌────────┐     ┌────────┐
│ Start  │ ──→ │ Middle │ ──→ │  End   │
└────────┘     └────────┘     └────────┘
    ↓              ↓              ↓
  ★ OK         ● Running      ✓ Done
```

**Erwartung**:
- Pfeile `→`, `↓` werden hervorgehoben (Special-Gruppe)
- Symbole `★`, `●`, `✓` werden hervorgehoben (Delimiter-Gruppe)

---

## Test 5: Go mit Operatoren

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

**Erwartung**:
- Keywords `chan`, `int`, `func` hervorgehoben
- Operator `:=` und `<-` hervorgehoben

---

## Test 6: Leerer Fence (nur wenn treat_empty_fence_as_ascii = true)

```
┌────────────┐
│ Empty Box  │
└────────────┘
```

**Erwartung**:
- **Wenn aktiviert**: Box-Zeichen werden hervorgehoben
- **Wenn deaktiviert**: Keine Hervorhebung

---

## Test 7: Inline Code (nur wenn enable_inline_code = true)

Man verwendet `func` für Funktionen in Go und `→` für Pfeile.
Die `:=` Syntax ist eindeutig Go-spezifisch.

**Erwartung**:
- **Wenn aktiviert**: `func`, `→`, `:=` werden hervorgehoben
- **Wenn deaktiviert**: Keine Hervorhebung

---

## Test 8: Operatoren und Klammern

```ascii-c
Expression Evaluation:
┌───────────────────────┐
│ if (x >= 10 && y != 0) │
│   result = x / y;      │
│ else                   │
│   result = 0;          │
└───────────────────────┘
```

**Erwartung**:
- Keywords `if`, `else` hervorgehoben
- **Wenn enable_bracket_highlighting = true**: `()` hervorgehoben
- Operatoren `>=`, `&&`, `!=`, `/` hervorgehoben (aus Operators-Gruppe)

---

## Test 9: Funktionsnamen-Erkennung (nur wenn enable_function_names = true)

```ascii-c
Function Call Chain:
┌─────────────────────────┐
│ result = calculate(x);  │
│ process(result);        │
│ display(result);        │
└─────────────────────────┘
```

**Erwartung**:
- **Wenn aktiviert**: `calculate`, `process`, `display` als Function hervorgehoben
- **Wenn deaktiviert**: Nur normaler Text

---

## Test 10: Blöcke und Shading

```ascii
Progress Bar:
┌──────────────────────┐
│ ████████████░░░░░░░░ │ 60%
└──────────────────────┘
```

**Erwartung**: Block-Zeichen `█`, `░` hervorgehoben (Type-Gruppe)

---

## Test 11: Custom Highlights Testing

Dieser Test funktioniert nur mit manueller Konfiguration:

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

**Erwartung**:
- Obere linke Ecke `┌` in rot und fett
- Untere linke Ecke `└` in grün und fett
- Normaler Text gedämpft in grau

---

## Test 12: Mehrsprachiger Block

```ascii
Polyglot Example:
┌──────────────────────────────────┐
│ Python: def hello():             │
│ Go:     func hello()             │
│ Rust:   fn hello()               │
│ C++:    void hello()             │
└──────────────────────────────────┘
```

**Erwartung**:
- `def` (Python), `func` (Go), `fn` (Rust), `void` (C++) alle hervorgehoben
- Plugin nutzt erste gefundene Sprache oder alle Keywords

---

## Test 13: Komplexe Diagramme

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

**Erwartung**: Alle Linien und Pfeile korrekt hervorgehoben

---

## Test 14: Rust mit Type System

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

**Erwartung**:
* Keywords `struct`, `impl`, `fn`, `u32` hervorgehoben
* Function name `new` hervorgehoben (wenn enable_function_names = true)

---

## Debug-Befehle

Nach dem Öffnen dieser Datei in Neovim:

```vim
" Plugin-Informationen anzeigen
:ColorMyAsciiDebug

" Manuelles Highlighting erzwingen
:ColorMyAscii

" Plugin an/aus schalten
:ColorMyAsciiToggle

" Health Check durchführen
:checkhealth color_my_ascii
```

## Erwartete Debug-Ausgabe

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

## Feature-Matrix

| Feature | Default | Getestet in |
|---------|---------|-------------|
| Box-Zeichen | ✓ | Test 1 |
| Sprach-Keywords | ✓ | Test 2, 3 |
| Pfeile/Symbole | ✓ | Test 4 |
| Operatoren | ✓ | Test 5, 8 |
| Leere Fences | ✗ | Test 6 |
| Inline-Code | ✗ | Test 7 |
| Funktionsnamen | ✗ | Test 9 |
| Klammern | ✗ | Test 8 |
| Custom Highlights | ✗ | Test 11 |
| Default Text HL | ✗ | Test 11 |
