# Test File für color_my_ascii.nvim

## Test 1: Einfaches ASCII-Art ohne Sprache

```ascii
┌─────────────────────┐
│  Hello World!       │
└─────────────────────┘
```

## Test 2: ASCII-Art mit C (explizit)

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

## Test 3: ASCII-Art mit Lua (automatische Erkennung)

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

## Test 4: Pfeile und Symbole

```ascii
Process Flow:
┌────────┐     ┌────────┐     ┌────────┐
│ Start  │ ──→ │ Middle │ ──→ │  End   │
└────────┘     └────────┘     └────────┘
    ↓              ↓              ↓
  ★ OK         ● Running      ✓ Done
```

## Test 5: Go mit Operatoren

```ascii go
Channel:
┌─────────────────────┐
│ chan int            │
│   ↓                 │
│ goroutine           │
│   func() {          │
│     data := <-ch    │
│   }                 │
└─────────────────────┘
```

## Test 6: Leerer Fence (nur wenn treat_empty_fence_as_ascii = true)

```
┌────────────┐
│ Empty Box  │
└────────────┘
```

## Test 7: Inline Code (nur wenn enable_inline_code = true)

Man verwendet `func` für Funktionen in Go und `→` für Pfeile.
Die `:=` Syntax ist eindeutig Go.

## Test 8: Operatoren und Klammern

```ascii-c
Expression:
┌───────────────────────┐
│ if (x >= 10 && y != 0) │
│   result = x / y;      │
│ else                   │
│   result = 0;          │
└───────────────────────┘
```

## Debug-Befehle

Nach dem Öffnen dieser Datei in Neovim:

1. `:ColorMyAsciiDebug` - Zeigt geladene Konfiguration
2. `:ColorMyAscii` - Manuelles Highlighting
3. `:ColorMyAsciiToggle` - Plugin an/aus
