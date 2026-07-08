# Roadmap

Ideas and planned work for color_my_ascii.nvim. Nothing here is committed to a
timeline - this is a working list of what might come next.

## weitere sinnvolle `:Fence`-Features

Der Dispatcher ist genau dafür gebaut. Ideen, die `:Fence` zu einem kleinen Literate-Programming-Werkzeug machen:

- **`:Fence yank`** — Inhalt (ohne Marker) ins Register/Clipboard.
- **`:Fence open`** — Fence-Inhalt in einem Split mit korrektem Filetype öffnen, optional **auf `:w` zurücksynchen** (Mini-„otter-lite" zum bequemen Editieren + volles LSP im Split).
- **`:Fence run`** — Block mit dem Sprach-Interpreter ausführen, Output anzeigen (Code-Runner / literate execution).
- **`:Fence format`** — Formatter der Sprache (conform/`formatprg`) auf den Block anwenden, in-place.
- **`:Fence import <file>`** — Umkehrung von export: Datei in den Fence einlesen/ersetzen → hält Tangle synchron.
- **`:Fence lang <neu>`** — Sprach-Tag des Fences ändern.
- **`:Fence select`** — Fence-Inhalt visuell selektieren.
- **`:Fence wrap` / `unwrap`** — Selektion in einen Fence wickeln / Fence auflösen.

Mein Tipp für den größten Nutzen als Nächstes: **`:Fence open` mit Sync** — das gibt dir de facto volles LSP + Formatter im Fence *ohne* die große Embedded-LSP-Engine, weil du im echten Split-Buffer editierst. Sag Bescheid, dann baue ich das (oder yank/run/format) als nächsten Subcommand.

## Planned

- Additional built-in color schemes

## Implemented

- Optional treesitter-based block detection and real syntax highlighting
  (`treesitter.block_detection` / `treesitter.syntax_highlight`), on by
  default via `treesitter.enabled = true` - falls back silently to
  heuristic-only behavior wherever a parser isn't installed.
  See [README.md](../README.md#treesitter-integration).
- 31 predefined languages (up from 11), with `fence_language_map` now covering
  every one of them under its common tag(s) by default - plain ` ```go `/
  ` ```javascript `/` ```json ` etc. blocks are highlighted without needing the
  `ascii-` prefix. See [README.md](../README.md#supported-languages).

## Under Consideration

- Additional default keymap actions (see [BINDINGS.md](BINDINGS.md) for the current set)
- Additional autocommand hooks (e.g. re-highlight on `ColorScheme` change)
- Additional user commands for scheme/keyword introspection
- Deeper `lib.nvim` integration if/once its API stabilizes

## Engineering Checklists & Implementation Plan

Internal (German) notes distilling the project's Lua/Neovim architecture and coding
checklists down to what's actually relevant for this plugin's size, plus a concrete
implementation plan derived from them:

- [ROADMAP/Arch&Coding.md](ROADMAP/Arch&Coding.md)
- [ROADMAP/Zentral-Prinzipien.md](ROADMAP/Zentral-Prinzipien.md)
- [ROADMAP/Checklist.md](ROADMAP/Checklist.md)
- [ROADMAP/IMPLEMENTATION_PLAN.md](ROADMAP/IMPLEMENTATION_PLAN.md)
