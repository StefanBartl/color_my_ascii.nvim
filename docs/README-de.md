# color_my_ascii.nvim

```
    ╔══════════════════════════════════════════╗
    ║   c o l o r _ m y _ a s c i i . n v i m   ║
    ║   ┌─┐ → ★ ┌─┐   function() end   ┌─┐      ║
    ╚══════════════════════════════════════════╝
```

> Siehe auch: [markdown.nvim](https://github.com/StefanBartl/markdown.nvim) - ein
> Begleit-Plugin für die Arbeit mit Markdown-Dateien, ergänzt das ASCII-Highlighting hier gut.

![version](https://img.shields.io/badge/version-0.2-blue.svg)
![State](https://img.shields.io/badge/status-beta-orange.svg)
![Lazy.nvim compatible](https://img.shields.io/badge/lazy.nvim-supported-success)
![Neovim](https://img.shields.io/badge/Neovim-0.9+-success.svg)
![Lua](https://img.shields.io/badge/language-Lua-yellow.svg)

> 🔧 Beta-Stadium – aktive Entwicklung. Änderungen möglich.

Ein Neovim-Plugin zum farblichen Hervorheben von ASCII-Art in Markdown-Codeblöcken mit automatischer Sprach-Erkennung, Custom-Highlights und vordefinierten Color-Schemes.

## Table of content

  - [Features](#features)
    - [Core-Features](#core-features)
    - [Erweiterte Features](#erweiterte-features)
  - [Installation](#installation)
    - [Mit lazy.nvim](#mit-lazynvim)
    - [Mit packer.nvim](#mit-packernvim)
  - [Quick Start](#quick-start)
    - [Minimal-Setup](#minimal-setup)
    - [Beispiel](#beispiel)
  - [Konfiguration](#konfiguration)
    - [Standard-Konfiguration](#standard-konfiguration)
    - [Treesitter-Integration](#treesitter-integration)
    - [Mit Color-Scheme](#mit-color-scheme)
    - [Custom-Highlights](#custom-highlights)
    - [Alle Features aktiviert](#alle-features-aktiviert)
  - [Unterstützte Sprachen](#untersttzte-sprachen)
  - [Befehle](#befehle)
    - [Kern-Befehle](#kern-befehle)
    - [Fence-Verwaltung](#fence-verwaltung)
    - [Scheme-Verwaltung](#scheme-verwaltung)
    - [Keybinding-Beispiele](#keybinding-beispiele)
  - [Dokumentation](#dokumentation)
    - [Features](#features-1)
    - [Guides](#guides)
    - [Referenz](#referenz)
  - [Color Schemes](#color-schemes)
    - [Eigenes Schema erstellen](#eigenes-schema-erstellen)
  - [Architektur](#architektur)
  - [Performance](#performance)
  - [Troubleshooting](#troubleshooting)
    - [Keine Highlights sichtbar](#keine-highlights-sichtbar)
    - [Falsche Sprache erkannt](#falsche-sprache-erkannt)
    - [Performance-Probleme](#performance-probleme)
  - [Contributing](#contributing)
    - [Neue Sprache hinzufügen](#neue-sprache-hinzufgen)
    - [Neue Zeichengruppe hinzufügen](#neue-zeichengruppe-hinzufgen)
  - [Credits](#credits)
  - [Siehe auch](#siehe-auch)

---

## Features

### Core-Features

- ✅ **Automatische Erkennung** von `ascii`-Codeblöcken in Markdown-Dateien
- ✅ **Modulare Sprach-Definitionen**: 31 vordefinierte Sprachen (C, C++, C#, Lua, Go, Rust, TypeScript, JavaScript, Python, Bash, Zig, LLVM IR, Vimscript, Java, PHP, Ruby, Kotlin, Swift, Scala, Dart, Elixir, Haskell, Perl, R, Clojure, Groovy, PowerShell, SQL, JSON, HTML, CSS)
- ✅ **Intelligente Sprach-Erkennung**:
  - Explizite Angabe via ````ascii-c`, ````ascii lua`, ````ascii:python`
  - Standard-Markdown-Fence-Tags via `fence_language_map` (z. B. ` ```vim `)
  - Heuristische Erkennung basierend auf Keyword-Häufigkeit
  - Fallback auf Buffer-Filetype
- ✅ **Modulare Zeichengruppen**: Anpassbare Gruppen für Linien, Blöcke, Pfeile, Symbole, Operatoren
- ✅ **Custom-Highlights mit RGB/Hex**: Vollständige Farb- und Style-Kontrolle
- ✅ **10 vordefinierte Color-Schemes**: Default, Matrix, Nord, Gruvbox, Dracula, Catppuccin, One Dark, Solarized, Tokyo Night, Monokai
- ✅ **Nicht-intrusiv**: Verwendet Extmarks, keine Puffer-Änderung

---

### Erweiterte Features

- ✅ **Funktionsnamen-Erkennung**: Heuristik für `word()`-Pattern
- ✅ **Bracket-Highlighting**: Automatisches Hervorheben von `()[]{}`
- ✅ **Inline-Code-Highlighting**: Keywords und Symbole in `` `...` ``
- ✅ **Leere Fenced Blocks**: Optional ``` ohne Sprache als ASCII behandeln
- ✅ **Standard-Textfarbe**: Gedämpfte Darstellung für normalen Text
- ✅ **Health Check**: `:checkhealth color_my_ascii`
- ✅ **Fence-Validierung**: `:ColorMyAscii check-fences` zur Erkennung nicht geschlossener Blöcke
- ✅ **Vim Help**: `:h color_my_ascii`
- ✅ **Optionale Treesitter-Integration**: Block-Erkennung und echtes Syntax-Highlighting
- ✅ **Optionale, deaktivierbare Default-Keymaps** mit which-key-Unterstützung

---

## Installation

**Lade-Strategie**: Das Plugin wird via `ft = 'markdown'` geladen, also erst sobald
eine Markdown-Datei geöffnet wird. Das ist der empfohlene Trigger für dieses
Plugin - präziser als ein pauschales `event = "VeryLazy"`, da es nichts zu tun
gibt, bevor tatsächlich eine Markdown-Datei bearbeitet wird.

### Mit lazy.nvim
````lua
{
  'StefanBartl/color_my_ascii.nvim',
  ft = 'markdown',
  dependencies = { 'StefanBartl/lib.nvim' }, -- erforderlich: :ColorMyAscii baut darauf auf
  opts = {
    -- Optional: Konfiguration hier
  }
}
````

---

### Mit packer.nvim
````lua
use {
  'StefanBartl/color_my_ascii.nvim',
  ft = 'markdown',
  requires = { 'StefanBartl/lib.nvim' }, -- erforderlich: :ColorMyAscii baut darauf auf
  config = function()
    require('color_my_ascii').setup({
      -- Optional: Konfiguration hier
    })
  end
}
````

---

## Quick Start

### Minimal-Setup
````lua
require('color_my_ascii').setup()
````

Das Plugin aktiviert sich automatisch für Markdown-Dateien.

---

### Beispiel
````markdown
```ascii
┌─────────────────────┐
│  Hello World!       │
└─────────────────────┘
```
````

→ Box-Zeichen werden automatisch farbig hervorgehoben

---

## Konfiguration

### Standard-Konfiguration
````lua
require('color_my_ascii').setup({
  debug_enabled = false,
  debug_verbose = false,
  scheme = 'default',

  -- Zeichenspezifische Overrides (höchste Priorität)
  overrides = {},

  -- Standard-Highlighting für nicht zugeordnete Zeichen
  default_hl = 'Normal',

  -- Optional: Standard-Highlighting für normalen Text in Blöcken
  default_text_hl = nil,  -- z. B. 'Comment' für gedämpfte Darstellung

  -- Feature-Toggles
  enable_keywords = true,
  enable_language_detection = true,
  language_detection_threshold = 2,
  enable_function_names = true,
  enable_bracket_highlighting = true,
  treat_empty_fence_as_ascii = true,
  enable_inline_code = true,

  -- Standard-Markdown-Fence-Tags, die als ASCII-Blöcke behandelt werden.
  -- Mappt die Fence-Sprachkennung auf den Plugin-Sprachnamen.
  fence_language_map = {
    vim = 'vim',
    vimscript = 'vim',
    viml = 'vim',
  },

  -- Optionale Treesitter-Integration, standardmäßig an (siehe unten)
  treesitter = {
    enabled = true,
    block_detection = true,
    syntax_highlight = true,
  },
})
````

---

### Treesitter-Integration

Standardmäßig an. Beide Teilfunktionen fallen automatisch und still auf rein
heuristisches Verhalten zurück, wenn der jeweilige Parser nicht installiert
ist — es gibt also keinen Nachteil, das aktiviert zu lassen, selbst ganz ohne
Treesitter-Setup. Mit `enabled = false` komplett deaktivieren. Die beiden
Teil-Flags lassen sich außerdem unabhängig voneinander umschalten:

- **`block_detection`**: Nutzt Neovims Markdown-Treesitter-Grammatik zur
  Erkennung von Fenced-Code-Blöcken statt des eingebauten Zeilen-Scanners.
  Robuster bei Randfällen (verschachtelte Fences, ungewöhnliche Einrückung).
  Benötigt einen `markdown`-Parser (`:TSInstall markdown`); fällt bei
  fehlendem Parser automatisch auf den heuristischen Scanner zurück.
- **`syntax_highlight`**: Highlightet den Blockinhalt zusätzlich mit der
  echten Grammatik der erkannten Sprache (z. B. echte Lua-/Python-/C-Syntax
  via `@`-Highlight-Gruppen), zusätzlich zum bestehenden Zeichen-/Keyword-
  Highlighting. Best-effort: ASCII-Art ist meist keine valide Syntax, daher
  wirkt sich das nur auf Blöcke (oder Blockteile) aus, die tatsächlich echten,
  parsbaren Code enthalten. Benötigt einen Parser für die jeweilige Sprache
  (`:TSInstall <language>`); tut bei fehlendem/nicht parsbarem Inhalt
  stillschweigend nichts.

```lua
-- Komplett deaktivieren
require('color_my_ascii').setup({
  treesitter = { enabled = false },
})

-- Oder Block-Erkennung behalten, aber die (teurere) Syntax-Highlighting-Phase überspringen
require('color_my_ascii').setup({
  treesitter = { syntax_highlight = false },
})
```

`:checkhealth color_my_ascii` zeigt an, ob die benötigten Parser installiert sind.

---

### Mit Color-Scheme
````lua
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
````

---

### Custom-Highlights
````lua
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
````

---

### Alle Features aktiviert
````lua
require('color_my_ascii').setup({
  enable_keywords = true,
  enable_language_detection = true,
  enable_function_names = true,
  enable_bracket_highlighting = true,
  treat_empty_fence_as_ascii = true,
  enable_inline_code = true,
  default_text_hl = 'Comment',
})
````

---

## Unterstützte Sprachen

Das Plugin enthält vordefinierte Keyword-Definitionen für:

| Sprache | Unique Keywords | Beispiel |
|---------|----------------|----------|
| C | `restrict`, `_Bool`, `_Complex` | `int`, `void`, `char` |
| C++ | `class`, `namespace`, `template` | `virtual`, `override`, `nullptr` |
| C# | `foreach`, `delegate`, `sealed` | `class`, `async`, `await` |
| Lua | `then`, `elseif`, `end` | `function`, `local`, `nil` |
| Go | `func`, `chan`, `defer` | `go`, `:=`, `<-` |
| Rust | `fn`, `mut`, `impl` | `trait`, `match`, `loop` |
| TypeScript | `interface`, `namespace` | `async`, `await`, `Promise` |
| JavaScript | `console`, `NaN`, `globalThis` | `function`, `async`, `await` |
| Python | `def`, `elif`, `pass` | `lambda`, `self`, `yield` |
| Bash | `fi`, `esac`, `done` | `if`, `then`, `else` |
| Zig | `comptime`, `errdefer` | `anytype`, `unreachable` |
| LLVM IR | `getelementptr`, `phi` | `alloca`, `icmp`, `zext` |
| Vimscript | `endif`, `endfunction`, `nnoremap` | `augroup`, `echom`, `setlocal` |
| Java | `implements`, `throws`, `synchronized` | `class`, `public`, `static` |
| PHP | `echo`, `require_once`, `isset` | `function`, `class`, `foreach` |
| Ruby | `elsif`, `unless`, `attr_accessor` | `def`, `end`, `module` |
| Kotlin | `fun`, `companion`, `suspend` | `val`, `var`, `class` |
| Swift | `guard`, `fileprivate`, `deinit` | `func`, `var`, `let` |
| Scala | `trait`, `implicit`, `object` | `def`, `val`, `case` |
| Dart | `mixin`, `covariant`, `late` | `void`, `class`, `async` |
| Elixir | `defmodule`, `defp`, `defmacro` | `def`, `do`, `end` |
| Haskell | `newtype`, `deriving`, `Maybe` | `data`, `type`, `where` |
| Perl | `bless`, `wantarray`, `qw` | `my`, `sub`, `if` |
| R | `sapply`, `lapply`, `ifelse` | `function`, `TRUE`, `FALSE` |
| Clojure | `defn`, `recur`, `deref` | `let`, `fn`, `def` |
| Groovy | `println`, `findAll`, `GString` | `def`, `class`, `closure` |
| PowerShell | `param`, `trap` | `function`, `foreach`, `try` |
| SQL | `SELECT`, `INSERT`, `JOIN` | `WHERE`, `FROM`, `UPDATE` |
| JSON | *(keine - nur explizites Tag)* | `true`, `false`, `null` |
| HTML | `DOCTYPE`, `textarea`, `thead` | `div`, `span`, `class` |
| CSS | `keyframes`, `rgba`, `important` | `display`, `flex`, `color` |

### Standard-Fence-Tag-Unterstützung

Blöcke mit einem Standard-Markdown-Fence-Tag werden automatisch hervorgehoben,
wenn dieser Tag in `fence_language_map` gelistet ist - das schließt
standardmäßig **jede der obigen Sprachen unter ihrem gängigen Tag** ein (z. B.
` ```go `, ` ```js `/` ```javascript `, ` ```py `/` ```python `,
` ```rb `/` ```ruby `, ...), nicht nur die `ascii`-präfixierten Formate:

````markdown
```vim
function! MyFunc()
  ┌──────────────────────────┐
  │  nnoremap <leader>w :w<CR>│
  └──────────────────────────┘
endfunction
```
````

Siehe [config/DEFAULTS.lua](../lua/color_my_ascii/config/DEFAULTS.lua) für die
vollständige Default-Map (inkl. Aliase wie `sh`/`py`/`ts`/`rs`/`kt`/`cs`).
Eigene Einträge ergänzen oder überschreiben:

````lua
require('color_my_ascii').setup({
  fence_language_map = {
    myasciitag = 'python',  -- zusätzlichen Tag zu den Defaults hinzufügen
  },
})
````

Weitere Sprachen können einfach hinzugefügt werden (siehe [Contributing](#contributing)).

---

## Befehle

### Kern-Befehle

| Befehl | Beschreibung |
|--------|--------------|
| `:ColorMyAscii` | Manuelles Aktualisieren der Hervorhebung |
| `:ColorMyAscii toggle` | Plugin aktivieren/deaktivieren |
| `:ColorMyAscii debug` | Debug-Informationen anzeigen (einfach) |
| `:ColorMyAscii show-config` | Detaillierte Konfiguration anzeigen |
| `:checkhealth color_my_ascii` | Health-Check durchführen |
| `:h color_my_ascii` | Vim-Help öffnen |

---

### Fence-Verwaltung

| Befehl | Beschreibung |
|--------|--------------|
| `:ColorMyAscii check-fences` | Nicht geschlossene Fences prüfen |
| `:ColorMyAscii ensure-blank-lines` | Leerzeilen um Codeblöcke sicherstellen |

---

### Scheme-Verwaltung

| Befehl | Beschreibung |
|--------|--------------|
| `:ColorMyAscii schemes list` | Verfügbare Schemes auflisten |
| `:ColorMyAscii schemes switch <name>` | Zu anderem Scheme wechseln |
| `:ColorMyAscii schemes pick` | Scheme mit Telescope auswählen (Live-Vorschau) |

---

#### Verfügbare Schemes

- `default`    - Built-in Neovim Highlights
- `matrix`     - Grüner Hacker-Style
- `nord`       - Kühles Blau/Cyan
- `gruvbox`    - Warme Retro-Farben
- `dracula`    - Lebendiges Lila/Pink
- `catppuccin` - Sanfte Pastellfarben
- `onedark`    - Dunkles Theme mit dezenten Highlights
- `solarized`  - Solarized-Farbpalette
- `tokyonight` - Dunkles Theme mit blauen Akzenten
- `monokai`    - Klassisches Monokai-Farbschema

### Keybinding-Beispiele

Keymaps sind **opt-in** und standardmäßig deaktiviert. Aktivieren und anpassen
lassen sie sich über die `keymaps`-Option in `setup()`:

```lua
require('color_my_ascii').setup({
  keymaps = {
    highlight           = '<leader>ah',
    toggle              = '<leader>at',
    schemes             = '<leader>as',
    ensure_blank_lines  = '<leader>af',
    show_config         = '<leader>ac',
    debug               = '<leader>ad',
    check_fences        = '<leader>ax',
  },
})
```

Jede Keymap wird mit `desc` gesetzt, sodass [which-key.nvim](https://github.com/folke/which-key.nvim)
sie automatisch erkennt, ohne zusätzliche Konfiguration. Ist
[lib.nvim](https://github.com/StefanBartl/lib.nvim) installiert, wird es für
die Keymap-Registrierung genutzt; andernfalls nutzt das Plugin `vim.keymap.set`.

Siehe [docs/BINDINGS.md](BINDINGS.md) für die vollständige Übersicht aller
Commands, Keymap-Aktionen und Autocommands.

---

## Dokumentation

### Features

- [Features](FEATURES/README.md) - vollständiger Feature-Katalog nach Themen

---

### Guides

- [Quickstart](QUICKSTART-de.md) - Erste Schritte
- [Test File](dev/TEST.md) - Alle Features testen
- [Color Schemes](schemes.md) - Eigene Schemes erstellen
- [Bindings-Übersicht](BINDINGS.md) - Alle Commands, Keymaps und Autocommands

---

### Referenz

- [Vim Help](../doc/color_my_ascii.txt) - Vollständige Referenz
- [Changelog](CHANGELOG.md) - Versionshistorie

---

## Color Schemes

Wähle ein Schema aus der Liste der [verfügbaren Schemes](#verfgbare-schemes)
und setze es in der Initialisierung:

Beispiel mit Matrix-Schema:

````lua
require('color_my_ascii').setup({
  scheme = "matrix",
})
````

Dunkler Hintergrund mit leuchtend grünen Elementen. Alle Features aktiviert.

---

### Eigenes Schema erstellen
````lua
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
````

Siehe [Color Schemes Guide](schemes.md) für Details.

---

## Architektur

Das Plugin besteht aus mehreren Modulen:

- `init.lua` - Haupteinstiegspunkt, öffentliche API, State-Management
- `config/` - Konfigurationsverwaltung (`DEFAULTS.lua` + `init.lua`), dynamisches Laden
- `bindings/` - Registrierung von Usercommands (`usrcmds.lua`), Autocommands
  (`autocmds.lua`) und optionalen Keymaps (`keymaps.lua`)
- `parser.lua` / `parser_ts.lua` - Erkennung von ASCII-Codeblöcken (heuristisch
  bzw. via Treesitter) und Inline-Code
- `highlighter.lua` / `highlighter_ts.lua` - Anwendung von Highlights via
  Extmarks (heuristisch bzw. via Treesitter-Syntax)
- `language_detector.lua` - Intelligente Sprach-Erkennung
- `cache_manager.lua` / `debounce_manager.lua` - Performance (Caching,
  adaptives Debouncing)
- `health.lua` - Health-Check für `:checkhealth`
- `languages/*.lua` - Modulare Sprach-Definitionen
- `groups/*.lua` - Modulare Zeichengruppen-Definitionen
- `schemes/*.lua` - Vordefinierte Color-Schemes

---

## Performance

Das Plugin verwendet:
- Extmarks für non-intrusive Highlights
- Debounced Updates (adaptiv, 100–500ms je nach Dateigröße) bei Textänderungen
- Effiziente Lookup-Tabellen (O(1) Zugriff)
- Lazy-Loading für Markdown-Dateien

Selbst große Dokumente (>1000 Zeilen) sollten keine Performance-Probleme verursachen.

**Hinweis**: `enable_inline_code` kann bei sehr großen Dateien (>5000 Zeilen) zu Verlangsamungen führen.

---

## Troubleshooting

### Keine Highlights sichtbar

1. Plugin geladen?
````vim
:ColorMyAscii debug
````

2. Buffer ist Markdown?
````vim
:set filetype?
````

3. Health-Check durchführen
````vim
:checkhealth color_my_ascii
````

---

### Falsche Sprache erkannt

Explizite Sprach-Angabe verwenden:
````markdown
```ascii-c
int x = 42;
```
````

Oder einen Standard-Fence-Tag nutzen (falls in `fence_language_map` gelistet):
````markdown
```vim
nnoremap <leader>w :w<CR>
```
````

Oder Detection-Threshold anpassen:
````lua
require('color_my_ascii').setup({
  language_detection_threshold = 3,  -- Strenger
})
````

---

### Performance-Probleme

Features deaktivieren:
````lua
require('color_my_ascii').setup({
  enable_function_names = false,
  enable_inline_code = false,
})
````

---

## Contributing

Issues und Pull Requests sind willkommen. Bei größeren Änderungen bitte vorher ein Issue öffnen.

---

### Neue Sprache hinzufügen

1. Datei erstellen: `lua/color_my_ascii/languages/NAME.lua`
2. Keywords definieren:
````lua
---@module 'color_my_ascii.languages.NAME'
---@type ColorMyAscii.KeywordGroup
return {
  words = { 'keyword1', 'keyword2', ... },
  unique_words = { 'unique1', 'unique2', ... },
  hl = 'Function',
}
````

3. Plugin neu laden

---

### Neue Zeichengruppe hinzufügen

1. Datei erstellen: `lua/color_my_ascii/groups/NAME.lua`
2. Characters definieren:
````lua
---@module 'color_my_ascii.groups.NAME'
---@type ColorMyAscii.CharGroup
local group = {
  chars = '',
  hl = 'Keyword',
}

local chars = { '⚡', '★', '☆' }
group.chars = table.concat(chars, '')

return group
````

3. Plugin neu laden

---

## Credits

- Inspiriert von verschiedenen ASCII-Art-Highlighting-Plugins
- Color-Schemes basierend auf populären Vim/Neovim-Themes
- Danke an alle Contributors

---

## Siehe auch

- [Neovim Documentation](https://neovim.io/doc/)
- [Extmarks API](https://neovim.io/doc/user/api.html#api-extmarks)
- [Markdown Syntax](https://www.markdownguide.org/basic-syntax/)

---
