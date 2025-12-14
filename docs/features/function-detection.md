# Inline Code Highlighting

Das Plugin kann Keywords und Symbole auch in Inline-Code (`` `...` ``) hervorheben.

## Aktivierung

```lua
require('color_my_ascii').setup({
  enable_inline_code = true,
})
```

**Standard**: `false` (deaktiviert)

## Funktionsweise

Das Plugin scannt Markdown-Zeilen nach Inline-Code-Segmenten zwischen Backticks und wendet dieselben Highlighting-Regeln an wie für ASCII-Blöcke.

## Was wird hervorgehoben?

In Inline-Code werden folgende Elemente erkannt:

1. **Special Characters**: Aus Character Groups (Pfeile, Symbole, etc.)
2. **Keywords**: Aus allen geladenen Sprachen
3. **Function Names**: Falls `enable_function_names = true`
4. **Operators**: Falls in Character Groups definiert

## Beispiele

### Keywords

```markdown
Man verwendet `func` für Funktionen in Go und `local` in Lua.
```

**Ergebnis**:
- `func` → Go-Keyword, hervorgehoben
- `local` → Lua-Keyword, hervorgehoben

### Symbole und Pfeile

```markdown
Datenfluss: `A → B → C` mit Checkpoint `★`.
```

**Ergebnis**:
- `→` → Pfeil, hervorgehoben (Special)
- `★` → Symbol, hervorgehoben (Delimiter)

### Operatoren

```markdown
Go verwendet `:=` für Deklarationen und `<-` für Channels.
```

**Ergebnis**:
- `:=` → Go-Operator
- `<-` → Go-Operator

### Funktionsnamen

```markdown
Nutze `calculate(x)` für die Berechnung.
```

**Mit `enable_function_names = true`**:
- `calculate` → als Funktion hervorgehoben

## Priorität

Die Highlighting-Priorität in Inline-Code ist identisch zu ASCII-Blöcken:

1. `default_text_hl` (niedrigste, falls gesetzt)
2. Character highlights
3. Function names
4. Keywords (höchste)

## Anwendungsfälle

### Dokumentation

Inline-Code in technischer Dokumentation:

```markdown
## API Reference

Die Funktion `init()` initialisiert das System.
Nutze `→` für Referenzen und `★` für wichtige Punkte.
```

### Code-Erklärungen

```markdown
In Rust verwendet man `fn` statt `function` und `let` statt `var`.
Der Operator `::` trennt Namespaces, `->` zeigt Return-Typen.
```

### Inline-Diagramme

```markdown
Flow: `start → process → end`

States: `idle ● running ● done ✓`
```

## Konfiguration

### Mit gedämpftem Text

```lua
require('color_my_ascii').setup({
  enable_inline_code = true,
  default_text_hl = { fg = '#808080' },  -- Grauer Text
})
```

**Ergebnis**: Normaler Text in Inline-Code wird grau, Keywords bleiben farbig.

### Mit allen Features

```lua
require('color_my_ascii').setup({
  enable_inline_code = true,
  enable_function_names = true,
  enable_bracket_highlighting = true,
  enable_keywords = true,
})
```

### Nur Symbole, keine Keywords

```lua
require('color_my_ascii').setup({
  enable_inline_code = true,
  enable_keywords = false,  -- Keywords aus
})
```

**Ergebnis**: Nur Symbole (→, ★, etc.) werden hervorgehoben, keine Wörter.

## Performance

### Overhead

Inline-Code-Highlighting scannt **jede Zeile** im Buffer:
- O(n) für Anzahl Zeilen
- O(m) für Zeilen-Länge
- Effizient durch Pattern-Matching

**Empfehlung**: Bei sehr großen Dokumenten (>5000 Zeilen) kann man das Feature deaktivieren.

### Debouncing

Wie bei ASCII-Blöcken ist auch Inline-Code-Highlighting debounced:
- 100ms Verzögerung nach Textänderung
- Verhindert Flackern beim Tippen

## Einschränkungen

### Escaped Backticks

Escaped Backticks werden nicht korrekt behandelt:

```markdown
Use \`code\` for inline  → Wird nicht als Inline-Code erkannt
```

Dies ist eine Limitation des aktuellen Parsers.

### Verschachtelte Backticks

Nicht unterstützt:

```markdown
``nested `code` here``  → Funktioniert nicht korrekt
```

### Code-Spans über Zeilen

Inline-Code über mehrere Zeilen wird nicht erkannt:

```markdown
`start
end`  → Wird nicht als Inline-Code erkannt
```

Dies ist beabsichtigt, da Markdown-Inline-Code typischerweise einzeilig ist.

## Kombination mit ASCII-Blöcken

Beide Features können gleichzeitig aktiv sein:

```markdown
Flow-Diagramm:

```ascii
┌──────┐
│ Start│ → Process → End
└──────┘
```

Man verwendet `→` für Pfeile.
```

**Ergebnis**:
- ASCII-Block: Alle Elemente hervorgehoben
- Inline `→`: Auch hervorgehoben

## Language Detection

Im Gegensatz zu ASCII-Blöcken gibt es **keine Language Detection** für Inline-Code:

**Grund**: Inline-Code ist zu kurz für zuverlässige Heuristik.

**Konsequenz**: Alle Keywords aller Sprachen werden geprüft.

Beispiel:
```markdown
`func` und `function` werden beide hervorgehoben (Go und Lua).
```

## Best Practices

### Wann aktivieren?

**Aktivieren**, wenn:
- Dokumentation viele Inline-Code-Beispiele enthält
- Keywords und Symbole in Fließtext hervorgehoben werden sollen
- Konsistentes Highlighting zwischen Blöcken und Inline-Code gewünscht ist

**Deaktivieren**, wenn:
- Dokumentation ist sehr groß (>5000 Zeilen)
- Inline-Code enthält hauptsächlich Variable/Platzhalter (keine Keywords)
- Performance kritisch ist

### Kombination mit Colorschemes

```lua
-- Matrix-Scheme hat enable_inline_code = true
require('color_my_ascii').setup(
  require('color_my_ascii.schemes.matrix')
)
```

Eigene Anpassung:
```lua
local config = require('color_my_ascii.schemes.nord')
config.enable_inline_code = true  -- Falls im Schema deaktiviert
require('color_my_ascii').setup(config)
```

### Mit default_text_hl

Für bessere Lesbarkeit:

```lua
require('color_my_ascii').setup({
  enable_inline_code = true,
  default_text_hl = 'Comment',  -- Gedämpfter Text
})
```

**Effekt**: Keywords stechen deutlicher hervor.

## Troubleshooting

### Inline-Code wird nicht hervorgehoben

1. Feature aktiviert?
```lua
local config = require('color_my_ascii.config').get()
print(config.enable_inline_code)
```

2. Buffer ist Markdown?
```vim
:set filetype?
```

3. Backticks korrekt?
```markdown
`code`  ✓ Funktioniert
'code'  ✗ Falsche Quotes
```

### Zu viele False Positives

Inline-Code hebt alle möglichen Keywords hervor:

**Lösung 1**: Keywords deaktivieren
```lua
require('color_my_ascii').setup({
  enable_inline_code = true,
  enable_keywords = false,  -- Nur Symbole
})
```

**Lösung 2**: Feature deaktivieren
```lua
require('color_my_ascii').setup({
  enable_inline_code = false,
})
```

### Performance-Probleme

Bei sehr großen Dateien:

1. Feature deaktivieren
2. Oder: Nur für spezifische Buffers aktivieren

```lua
vim.api.nvim_create_autocmd('BufEnter', {
  pattern = '*.md',
  callback = function()
    local lines = vim.api.nvim_buf_line_count(0)
    if lines < 1000 then
      -- Aktiviere nur für kleine Dateien
      require('color_my_ascii.config').get().enable_inline_code = true
    end
  end
})
```

## Siehe auch

- [Language Detection](language-detection.md)
- [Function Detection](function-detection.md)
- [Character Groups](character-groups.md)
- [Performance](../performance.md)
