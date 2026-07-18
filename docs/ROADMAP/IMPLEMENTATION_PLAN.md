# Implementation Plan

Synthese aus [Arch&Coding.md](Arch&Coding.md), [Zentral-Prinzipien.md](Zentral-Prinzipien.md),
[Checklist.md](Checklist.md) und dem bestehenden [../ROADMAP.md](../ROADMAP.md).

color_my_ascii.nvim erfüllt inzwischen **alle** aus den drei Checklisten abgeleiteten
Code- und Tooling-Punkte. Die ursprünglich identifizierten Lücken sind abgearbeitet;
was bleibt, sind bewusst vertagte Design-Entscheidungen (siehe unten).

## Abgeschlossen

Die konkreten Code- und Tooling-Fixes aus früheren Durchgängen sind umgesetzt und
verifiziert — sie sind hier nicht mehr einzeln aufgeführt (siehe Git-Historie /
[../CHANGELOG.md](../CHANGELOG.md)):

- ~~Hot-Path: Mehrfach-API-Zugriffe in `highlighter.lua` (`line_content` wird jetzt
  durchgereicht statt pro Zeichen neu geholt).~~
- ~~`enable_treesitter`-Flag durch echtes `treesitter`-Config-Table + Block-Erkennung
  (`parser_ts.lua`) und Grammar-Highlighting (`highlighter_ts.lua`) ersetzt.~~
- ~~`.luarc.json` angelegt.~~
- ~~**Formatter/Linter (stylua, luacheck) + CI.** `.stylua.toml` (2-Space, Single-Quote,
  120 cols, passend zum Bestandsstil), `.luacheckrc` (luajit-std, `vim` als Global,
  Längenprüfung an stylua delegiert) und `.github/workflows/lint.yml` (`stylua --check`
  + `luacheck` auf Push/PR). Bestand einmalig durchformatiert; beide Linter laufen
  lokal grün (0 Fehler / 0 Warnungen).~~

## Bewusst vertagt (keine offenen Tasks)

Diese Punkte sind dokumentierte Entscheidungen, **nicht** offene Arbeit — sie werden
erst bei nachgewiesenem Bedarf gebaut:

- **Externe Highlighter-API für Fences** (Phase 1–3): siehe
  [fence_highlighter_api.md](fence_highlighter_api.md). Kein konkreter Konsument
  bekannt; Phase 1 (`User ColorMyAsciiFenceBlock`) ist startbereit, sobald einer da ist.
- **Volle LSP im Fence**: siehe [lsp_integration_fence.md](lsp_integration_fence.md).
  Empfehlung: zuerst otter.nvim-Adapter evaluieren, statt eine eigene Embedded-LSP-Engine
  zu bauen.
- **Per-Verzeichnis `@types`-Ordner**: aktuelle Struktur (root `@types.lua` +
  `debug/@types.lua`) deckt den Bedarf; zusätzliche fast leere Types-Dateien wären
  Overengineering für die aktuelle Codegröße.
- **Automatisiertes Test-Framework** (plenary/busted): bewusst ausgelassen
  ("state of the art"-Klausel); manuelle Verifikation über `TESTS/`.
- **Tiefere `lib.nvim`-Integration** in performance-kritischen Modulen: abhängig von
  `lib.nvim`s Stabilisierung, siehe [../ROADMAP.md](../ROADMAP.md) "Under Consideration".
