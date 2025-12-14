# Custom Highlights

Das Plugin unterstützt vollständig anpassbare Highlight-Definitionen mit RGB/Hex-Farben und Text-Styles.

## Übersicht

Man kann Highlights auf zwei Arten spezifizieren:

1. **String**: Name einer existierenden Neovim-Highlight-Gruppe
2. **Table**: Custom-Definition mit Farben und Styles

## String-Highlights

Verwendet existierende Neovim-Highlight-Gruppen:

```lua
require('color_my_ascii').setup({
  overrides = {
    ['┌'] = 'Special',      -- Built-in Highlight-Gruppe
    ['→'] = 'Function',     -- Andere Highlight-Gruppe
  }
})
```

Vorteile:
- Kompatibel mit Colorschemes
- Automatisch an Theme angepasst
- Keine zusätzliche Konfiguration

## Custom-Highlight-Tables

Definiert eigene Farben und Styles:

```lua
require('color_my_ascii').setup({
  overrides = {
    ['┌'] = {
      fg = '#ff0000',           -- Vordergrundfarbe (Hex)
      bg = '#000000',           -- Hintergrundfarbe (optional)
      bold = true,              -- Fett (optional)
      italic = false,           -- Kursiv (optional)
      underline = false,        -- Unterstrichen (optional)
      undercurl = false,        -- Gewellte Unterstreichung (optional)
      strikethrough = false,    -- Durchgestrichen (optional)
    },
  }
})
```

## Unterstützte Farb-Formate

### Hex-Farben

```lua
fg = '#ff0000'    -- Rot
fg = '#00ff00'    -- Grün
fg = '#0000ff'    -- Blau
fg = '#ffffff'    -- Weiß
fg = '#000000'    -- Schwarz
```

### Farbnamen

Das Plugin verwendet Neovim's interne Farbverarbeitung, daher funktionieren auch Farbnamen:

```lua
fg = 'red'
fg = 'blue'
fg = 'green'
```

**Hinweis**: Hex-Werte sind präziser und portabler.

## Text-Styles

Alle Styles können kombiniert werden:

```lua
{
  fg = '#ff0000',
  bold = true,
  italic = true,
  underline = true,
}
```

### Verfügbare Styles

| Style | Beschreibung | Beispiel |
|-------|--------------|----------|
| `bold` | Fettdruck | `bold = true` |
| `italic` | Kursiv | `italic = true` |
| `underline` | Unterstrichen | `underline = true` |
| `undercurl` | Gewellte Unterstreichung | `undercurl = true` |
| `strikethrough` | Durchgestrichen | `strikethrough = true` |

## Anwendungsfälle

### Character-Specific Overrides

Bestimmte Zeichen hervorheben:

```lua
require('color_my_ascii').setup({
  overrides = {
    -- Ecken in rot und fett
    ['┌'] = { fg = '#ff0000', bold = true },
    ['┐'] = { fg = '#ff0000', bold = true },
    ['└'] = { fg = '#ff0000', bold = true },
    ['┘'] = { fg = '#ff0000', bold = true },

    -- Pfeile in grün
    ['→'] = { fg = '#00ff00' },
    ['←'] = { fg = '#00ff00' },

    -- Symbole in blau mit Unterstreichung
    ['★'] = { fg = '#0000ff', underline = true },
  }
})
```

### Default Text Highlighting

Normalen Text in Blöcken gedämpft darstellen:

```lua
require('color_my_ascii').setup({
  default_text_hl = { fg = '#808080' },  -- Grauer Text
})
```

Dies bewirkt:
- Normaler Text wird grau
- Keywords bleiben farbig hervorgehoben
- Symbole bleiben farbig hervorgehoben
- Guter Kontrast zwischen wichtigen und unwichtigen Elementen

### Kombinierte Nutzung

String-Highlights und Custom-Highlights kombinieren:

```lua
require('color_my_ascii').setup({
  overrides = {
    ['┌'] = 'Special',                    -- Built-in Highlight
    ['→'] = { fg = '#00ff00', bold = true }, -- Custom
  },
  default_text_hl = 'Comment',            -- Built-in Highlight
})
```

## Character Groups mit Custom Highlights

Auch Gruppen können Custom-Highlights verwenden:

```lua
require('color_my_ascii').setup({
  groups = {
    box_drawing = {
      chars = "─│┌┐└┘├┤┬┴┼",
      hl = { fg = '#00ff00', bold = true },
    },
    arrows = {
      chars = "←→↑↓",
      hl = 'Special',  -- Oder String
    },
  }
})
```

## Keyword Highlights

Keywords können ebenfalls Custom-Highlights verwenden:

```lua
require('color_my_ascii').setup({
  keywords = {
    my_language = {
      words = { 'function', 'return', 'if' },
      hl = { fg = '#ff00ff', bold = true },
    }
  }
})
```

## Praktische Beispiele

### Matrix-Style (Grüner Hacker-Look)

```lua
require('color_my_ascii').setup({
  groups = {
    box_drawing = {
      chars = "─│┌┐└┘├┤┬┴┼",
      hl = { fg = '#00ff00', bold = true },
    },
  },
  default_text_hl = { fg = '#004400' },  -- Dunkles Grün
})
```

### Regenbogen-Ecken

```lua
require('color_my_ascii').setup({
  overrides = {
    ['┌'] = { fg = '#ff0000' },  -- Rot
    ['┐'] = { fg = '#ff7f00' },  -- Orange
    ['└'] = { fg = '#00ff00' },  -- Grün
    ['┘'] = { fg = '#0000ff' },  -- Blau
  }
})
```

### Subtile Dimm-Effekte

```lua
require('color_my_ascii').setup({
  default_text_hl = { fg = '#666666' },  -- Gedämpfter Text
  overrides = {
    -- Wichtige Symbole hell
    ['→'] = { fg = '#ffffff', bold = true },
    ['★'] = { fg = '#ffff00', bold = true },
  }
})
```

## Troubleshooting

### Farben werden nicht angezeigt

1. Terminal unterstützt True Color:
```lua
vim.opt.termguicolors = true
```

2. Theme überschreibt Custom-Highlights:
   - Lade Plugin nach dem Theme
   - Verwende höhere Priorität

### Styles funktionieren nicht

Manche Terminals unterstützen nicht alle Styles:
- `bold` und `italic` funktionieren meist
- `undercurl` benötigt spezielle Terminal-Unterstützung
- `strikethrough` ist nicht überall verfügbar

### Performance-Probleme

Custom-Highlights werden beim Setup einmalig erstellt und gecacht:
- Keine Performance-Einbußen im Vergleich zu String-Highlights
- Lookup ist O(1)

## Best Practices

1. **Konsistenz**: Verwende ähnliche Farben für ähnliche Element-Typen
2. **Kontrast**: Stelle sicher, dass Text lesbar bleibt
3. **Sparsamkeit**: Zu viele Farben können ablenkend wirken
4. **Theme-Kompatibilität**: Überlege, String-Highlights zu nutzen, wenn möglich

## Siehe auch

- [Language Detection](language-detection.md)
- [Character Groups](character-groups.md)
- [Color Schemes](../color-schemes.md)
