# color_my_ascii.nvim

Ein Neovim-Plugin zum farblichen Hervorheben von ASCII-Art in Markdown-Codeblöcken mit automatischer Sprach-Erkennung, Custom-Highlights und vordefinierten Color-Schemes.

## Features

### Core-Features

- ✅ **Automatische Erkennung** von `ascii`-Codeblöcken in Markdown-Dateien
- ✅ **Modulare Sprach-Definitionen**: 10 vordefinierte Sprachen (C, C++, Lua, Go, Rust, TypeScript, Python, Bash, Zig, LLVM IR)
- ✅ **Intelligente Sprach-Erkennung**:
  - Explizite Angabe via ````ascii-c`, ````ascii lua`, ````ascii:python`
  - Heuristische Erkennung basierend auf Keyword-Häufigkeit
  - Fallback auf Buffer-Filetype
- ✅ **Modulare Zeichengruppen**: Anpassbare Gruppen für Linien, Blöcke, Pfeile, Symbole, Operatoren
- ✅ **Custom-Highlights mit RGB/Hex**: Vollständige Farb- und Style-Kontrolle
- ✅ **5 vordefinierte Color-Schemes**: Default, Matrix, Nord, Gruvbox, Dracula
- ✅ **Nicht-intrusiv**: Verwendet Extmarks, keine Puffer-Änderung

### Erweiterte Features

- ✅ **Funktionsnamen-Erkennung**: Heuristik für `word()`-Pattern
- ✅ **Bracket-Highlighting**: Automatisches Hervorheben von `()[]{}`
- ✅ **Inline-Code-Highlighting**: Keywords und Symbole in `` `...` ``
- ✅ **Leere Fenced Blocks**: Optional ``` ohne Sprache als ASCII behandeln
- ✅ **Standard-Textfarbe**: Gedämpfte Darstellung für normalen Text
- ✅ **Health Check**: `:checkhealth color_my_ascii`
- ✅ **Vim Help**: `:h color_my_ascii`

## Installation

### Mit lazy.nvim

```lua
{
  'username/color_my_ascii.nvim',
  ft = 'markdown',
  opts = {
    -- Optional: Konfiguration hier
  }
}
```

### Mit packer.nvim

```lua
use {
  'username/color_my_ascii.nvim',
  ft = 'markdown',
  config = function()
    require('color_my_ascii').setup({
      -- Optional: Konfiguration hier
    })
  end
}
```

## Quick Start

### Minimal-Setup

```lua
require('color_my_ascii').setup()
```

Das Plugin aktiviert sich automatisch für Markdown-Dateien.

### Beispiel

````markdown
```ascii
┌─────────────────────┐
│  Hello World!       │
└─────────────────────┘
```
````

→ Box-Zeichen werden automatisch farbig hervorgehoben

## Konfiguration

### Standard-Konfiguration

```lua
require('color_my_ascii').setup({
  -- Zeichenspezifische Overrides (höchste Priorität)
  overrides = {},

  -- Standard-Highlighting für nicht zugeordnete Zeichen
  default_hl = 'Normal',

  -- Optional: Standard-Highlighting für normalen Text in Blöcken
  default_text_hl = nil,  -- z.B. 'Comment' für gedämpfte Darstellung

  -- Feature-Toggles
  enable_keywords = true,
  enable_language_detection = true,
  language_detection_threshold = 2,
  enable_function_names = false,
  enable_bracket_highlighting = false,
  treat_empty_fence_as_ascii = false,
  enable_inline_code = false,
})
```

### Mit Color-Scheme

```lua
-- Matrix-Style (grüner Hacker-Look)
require('color_my_ascii').setup(
  require('color_my_ascii.schemes.matrix')
)

-- Nord-Theme (kühles Blau/Cyan)
require('color_my_ascii').setup(
  require('color_my_ascii.schemes.nord')
)

-- Gruvbox (warme Retro-Farben)
require('color_my_ascii').setup(
  require('color_my_ascii.schemes.gruvbox')
)

-- Dracula (lebendiges Lila/Pink)
require('color_my_ascii').setup(
  require('color_my_ascii.schemes.dracula')
)
```

### Custom-Highlights

```lua
require('color_my_ascii').setup({
  overrides = {
    -- String: Built-in Highlight-Gruppe
    ['┌'] = 'Special',

    -- Table: Custom-Definition mit RGB/Hex
    ['└'] = { fg = '#ff0000', bold = true },
    ['→'] = { fg = '#00ff00', italic = true },
  },

  -- Gedämpfter Text in Blöcken
  default_text_hl = { fg = '#808080' },
})
```

### Alle Features aktiviert

```lua
require('color_my_ascii').setup({
  enable_keywords = true,
  enable_language_detection = true,
  enable_function_names = true,
  enable_bracket_highlighting = true,
  treat_empty_fence_as_ascii = true,
  enable_inline_code = true,
  default_text_hl = 'Comment',
})
```

## Unterstützte Sprachen

Das Plugin enthält vordefinierte Keyword-Definitionen für:

| Sprache | Unique Keywords | Beispiel |
|---------|----------------|----------|
| C | `restrict`, `_Bool`, `_Complex` | `int`, `void`, `char` |
| C++ | `class`, `namespace`, `template` | `virtual`, `override`, `nullptr` |
| Lua | `then`, `elseif`, `end` | `function`, `local`, `nil` |
| Go | `func`, `chan`, `defer` | `go`, `:=`, `<-` |
| Rust | `fn`, `mut`, `impl` | `trait`, `match`, `loop` |
| TypeScript | `interface`, `namespace` | `async`, `await`, `Promise` |
| Python | `def`, `elif`, `pass` | `lambda`, `self`, `yield` |
| Bash | `fi`, `esac`, `done` | `if`, `then`, `else` |
| Zig | `comptime`, `errdefer` | `anytype`, `unreachable` |
| LLVM IR | `getelementptr`, `phi` | `alloca`, `icmp`, `zext` |

Weitere Sprachen können einfach hinzugefügt werden (siehe [Dokumentation](docs/features/)).

## Befehle

| Befehl | Beschreibung |
|--------|--------------|
| `:ColorMyAscii` | Manuelles Aktualisieren der Hervorhebung |
| `:ColorMyAsciiToggle` | Plugin aktivieren/deaktivieren |
| `:ColorMyAsciiDebug` | Debug-Informationen anzeigen |
| `:checkhealth color_my_ascii` | Health-Check durchführen |
| `:h color_my_ascii` | Vim-Help öffnen |

## Dokumentation

### Features

- [Custom Highlights](docs/features/custom-highlights.md) - RGB/Hex-Farben und Styles
- [Function Detection](docs/features/function-detection.md) - Automatische Funktionsnamen-Erkennung
- [Bracket Highlighting](docs/features/bracket-highlighting.md) - Klammern hervorheben
- [Inline Code](docs/features/inline-code.md) - Highlighting in `` `...` ``

### Guides

- [Quickstart](docs/QUICKSTART.md) - Erste Schritte
- [Test File](docs/TEST.md) - Alle Features testen

### Reference

- [Vim Help](doc/color_my_ascii.txt) - Vollständige Referenz

## Color Schemes

### Matrix (Hacker Style)

```lua
require('color_my_ascii').setup(
  require('color_my_ascii.schemes.matrix')
)
```

Dunkler Hintergrund mit leuchtend grünen Elementen. Alle Features aktiviert.

### Nord

```lua
require('color_my_ascii').setup(
  require('color_my_ascii.schemes.nord')
)
```

Kühle Blau/Cyan-Töne. Ecken besonders hervorgehoben.

### Gruvbox

```lua
require('color_my_ascii').setup(
  require('color_my_ascii.schemes.gruvbox')
)
```

Warme Retro-Farben. Bracket-Highlighting aktiviert.

### Dracula

```lua
require('color_my_ascii').setup(
  require('color_my_ascii.schemes.dracula')
)
```

Lebendige Lila/Pink-Akzente. Alle Features aktiviert.

### Eigenes Schema erstellen

```lua
require('color_my_ascii').setup({
  groups = {
    box_drawing = {
      chars = "─│┌┐└┘",
      hl = { fg = '#00ff00', bold = true },
    },
  },
  overrides = {
    ['★'] = { fg = '#ffff00' },
  },
  enable_keywords = true,
})
```

## Architektur

Das Plugin besteht aus mehreren Modulen:

- `init.lua` - Haupteinstiegspunkt, API, State-Management
- `config.lua` - Konfigurationsverwaltung, dynamisches Laden
- `parser.lua` - Erkennung von ASCII-Codeblöcken und Inline-Code
- `highlighter.lua` - Anwendung von Highlights via Extmarks
- `language_detector.lua` - Intelligente Sprach-Erkennung
- `health.lua` - Health-Check für `:checkhealth`
- `languages/*.lua` - Modulare Sprach-Definitionen
- `groups/*.lua` - Modulare Zeichengruppen-Definitionen
- `schemes/*.lua` - Vordefinierte Color-Schemes

## Performance

Das Plugin verwendet:
- Extmarks für non-intrusive Highlights
- Debounced Updates (100ms) bei Textänderungen
- Effiziente Lookup-Tabellen (O(1) Zugriff)
- Lazy-Loading für Markdown-Dateien

Selbst große Dokumente (>1000 Zeilen) sollten keine Performance-Probleme verursachen.

**Hinweis**: `enable_inline_code` kann bei sehr großen Dateien (>5000 Zeilen) zu Verlangsamungen führen.

## Troubleshooting

### Keine Highlights sichtbar

1. Plugin geladen?
```vim
:ColorMyAsciiDebug
```

2. Buffer ist Markdown?
```vim
:set filetype?
```

3. Health-Check durchführen
```vim
:checkhealth color_my_ascii
```

### Falsche Sprache erkannt

Explizite Sprach-Angabe verwenden:

````markdown
```ascii-c
int x = 42;
```
````

Oder Detection-Threshold anpassen:

```lua
require('color_my_ascii').setup({
  language_detection_threshold = 3,  -- Strenger
})
```

### Performance-Probleme

Features deaktivieren:

```lua
require('color_my_ascii').setup({
  enable_function_names = false,
  enable_inline_code = false,
})
```

Siehe [Troubleshooting Guide](docs/troubleshooting.md) für mehr.

## Contributing

Issues und Pull Requests sind willkommen. Bei größeren Änderungen bitte vorher ein Issue öffnen.

### Neue Sprache hinzufügen

1. Datei erstellen: `lua/color_my_ascii/languages/NAME.lua`
2. Keywords definieren:

```lua
---@module 'color_my_ascii.languages.NAME'
---@type ColorMyAscii.KeywordGroup
return {
  words = { 'keyword1', 'keyword2', ... },
  unique_words = { 'unique1', 'unique2', ... },
  hl = 'Function',
}
```

3. Plugin neu laden

### Neue Zeichengruppe hinzufügen

1. Datei erstellen: `lua/color_my_ascii/groups/NAME.lua`
2. Characters definieren:

```lua
---@module 'color_my_ascii.groups.NAME'
---@type ColorMyAscii.CharGroup
local group = {
  chars = '',
  hl = 'Keyword',
}

local chars = { '⚡', '★', '☆' }
group.chars = table.concat(chars, '')

return group
```

3. Plugin neu laden

## Lizenz

MIT

## Credits

- Inspiriert von verschiedenen ASCII-Art-Highlighting-Plugins
- Color-Schemes basierend auf populären Vim/Neovim-Themes
- Danke an alle Contributors

## Siehe auch

- [Neovim Documentation](https://neovim.io/doc/)
- [Extmarks API](https://neovim.io/doc/user/api.html#api-extmarks)
- [Markdown Syntax](https://www.markdownguide.org/basic-syntax/)
