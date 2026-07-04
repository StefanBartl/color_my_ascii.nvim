# Zentrale Prinzipien — angewendet auf color_my_ascii.nvim

Destilliert aus `Zentrale-Prinzipien.md` (10-Punkte-Mentalcheck). Alle 10 Punkte sind
grundsätzlich anwendbar, da es sich um Fragen zu Event-Handling, Caching und
Hot-Path-Verhalten handelt — genau das Kerngeschäft dieses Plugins.

## 1. Events bündeln, Logik entkoppeln

Kein Problem: Jedes Event hat genau einen Handler (`FileType markdown` →
`bindings/autocmds.lua`; `TextChanged`/`TextChangedI`/`BufDelete` → `init.lua`s
`setup_buffer`). Keine verstreute Mehrfachbindung an dasselbe Event.

## 2. Eigene Logik lazy laden

Bereits umgesetzt: Plugin lädt nur bei `ft = 'markdown'` (lazy.nvim); das
`debug/`-Modul wird nur bei `debug_enabled = true` require't (`config/init.lua`).

## 3. Kontext statt Mehrfach-API-Zugriffe

**Gap**: `highlighter.lua`s `highlight_range()` ruft für **jeden einzelnen**
Highlight-Aufruf (jedes Zeichen, jedes Keyword, jeder Funktionsname) erneut
`nvim_buf_line_count` und `nvim_buf_get_lines` auf, obwohl Zeilenanzahl und
-inhalt pro Zeile in `highlight_block`/`highlight_inline_codes` bereits bekannt
sind. Konkreter Verbesserungsvorschlag in [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md).

## 4. Autocommand-Gruppen sauber nutzen

Eingehalten: `ColorMyAscii`-Augroup (statisch) und `ColorMyAsciiBuffer_<bufnr>`
(pro Buffer) mit `clear = true`. Reload-sicher.

## 5. Event oder Command?

Passend gelöst: Highlighting läuft automatisch bei `TextChanged`/`TextChangedI`
(das ist der Kern-Zweck des Plugins, kein Fall für ausschließlich manuelle
Trigger), zusätzlich aber auch als expliziter `:ColorMyAscii`-Command verfügbar.

## 6. Treesitter notwendig oder nicht?

Bewusst regex-/heuristikbasiert (kein Treesitter im Hot-Path) — richtige
Entscheidung für ASCII-Art-Erkennung in Codeblöcken, die keine echte
Syntax-Semantik braucht. **Aber**: `enable_treesitter`-Flag existiert in
`config/DEFAULTS.lua` und wird in `health.lua` abgefragt, hat aber **keine
tatsächliche Implementierung**. Totes/unfertiges Feature — siehe Implementierungsplan.

## 7. Cache vorhanden und explizit?

Ja (`cache_manager.lua`): explizit, invalidierbar über `changedtick`, TTL-basiert.
Liegt bewusst im Runtime-State (nicht `stdpath("cache")`), was hier korrekt ist —
es handelt sich um einen ephemeren Parse-Cache pro Session, keine
persistierungswürdigen Daten.

## 8. Allokationen im Hot-Path vermeiden

Größtenteils unkritisch: `vim.fn.split(line_content, '\\zs')` erzeugt pro Zeile
eine neue Tabelle (in `highlight_characters`/`highlight_inline_codes`) — vertretbar,
da einmal pro Zeile statt pro Zeichen. Keine String-Konkatenation in Schleifen
gefunden.

## 9. Debugbarkeit eingeplant?

Ja: `debug_enabled`/`debug_verbose`-Flags, dediziertes `debug/`-Modul,
`:ColorMyAsciiDebug`-Command, `:checkhealth color_my_ascii`.

## 10. Laufzeit wichtiger als Startup?

Ja, korrekt priorisiert: `debounce_manager.lua` skaliert die Debounce-Verzögerung
adaptiv nach Dateigröße (100/200/500ms), um `TextChanged`/`TextChangedI` nicht zu
überlasten. Startup-Overhead ist bei `ft`-lazy-loading ohnehin minimal.

## Fazit

Von den 10 Prinzipien sind 8 bereits erfüllt. Zwei konkrete, umsetzbare Lücken:
Mehrfach-API-Zugriffe im Hot-Path (Punkt 3) und das unfertige
`enable_treesitter`-Flag (Punkt 6). Beide im [Implementierungsplan](IMPLEMENTATION_PLAN.md).
