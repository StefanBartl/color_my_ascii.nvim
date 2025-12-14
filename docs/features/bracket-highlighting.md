# Bracket Highlighting

Das Plugin kann Klammern und Brackets automatisch hervorheben, falls sie nicht bereits in Character Groups definiert sind.

## Aktivierung

```lua
require('color_my_ascii').setup({
  enable_bracket_highlighting = true,
})
```

**Standard**: `false` (deaktiviert)

## Unterstützte Brackets

Das Feature hebt folgende Zeichen hervor:

- `(` `)` — Runde Klammern (Parentheses)
- `[` `]` — Eckige Klammern (Square Brackets)
- `{` `}` — Geschweifte Klammern (Curly Braces)

## Highlight-Gruppe

Brackets werden mit der `Operator` Highlight-Gruppe hervorgehoben.

## Funktionsweise

### Automatische Erkennung

Das Plugin prüft, ob Brackets bereits in anderen Groups definiert sind:

**Beispiel 1**: Operators-Group enthält bereits Brackets
```lua
groups = {
  operators = {
    chars = "+-*/()[]{}",  -- Enthält Brackets
    hl = 'Operator',
  }
}
```
→ `enable_bracket_highlighting` wird **ignoriert** (bereits definiert)

**Beispiel 2**: Keine Bracket-Definition
```lua
groups = {
  arrows = {
    chars = "←→↑↓",  -- Keine Brackets
    hl = 'Special',
  }
}
```
→ `enable_bracket_highlighting = true` **fügt Brackets hinzu**

### Priorität

Falls Brackets sowohl in Groups als auch via `enable_bracket_highlighting` definiert sind:

**Groups haben Vorrang** (Overrides > Groups > enable_bracket_highlighting)

## Beispiele

### C-Syntax

````markdown
```ascii-c
┌──────────────────────┐
│ if (x > 0) {         │
│   result = func(x);  │
│ }                    │
└──────────────────────┘
```
````

**Mit `enable_bracket_highlighting = true`**:
- `()`, `{}` werden hervorgehoben
- `if`, `result` als Keywords
- `func` als Funktion (wenn `enable_function_names = true`)

### Array-Zugriff

````markdown
```ascii
┌─────────────────┐
│ array[0] = x    │
│ matrix[i][j]    │
└─────────────────┘
```
````

**Ergebnis**: `[]` werden hervorgehoben

### Nested Structures

````markdown
```ascii-go
┌──────────────────────────┐
│ map[string][]int{        │
│   "key": {1, 2, 3},      │
│ }                        │
└──────────────────────────┘
```
````

**Ergebnis**: Alle `[]`, `{}` werden hervorgehoben

## Kombination mit anderen Features

### Mit Operators Group

Falls man bereits eine Operators-Group hat:

**Option 1**: Brackets in Group definieren
```lua
require('color_my_ascii').setup({
  groups = {
    operators = {
      chars = "+-*/()[]{}",
      hl = 'Operator',
    }
  },
  enable_bracket_highlighting = false,  -- Nicht nötig
})
```

**Option 2**: Nur Feature nutzen
```lua
require('color_my_ascii').setup({
  groups = {
    operators = {
      chars = "+-*/",  -- Ohne Brackets
      hl = 'Operator',
    }
  },
  enable_bracket_highlighting = true,  -- Fügt Brackets hinzu
})
```

### Mit Custom Highlights

Brackets individuell stylen:

```lua
require('color_my_ascii').setup({
  enable_bracket_highlighting = true,
  overrides = {
    ['('] = { fg = '#ff0000' },  -- Rot
    [')'] = { fg = '#ff0000' },
    ['['] = { fg = '#00ff00' },  -- Grün
    [']'] = { fg = '#00ff00' },
    ['{'] = { fg = '#0000ff' },  -- Blau
    ['}'] = { fg = '#0000ff' },
  }
})
```

**Resultat**: Overrides haben Vorrang → Regenbogen-Brackets

## Use Cases

### Code-Diagramme

Bei Code-Visualisierungen sind Brackets oft wichtig:

```lua
require('color_my_ascii').setup({
  enable_bracket_highlighting = true,
  enable_function_names = true,
  enable_keywords = true,
})
```

### Minimale Konfiguration

Nur Brackets, keine anderen Operatoren:

```lua
require('color_my_ascii').setup({
  groups = {},  -- Keine vordefinierten Groups
  enable_bracket_highlighting = true,
})
```

### Bracket Pairing Visualization

Verschiedene Farben für verschiedene Bracket-Typen:

```lua
require('color_my_ascii').setup({
  enable_bracket_highlighting = false,  -- Basis-Feature aus
  overrides = {
    -- Runde Klammern: Gelb
    ['('] = { fg = '#ffff00', bold = true },
    [')'] = { fg = '#ffff00', bold = true },
    -- Eckige Klammern: Cyan
    ['['] = { fg = '#00ffff', bold = true },
    [']'] = { fg = '#00ffff', bold = true },
    -- Geschweifte Klammern: Magenta
    ['{'] = { fg = '#ff00ff', bold = true },
    ['}'] = { fg = '#ff00ff', bold = true },
  }
})
```

## Performance

Das Feature hat **minimalen Overhead**:
- Brackets werden beim Setup in die Lookup-Tabelle eingefügt
- Lookup ist O(1) wie für alle anderen Characters
- Keine Runtime-Overhead

## Einschränkungen

### Keine Matching-Logik

Das Feature hebt **alle** Brackets hervor, ohne zu prüfen, ob sie zusammenpassen:

```
( ] { )  → Alle werden hervorgehoben, auch wenn falsch gepaart
```

Für Matching-Logic nutze man ein separates Plugin wie:
- `rainbow-delimiters.nvim`
- `nvim-ts-rainbow`

### Keine Context-Awareness

Brackets werden überall hervorgehoben:

```
"text (in quotes)"  → () werden hervorgehoben (auch in Strings)
# comment [test]    → [] werden hervorgehoben (auch in Kommentaren)
```

Dies ist beabsichtigt, da ASCII-Art oft außerhalb normaler Syntax-Regeln liegt.

## Best Practices

### Wann aktivieren?

**Aktivieren**, wenn:
- Code-Strukturen mit Brackets visualisiert werden
- Arrays, Maps, oder verschachtelte Strukturen dargestellt werden
- Funktionsaufrufe in Diagrammen vorkommen

**Deaktivieren**, wenn:
- Keine Brackets in ASCII-Art vorkommen
- Operators-Group bereits Brackets definiert
- Individuelle Bracket-Styles via Overrides gewünscht sind

### Kombination mit Color Schemes

Manche vordefinierten Schemes haben bereits Bracket-Highlighting:

```lua
-- Matrix-Scheme hat enable_bracket_highlighting = true
require('color_my_ascii').setup(
  require('color_my_ascii.schemes.matrix')
)

-- Überschreiben falls gewünscht
local matrix = require('color_my_ascii.schemes.matrix')
matrix.enable_bracket_highlighting = false
require('color_my_ascii').setup(matrix)
```

## Troubleshooting

### Brackets werden nicht hervorgehoben

1. Feature aktiviert?
```lua
local config = require('color_my_ascii.config').get()
print(config.enable_bracket_highlighting)
```

2. Bereits in Groups definiert?
```lua
local lookup = require('color_my_ascii.config').char_lookup
print(lookup['('])  -- Sollte Highlight-Gruppe zeigen
```

3. Overrides vorhanden?
```lua
local config = require('color_my_ascii.config').get()
print(vim.inspect(config.overrides))
```

### Falsche Highlight-Farbe

Prüfe Priorität:
1. Overrides (höchste)
2. Groups
3. enable_bracket_highlighting (niedrigste)

Passe entsprechend an:
```lua
-- Entferne Brackets aus Groups
groups = {
  operators = {
    chars = "+-*/",  -- Ohne ()[]{}
  }
},
-- Dann funktioniert enable_bracket_highlighting
enable_bracket_highlighting = true,
```

## Siehe auch

- [Custom Highlights](custom-highlights.md)
- [Character Groups](character-groups.md)
- [Operators Group](../groups/operators.md)
