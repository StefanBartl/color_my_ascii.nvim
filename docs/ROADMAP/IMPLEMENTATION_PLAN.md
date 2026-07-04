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

### 2. Totes Feature: `enable_treesitter`

**Problem**: `config/DEFAULTS.lua` definiert `enable_treesitter = false`,
`health.lua:178` prüft es, aber es gibt **keine** tatsächliche Treesitter-Integration
im Code. Aktiviert ein Nutzer das Flag, passiert nichts außer einer Warnung, falls
`nvim-treesitter` fehlt — aber auch wenn es vorhanden ist, ändert sich nichts.

**Fix-Optionen** (Entscheidung beim nächsten Schritt):
- (a) Flag vorerst entfernen und stattdessen nur in `docs/ROADMAP.md` als "Planned"
  führen (bereits dort gelistet), bis eine echte Implementierung ansteht — vermeidet
  ein irreführendes No-Op-Flag in der Public API.
- (b) Flag behalten, aber `health.lua` um einen expliziten Hinweis ergänzen
  ("Treesitter integration is planned but not yet implemented") statt nur bei
  fehlendem `nvim-treesitter` zu warnen.

**Empfehlung**: (b) — kleinerer, nicht-breaking Fix; vermeidet stille Verwirrung ohne
eine bestehende (wenn auch ungenutzte) Config-Option zu entfernen.

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

1. `.luarc.json` anlegen (dieser Durchgang, siehe unten).
2. Bei Freigabe: Fix #1 (Hot-Path) und Fix #2b (Treesitter-Health-Hinweis) umsetzen —
   beide klein, risikoarm, unabhängig voneinander.
3. Tooling-Punkte (#4) nur bei Bedarf/auf Anfrage.
