# Implementation Plan

Synthese aus [Arch&Coding.md](Arch&Coding.md), [Zentral-Prinzipien.md](Zentral-Prinzipien.md),
[Checklist.md](Checklist.md) und dem bestehenden [../ROADMAP.md](../ROADMAP.md).
Dies ist ein reiner Plan (kein Code wurde im Zuge dieser Analyse geändert) — konkrete
Umsetzung erfolgt erst nach Freigabe.

Das Gesamtbild: color_my_ascii.nvim erfüllt bereits den überwiegenden Teil aller drei
Checklisten (Fehlerbehandlung, Modularität, Caching/Debouncing, Doku-Konventionen,
Config-Struktur). Es gibt nur zwei echte Code-Lücken und zwei reine Tooling-Lücken.

## Priorität 🔴 — konkrete Code-Fixes

### 1. Hot-Path: Mehrfach-API-Zugriffe in `highlighter.lua`

**Problem**: `highlight_range(bufnr, line, ...)` (lua/color_my_ascii/highlighter.lua:37)
ruft bei jedem einzelnen Aufruf `nvim_buf_line_count` und `nvim_buf_get_lines` neu auf.
Diese Funktion wird pro Zeile potenziell dutzende Male aufgerufen (einmal pro Zeichen
in `highlight_characters`, einmal pro Keyword-Treffer, einmal pro Funktionsnamen) —
Zeileninhalt und Zeilenanzahl sind aber für die gesamte Dauer von `highlight_block`
konstant.

**Fix**: `line_count` einmal in `highlight_block`/`highlight_inline_codes` ermitteln
und als Parameter durchreichen (oder `line_content` direkt durchreichen, da er in
`highlight_block` bereits aus `block.lines` vorliegt — `nvim_buf_get_lines` in
`highlight_range` entfällt dann komplett für den Block-Pfad). Reduziert die
API-Aufrufe pro Block von O(Zeichen×Zeilen) auf O(Zeilen).

**Risiko**: niedrig — reine interne Signaturänderung, keine öffentliche API betroffen.
**Aufwand**: klein (eine Funktion, ~4 Call-Sites in derselben Datei).

### 2. Totes Feature: `enable_treesitter` — ✅ erledigt

**Ursprüngliches Problem**: `config/DEFAULTS.lua` definierte `enable_treesitter = false`,
`health.lua` prüfte es, aber es gab keine tatsächliche Treesitter-Integration im Code.

**Umsetzung**: `enable_treesitter` (Boolean) wurde durch ein `treesitter`-Config-Table
ersetzt (`{ enabled, block_detection, syntax_highlight }`, alle default
`enabled=false`). Zwei neue, unabhängig voneinander aktivierbare Fähigkeiten:

- **Block-Erkennung** (`lua/color_my_ascii/parser_ts.lua`): nutzt die Markdown-
  Treesitter-Grammatik statt `parser.lua`s heuristischem Zeilen-Scan, mit
  garantiert identischer Blockklassifikation (`parser.is_ascii_fence`, von beiden
  Backends geteilt) und stillem Fallback auf die Heuristik, falls kein
  Markdown-Parser installiert ist oder der Treesitter-Pfad fehlschlägt.
- **Echtes Syntax-Highlighting** (`lua/color_my_ascii/highlighter_ts.lua`): parst
  den Blockinhalt mit der echten Grammatik der erkannten Sprache und highlightet
  zusätzlich per `@`-Capture-Gruppen (höhere Priorität als die Heuristik). Best-effort
  ohne Gate auf Parse-Fehler — ASCII-Art liefert i. d. R. unvollständige/fehlerhafte
  Bäume, aber valide Teilbereiche werden trotzdem korrekt erfasst.

Verifiziert: identische Blockgrenzen zwischen beiden Backends, identisches
Extmark-Verhalten bei `treesitter.enabled=false` (Default) und bei
`block_detection`-only, zusätzliche `@`-Extmarks bei aktiviertem
`syntax_highlight` auf echtem Code. Siehe [README.md](../../README.md#treesitter-integration).

## Priorität 🟡 — Tooling (optional, kein akuter Bedarf)

### 3. `.luarc.json`

Wird in diesem Durchgang direkt angelegt (siehe FINISH.md Punkt 3) — kein
Abstimmungsbedarf, rein additiv, keine Auswirkung auf Laufzeitverhalten.

### 4. Formatter/Linter (stylua, luacheck) + CI

Aktuell weder `.stylua.toml` noch `.github/workflows/` vorhanden. Für ein
Ein-Personen-Repo ohne aktive externe Contributor ist das **nicht dringend** —
wird hier nur als Option vermerkt, nicht umgesetzt. Falls gewünscht: minimaler
`stylua.toml` (2-space indent, passend zum bestehenden Stil) + ein einzelner
GitHub-Actions-Workflow, der `stylua --check` auf PRs laufen lässt.

## Nicht umgesetzt (bewusst ausgelassen)

- **Per-Verzeichnis `@types`-Ordner**: aktuelle Struktur (root `@types.lua` +
  `debug/@types.lua`) deckt den Bedarf; zusätzliche, fast leere Types-Dateien in
  `commands/`, `bindings/`, `groups/`, `languages/`, `schemes/`, `utils/` wären
  Overengineering für die aktuelle Codegröße.
- **Automatisiertes Test-Framework** (plenary/busted): bereits in der vorherigen
  Session bewusst ausgelassen ("state of the art"-Klausel der Original-Checklist);
  bleibt dabei.
- **Tiefere `lib.nvim`-Integration** in `parser.lua`/`highlighter.lua`/
  `cache_manager.lua`/`debounce_manager.lua`: bewusst nicht gemacht, da `lib.nvim`
  laut eigenem README als instabil/early gilt und diese Module performance-kritisch
  sind. Bereits in [../ROADMAP.md](../ROADMAP.md) als "Under Consideration" vermerkt,
  abhängig von `lib.nvim`s Stabilisierung.
- **Sortier-/Datenstruktur-/Bitoperationen-Empfehlungen** aus `Checklist.md`: nicht
  anwendbar, keine entsprechende Logik im Plugin vorhanden.

## Nächste Schritte

1. ✅ `.luarc.json` angelegt.
2. ✅ Fix #1 (Hot-Path) und Fix #2 (echte Treesitter-Integration statt totem Flag) umgesetzt.
3. Tooling-Punkte (#4) nur bei Bedarf/auf Anfrage.
