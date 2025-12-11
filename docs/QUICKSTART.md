# Quickstart Guide

## Installation

### Mit lazy.nvim

```lua
{
  'username/color_my_ascii.nvim',
  ft = 'markdown',
  config = function()
    require('color_my_ascii').setup()
  end
}
```

### Manuelle Installation

1. Repository klonen nach `~/.config/nvim/pack/plugins/start/color_my_ascii.nvim`
2. Neovim neu starten
3. Das Plugin lädt automatisch

## Verzeichnisstruktur

Das Plugin benötigt folgende Struktur:

```
color_my_ascii.nvim/
├── plugin/color_my_ascii.lua
└── lua/color_my_ascii/
    ├── init.lua
    ├── config.lua
    ├── parser.lua
    ├── highlighter.lua
    ├── language_detector.lua
    ├── languages/
    │   ├── c.lua
    │   ├── cpp.lua
    │   ├── lua.lua
    │   ├── go.lua
    │   ├── rust.lua
    │   ├── typescript.lua
    │   ├── python.lua
    │   ├── bash.lua
    │   ├── zig.lua
    │   └── llvm.lua
    └── groups/
        ├── box_drawing.lua
        ├── blocks.lua
        ├── arrows.lua
        └── symbols.lua
```

## Erste Schritte

1. Öffne eine Markdown-Datei: `:e test.md`

2. Füge einen ASCII-Codeblock ein:

````markdown
```ascii
┌─────────────┐
│ Hello World │
└─────────────┘
```
````

3. Die Box-Zeichen sollten automatisch farbig hervorgehoben werden

## Neue Features

### Leere Fenced Blocks als ASCII behandeln

```lua
require('color_my_ascii').setup({
  treat_empty_fence_as_ascii = true,
})
```

Jetzt wird auch ``` ohne Sprache als ASCII behandelt:

````markdown
```
┌─────┐
│ Box │
└─────┘
```
````

### Inline-Code-Highlighting

```lua
require('color_my_ascii').setup({
  enable_inline_code = true,
})
```

Jetzt werden auch Keywords und Symbole in Inline-Code hervorgehoben:

```markdown
Man verwendet `func` in Go und `→` für Pfeile.
```

### Standard-Textfarbe in Blöcken

```lua
require('color_my_ascii').setup({
  default_text_hl = 'Comment',
})
```

Normaler Text in Blöcken wird gedämpft dargestellt (wie Kommentare), während Keywords und Symbole hervorgehoben bleiben.

## Debugging

Falls nichts passiert:

```vim
" Prüfe ob Plugin geladen wurde
:ColorMyAsciiDebug

" Zeige geladene Sprachen und Gruppen
" Sollte ausgeben:
" Languages loaded: 10
" Groups loaded: 4
" Character lookup entries: 100+
" Keyword lookup entries: 500+

" Manuelles Highlighting erzwingen
:ColorMyAscii

" Plugin an/aus schalten
:ColorMyAsciiToggle
```

## Häufige Fehler

### "No language files found" oder "No group files found"

**Problem**: Die `languages/` oder `groups/` Verzeichnisse existieren nicht oder sind leer.

**Lösung**: Stelle sicher, dass alle Dateien aus den Artifacts vorhanden sind.

### "attempt to call a table value"

**Problem**: Wurde in Version 1.1 behoben durch korrekte UTF-8 Iteration.

**Lösung**: Aktualisiere auf die neueste Version.

### Keine Highlights sichtbar

**Problem 1**: Buffer ist nicht als Markdown erkannt
```vim
:set ft?
" Sollte ausgeben: filetype=markdown
```

**Problem 2**: ASCII-Block falsch formatiert
- Fence muss mit `ascii` beginnen: ````ascii` nicht ````asci` oder ````ASCII`
- Unterstützt: ````ascii`, ````ascii-c`, ````ascii lua`, ````ascii:python`

**Problem 3**: Keine Zeichengruppen geladen
```vim
:ColorMyAsciiDebug
" Prüfe ob "Groups loaded: 4" angezeigt wird
```

## Syntaxvarianten

Das Plugin unterstützt mehrere Syntax-Varianten:

```markdown
# Einfach
```ascii
┌────┐
```

# Mit Sprache (Bindestrich)
```ascii-c
int x;
```

# Mit Sprache (Leerzeichen)
```ascii lua
local x
```

# Mit Sprache (Doppelpunkt)
```ascii:go
func main()
```
```

Alle Varianten funktionieren für die Sprach-Erkennung.

## Performance

Das Plugin verwendet:
- Extmarks für non-intrusive Highlights
- Debounced Updates (100ms) bei Textänderungen
- Effiziente Lookup-Tabellen (O(1) Zugriff)
- Lazy-Loading für Markdown-Dateien

Selbst große Dokumente sollten keine Performance-Probleme verursachen.
