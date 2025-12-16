# Quickstart Guide

Schnelleinstieg in color_my_ascii.nvim mit allen wichtigen Features.

## Installation

### Mit lazy.nvim

```lua
{
  'StefanBartl/color_my_ascii.nvim',
  ft = 'markdown',
  config = function()
    require('color_my_ascii').setup()
  end
}
```

### Mit packer.nvim

```lua
use {
  'StefanBartl/color_my_ascii.nvim',
  ft = 'markdown',
  config = function()
    require('color_my_ascii').setup()
  end
}
```

## Erste Schritte

### 1. Markdown-Datei öffnen

```vim
:e test.md
```

### 2. ASCII-Codeblock einfügen

````markdown
```ascii
┌─────────────┐
│ Hello World │
└─────────────┘
```
````

Die Box-Zeichen sollten automatisch farbig hervorgehoben werden.

## Basis-Konfiguration

### Minimal

```lua
require('color_my_ascii').setup()
```

Nutzt alle Standard-Einstellungen und lädt automatisch:
- 10 Sprachen (C, C++, Lua, Go, Rust, TypeScript, Python, Bash, Zig, LLVM)
- 5 Zeichengruppen (Box-Drawing, Blocks, Arrows, Symbols, Operators)

### Mit Features

```lua
require('color_my_ascii').setup({
  enable_keywords = true,              -- Keywords hervorheben
  enable_language_detection = true,    -- Automatische Sprach-Erkennung
  enable_function_names = false,       -- Funktionsnamen erkennen
  enable_bracket_highlighting = false, -- Klammern hervorheben
  enable_inline_code = false,          -- Inline-Code highlighten
  treat_empty_fence_as_ascii = false,  -- ``` ohne Sprache = ASCII
})
```

### Mit Color-Scheme

```lua
-- Hacker-Style (grün auf schwarz)
require('color_my_ascii').setup(
  require('color_my_ascii.schemes.matrix')
)

-- Nord-Theme (blau/cyan)
require('color_my_ascii').setup(
  require('color_my_ascii.schemes.nord')
)
```

## Feature-Beispiele

### 1. Sprach-Erkennung

**Explizit**:
````markdown
```ascii-c
┌──────────────┐
│ int x = 42;  │
└──────────────┘
```
````

**Automatisch** (durch Keywords):
````markdown
```ascii
┌─────────────────────┐
│ function counter()  │
│   local count = 0   │
│   return count      │
│ end                 │
└─────────────────────┘
```
````
→ Erkennt Lua durch `function`, `local`, `end`

### 2. Custom-Highlights

```lua
require('color_my_ascii').setup({
  overrides = {
    ['┌'] = { fg = '#ff0000', bold = true },  -- Rote Ecke
    ['→'] = { fg = '#00ff00' },               -- Grüner Pfeil
  },
  default_text_hl = { fg = '#808080' },       -- Grauer Text
})
```

### 3. Funktionsnamen

```lua
require('color_my_ascii').setup({
  enable_function_names = true,
})
```

````markdown
```ascii-c
┌────────────────┐
│ init()         │
│ process(data)  │
│ cleanup()      │
└────────────────┘
```
````
→ `init`, `process`, `cleanup` werden als Funktionen hervorgehoben

### 4. Inline-Code

```lua
require('color_my_ascii').setup({
  enable_inline_code = true,
})
```

```markdown
Man verwendet `func` in Go und `→` für Pfeile.
```
→ `func` und `→` werden hervorgehoben

### 5. Leere Fences

```lua
require('color_my_ascii').setup({
  treat_empty_fence_as_ascii = true,
})
```

````markdown
```
┌────┐
│ OK │
└────┘
```
````
→ Wird wie ````ascii` behandelt

## Verfügbare Color-Schemes

| Schema | Stil | Features |
|--------|------|----------|
| `default` | Built-in Highlights | Minimal, kompatibel |
| `matrix` | Grün auf schwarz | Alle aktiviert |
| `nord` | Blau/Cyan | Function names |
| `gruvbox` | Warm/Retro | Brackets, Inline |
| `dracula` | Lila/Pink | Alle aktiviert |

### Schema laden

```lua
local scheme = require('color_my_ascii.schemes.matrix')
require('color_my_ascii').setup(scheme)
```

### Schema anpassen

```lua
local scheme = require('color_my_ascii.schemes.nord')
scheme.enable_inline_code = true  -- Feature hinzufügen
scheme.default_text_hl = 'Comment'  -- Text dimmen
require('color_my_ascii').setup(scheme)
```

## Nützliche Befehle

```vim
" Debug-Info anzeigen
:ColorMyAsciiDebug

" Manuell highlighten
:ColorMyAscii

" Plugin an/aus
:ColorMyAsciiToggle

" Health-Check
:checkhealth color_my_ascii

" Hilfe
:h color_my_ascii
```

## Typische Konfigurationen

### Für Entwickler

```lua
require('color_my_ascii').setup({
  enable_keywords = true,
  enable_language_detection = true,
  enable_function_names = true,
  enable_bracket_highlighting = true,
})
```

### Für Dokumentation

```lua
require('color_my_ascii').setup({
  enable_inline_code = true,
  treat_empty_fence_as_ascii = true,
  default_text_hl = 'Comment',
})
```

### Minimalistisch

```lua
require('color_my_ascii').setup({
  enable_keywords = false,
  enable_language_detection = false,
  -- Nur Zeichen-Highlighting
})
```

### Maximum Features

```lua
require('color_my_ascii').setup({
  enable_keywords = true,
  enable_language_detection = true,
  enable_function_names = true,
  enable_bracket_highlighting = true,
  enable_inline_code = true,
  treat_empty_fence_as_ascii = true,
  default_text_hl = 'Comment',
})
```

## Häufige Probleme

### Keine Highlights

1. Plugin geladen?
```vim
:ColorMyAsciiDebug
```

2. Filetype richtig?
```vim
:set filetype?  " Sollte markdown sein
```

3. Syntax richtig?
````markdown
```ascii  ✓ Richtig
```asci   ✗ Tippfehler
```
````

### Falsche Farben

1. True Color aktiviert?
```lua
vim.opt.termguicolors = true
```

2. Theme lädt nach Plugin?
```lua
-- In init.lua: Plugin VOR Theme laden
```

### Performance-Probleme

Features deaktivieren:
```lua
require('color_my_ascii').setup({
  enable_function_names = false,  -- Kann langsam sein
  enable_inline_code = false,     -- Bei großen Dateien
})
```

## Nächste Schritte

1. **Feature-Dokumentation** lesen:
   - [Custom Highlights](features/custom-highlights.md)
   - [Function Detection](features/function-detection.md)
   - [Bracket Highlighting](features/bracket-highlighting.md)
   - [Inline Code](features/inline-code.md)

2. **Test-Datei** ausprobieren:
   - Öffne [TEST.md](TEST.md)
   - Teste alle Features systematisch

3. **Eigenes Schema** erstellen:
   - Basiere auf existierendem Schema
   - Passe Farben an
   - Speichere als eigene Datei

4. **Neue Sprache** hinzufügen:
   - Siehe [README.md](../README.md#contributing)

## Hilfe bekommen

1. **Vim-Help**: `:h color_my_ascii`
2. **Health-Check**: `:checkhealth color_my_ascii`
3. **Debug-Info**: `:ColorMyAsciiDebug`
4. **GitHub Issues**: Öffne ein Issue mit Details

## Siehe auch

- [README.md](../README.md) - Vollständige Dokumentation
- [TEST.md](TEST.md) - Alle Features testen
- [doc/color_my_ascii.txt](../doc/color_my_ascii.txt) - Vim-Help
