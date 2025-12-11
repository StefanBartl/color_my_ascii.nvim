# color_my_ascii.nvim

Ein Neovim-Plugin zum farblichen Hervorheben von ASCII-Art in Markdown-Codeblöcken mit automatischer Sprach-Erkennung.

## Features

- Automatische Erkennung von `ascii`-Codeblöcken in Markdown-Dateien
- **Modulare Sprach-Definitionen**: Einfaches Hinzufügen neuer Sprachen via separate Dateien
- **Intelligente Sprach-Erkennung**:
  - Explizite Angabe via ````ascii-c`, ````ascii lua`, ````ascii:python`
  - Heuristische Erkennung basierend auf Keyword-Häufigkeit
  - Fallback auf Buffer-Filetype
- **Modulare Zeichengruppen**: Anpassbare Gruppen für Linien, Blöcke, Pfeile, Symbole
- Zeichenspezifische Overrides für maximale Kontrolle
- Nicht-intrusiv: verwendet Extmarks, keine Pufferänderung
- Debounced Updates für Performance
- Toggle-Funktionalität zum temporären Deaktivieren

## Unterstützte Sprachen

Das Plugin enthält vordefinierte Keyword-Definitionen für:

- C
- C++
- Lua
- Go
- Rust
- TypeScript/JavaScript
- Python
- Bash/Shell
- Zig
- LLVM IR

Weitere Sprachen können einfach hinzugefügt werden (siehe unten).

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

## Verwendung

Das Plugin aktiviert sich automatisch für Markdown-Dateien. Codeblöcke müssen mit `ascii` als Sprache markiert werden:

### Einfaches ASCII-Art (ohne Sprach-Erkennung)

````markdown
```ascii
┌─────────────────────┐
│  Hello World!       │
└─────────────────────┘
```
````

### Mit expliziter Sprach-Angabe

Syntax: ````ascii-SPRACHE`, ````ascii SPRACHE`, oder ````ascii:SPRACHE`

````markdown
```ascii-c
Struct im Speicher:
┌─────────────────────────────────────┐
│ int id          (4 bytes)           │
├─────────────────────────────────────┤
│ char* name      (8 bytes)           │
└─────────────────────────────────────┘
```
````

### Mit automatischer Sprach-Erkennung

Das Plugin erkennt die Sprache automatisch basierend auf vorhandenen Keywords:

````markdown
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
````

Die Erkennung funktioniert durch:
1. Zählen eindeutiger Keywords (z.B. `local`, `end` → Lua)
2. Priorität auf sprach-spezifische Keywords
3. Fallback auf Buffer-Filetype bei Unsicherheit

### Befehle

- `:ColorMyAscii` - Manuelles Aktualisieren der Hervorhebung
- `:ColorMyAsciiToggle` - Plugin aktivieren/deaktivieren

## Konfiguration

### Minimal-Konfiguration

```lua
require('color_my_ascii').setup()
```

Die Standard-Konfiguration lädt automatisch alle Sprachen und Zeichengruppen aus den `languages/` und `groups/` Verzeichnissen.

### Erweiterte Konfiguration

```lua
require('color_my_ascii').setup({
  -- Zeichenspezifische Overrides (höchste Priorität)
  overrides = {
    ['┌'] = 'Special',
    ['└'] = 'Special',
  },

  -- Standard-Highlighting für nicht zugeordnete Zeichen
  default_hl = 'Normal',

  -- Optional: Standard-Highlighting für normalen Text in Blöcken
  -- nil = keine Änderung, String = Highlight-Gruppe
  default_text_hl = nil,  -- z.B. 'Comment' für gedämpfte Darstellung

  -- Feature-Toggles
  enable_keywords = true,
  enable_language_detection = true,
  language_detection_threshold = 2, -- Minimum unique keyword matches

  -- Treesitter-Integration (experimentell)
  enable_treesitter = false,

  -- Behandle leere Fenced Blocks als ASCII
  -- Wenn true: ``` ohne Sprache = ASCII-Highlighting
  treat_empty_fence_as_ascii = false,

  -- Inline-Code-Highlighting
  -- Wenn true: `...` wird auch hervorgehoben
  enable_inline_code = false,
})
```

### Beispiel-Konfigurationen

**Alles hervorheben (auch leere Blocks und Inline-Code)**:

```lua
require('color_my_ascii').setup({
  treat_empty_fence_as_ascii = true,
  enable_inline_code = true,
})
```

**Gedämpfte Textfarbe in Blöcken**:

```lua
require('color_my_ascii').setup({
  default_text_hl = 'Comment', -- Normaler Text wie Kommentare
})
```

### Neue Sprache hinzufügen

Man erstellt einfach eine neue Datei unter `lua/color_my_ascii/languages/NAME.lua`:

```lua
---@module 'color_my_ascii.languages.NAME'

---@type ColorMyAscii.KeywordGroup
return {
  words = {
    'keyword1', 'keyword2', 'keyword3',
    -- Alle Keywords der Sprache
    -- Auch Multi-Char-Operatoren
    ':=', '==', '!=', '<=', '>=',
  },

  unique_words = {
    'unique_keyword1', 'unique_keyword2',
    -- Keywords die NUR in dieser Sprache vorkommen (für Heuristik)
  },

  hl = 'Function',
}
```

Das Plugin lädt die Datei automatisch beim nächsten Start.

### Neue Zeichengruppe hinzufügen

Man erstellt eine neue Datei unter `lua/color_my_ascii/groups/NAME.lua`:

```lua
---@module 'color_my_ascii.groups.NAME'

---@type ColorMyAscii.CharGroup
local group = {
  chars = '',
  hl = 'Constant',
}

-- WICHTIG: table.concat() muss ausgeführt werden!
local chars = {
  '⚡', '★', '☆', '♦', '♥', '♠', '♣',
}

group.chars = table.concat(chars, '')

return group
```

**Wichtig**: Man muss `table.concat()` explizit aufrufen, nicht als Teil des return statements!

## Architektur

Das Plugin besteht aus mehreren Modulen:

- `init.lua` - Haupteinstiegspunkt, API, State-Management
- `config.lua` - Konfigurationsverwaltung, dynamisches Laden modularer Definitionen
- `parser.lua` - Erkennung von ASCII-Codeblöcken
- `highlighter.lua` - Anwendung von Highlights via Extmarks
- `language_detector.lua` - Intelligente Sprach-Erkennung (explizit, heuristisch, Kontext)
- `languages/*.lua` - Modulare Sprach-Definitionen
- `groups/*.lua` - Modulare Zeichengruppen-Definitionen

## Technische Details

### Sprach-Erkennung (Priorität)

1. **Explizite Angabe** (höchste Priorität)
   - ````ascii-c` → C
   - ````ascii lua` → Lua
   - ````ascii:python` → Python

2. **Heuristische Analyse**
   - Zählt eindeutige Keywords pro Sprache
   - Sprache mit meisten einzigartigen Treffern gewinnt
   - Minimum: 2 eindeutige Treffer (konfigurierbar)

3. **Buffer-Kontext** (niedrigste Priorität)
   - Nutzt Filetype des Buffers als Fallback
   - Nur wenn vorige Methoden fehlschlagen

4. **Keine Erkennung**
   - Alle Keywords aller Sprachen werden hervorgehoben
   - Für generische Diagramme ohne Code-Elemente

### Highlight-Priorität

1. Zeichenspezifische Overrides (höchste Priorität)
2. Zeichengruppen-Zuordnung
3. Keywords (separate Pass für Sichtbarkeit)
4. Default-Highlighting

### Performance

- Debounced Updates (100ms) bei Textänderungen
- Effiziente Lookup-Tabellen für O(1) Zeichenzuordnung
- Extmarks statt virtuellem Text für minimalen Overhead
- Nur aktive Buffer werden verwaltet

## Bekannte Einschränkungen

- Funktioniert nur in Markdown-Dateien
- Keywords müssen als ganze Wörter vorkommen (keine Teilstrings)
- Sprach-Erkennung kann bei mehrdeutigen Keywords fehlschlagen (z.B. `int` in C, C++, Go)
  - Lösung: Explizite Sprach-Angabe oder mehr sprach-spezifische Keywords verwenden
- Modulare Dateien werden beim Plugin-Load geladen (nicht dynamisch zur Laufzeit)

## Lizenz

MIT

## Beitragen

Issues und Pull Requests sind willkommen. Bei größeren Änderungen bitte vorher ein Issue öffnen.
