# Lua/Neovim-Checkliste — angewendet auf color_my_ascii.nvim

Die Quelle (`Checklist.md`) ist eine generische Referenz für sehr unterschiedliche
Lua-Projekte, inkl. ganzer Abschnitte zu Sortieralgorithmen, Datenstrukturen
(Bäume, Skip-Lists, Tries, Hash-Tabellen-Interna), Bitoperationen und
Streaming-/ETL-Architekturen. **Keiner dieser Abschnitte ist für
color_my_ascii.nvim relevant** — das Plugin parst Markdown-Buffer mit einfachen
String-Operationen und Lookup-Tabellen, es gibt keine eigenen Sortier- oder
Graph-/Baum-Algorithmen, keine Bit-Tricks, keine Netzwerk-/Streaming-Verarbeitung.
Diese Abschnitte wurden komplett ausgelassen. Übernommen wurde nur, was für ein
Buffer-Highlighting-Plugin dieser Größe greift.

## Schnell-Check (vor jedem Merge)

| Prüfschritt | Status hier |
|---|---|
| Fehlerbehandlung vorhanden (pcall/Wrapper) | ✅ Erfüllt |
| Type Guards vor API-Zugriff | ✅ Erfüllt |
| Buffer/Window validieren (`nvim_*_is_valid`) | ✅ Erfüllt (`utils/safe_api.lua`) |
| Keine globalen States | ✅ Erfüllt |
| Single Responsibility pro Modul | ✅ Erfüllt |
| UI-Cleanup (`cleanup_all()`) | ✅ Sinngemäß erfüllt (`BufDelete`-Autocmd räumt Highlighter/Cache/Debounce auf) |
| Performance-Hotspots (`table.concat`, Vorreservierung) | ✅ Keine Verstöße gefunden |
| Annotationen vollständig | ✅ Erfüllt |
| Testbarkeit (Pure Functions, DI) | 🟡 Teilweise — kein automatisiertes Testsystem (siehe unten) |
| Import-Reihenfolge | ✅ Erfüllt |

## PR-Review-Checkliste (relevante Punkte)

### Modularität und Struktur

| Prüfschritt | Status |
|---|---|
| `/config`-Ordner mit `DEFAULTS.lua` | ✅ Bereits umgesetzt (`config/DEFAULTS.lua`, `config/init.lua`) |
| Registry-Pattern für Tools | Nicht anwendbar — keine dynamisch registrierten "Tools", nur feste Commands/Sprachen/Gruppen über Verzeichnis-Globbing (`config/init.lua`s `load_languages`/`load_groups` sind bereits ein leichtgewichtiges Registry-Äquivalent) |

### Tooling

| Prüfschritt | Status |
|---|---|
| Lua LS Settings (`diagnostics.globals=vim`, `workspace.library`) | ✅ Erledigt — `.luarc.json` vorhanden. |
| Formatter/Linter (stylua, luacheck) im CI | ✅ Erledigt — `.stylua.toml`, `.luacheckrc` und `.github/workflows/lint.yml` (`stylua --check` + `luacheck` auf Push/PR). Bestand einmalig durchformatiert; beide Linter laufen grün. |

### Testbarkeit

Kein automatisiertes Test-Framework (plenary/busted). `docs/dev/TEST.md` und
`docs/dev/TEST-Configuration.md` dienen als manuelle Verifikationsdateien. Bereits
in der letzten Session bewusst nicht durch ein neues Test-Framework ersetzt
("wenn sinnvoll" / "state of the art"-Klausel) — bleibt so.

## Coding-Checkliste (relevante Punkte)

### A. Strings und Tabellen

Keine String-Verkettung in Schleifen gefunden (`highlighter.lua` nutzt
`string.format` nur für bedingte Debug-Meldungen). Keine Verstöße.

### B. Performance-Quickwins

| Regel | Status |
|---|---|
| Lokale Funktions-Refs in Hot-Loops | ✅ (`local api = vim.api` etc. als Modul-Header) |
| Async statt Blocken | ✅ Debouncing vorhanden; kein blockierendes I/O im Plugin |
| Memoization | ✅ `cache_manager.lua` |

### C. Neovim-API sicher verwenden

| Regel | Status |
|---|---|
| Handle-Validierung vor jedem `nvim_buf_*`/`nvim_win_*` | ✅ Erfüllt |
| Deferred Calls erneut validieren | Nicht anwendbar — Plugin nutzt keine `vim.defer_fn` mit Buffer-Handles |

### D. State- und Datenmodelle

Getter/Setter statt Direktzugriff bereits durchgängig (`config.get()`,
`cache_manager.get()`, `debounce_manager.get_config()`).

### F. Lazy-Loading

Bereits umgesetzt (`ft = 'markdown'`, bedingtes Laden von `debug/`).

## Architektur-Checkliste

| Aspekt | Status |
|---|---|
| Schichten/Module klar, Kopplung niedrig | ✅ Erfüllt |
| Abhängigkeiten explizit via Parameter | ✅ Erfüllt (kein verstecktes Rückgreifen auf globalen State) |
| Erweiterbarkeit (Registries/Factories) | ✅ Sinngemäß erfüllt (Verzeichnis-basiertes Laden von `languages/`, `groups/`, `schemes/`) |

## Anti-Pattern-Check

| Muster | Gefunden? |
|---|---|
| Globaler State | Nein |
| API ohne Guards | Nein |
| String-Concat im Loop | Nein |
| Closures im Loop | Nein (Callbacks werden einmalig bei Setup gebunden, nicht pro Iteration neu erzeugt) |

## Import- und Dateistruktur-Check

| Punkt | Status |
|---|---|
| Import-Reihenfolge | ✅ Erfüllt |
| Datei-Header | ✅ Erfüllt |
| Projektweiter `@types`-Ordner | 🟡 Nur root-level `@types.lua` + `debug/@types.lua` — für die Codegröße ausreichend, siehe [Arch&Coding.md](Arch&Coding.md) |

## Performance-Spickzettel

Die meisten Punkte (Debounced Writes, Async via uv, Weak-Caches) sind für dieses
Plugin nicht in voller Schärfe relevant, da kein Hochfrequenz-I/O stattfindet.
Der zuvor offene Hot-Path-Punkt (Mehrfach-API-Zugriffe in `highlighter.lua`) ist
erledigt — `line_content` wird jetzt durchgereicht statt pro Zeichen neu geholt.

## Ausgelassene Abschnitte (nicht anwendbar)

- Funktionales Programmieren / Filter-Sinks-Pumps (Datei-, Netzwerk-, Streamverarbeitung)
- UI-State-Management (kein eigenes Fenster-/UI-State-Modul vorhanden)
- Garbage-Collector-Steuerung (keine großen Objektmengen, die manuelles GC-Tuning rechtfertigen)
- Sortieralgorithmen (kein eigener Sortierbedarf über `table.sort` hinaus)
- Einfüge-/Lösch-/Such-Datenstrukturen (Bäume, Skip-Lists, Tries, Hash-Tabellen-Interna, Union-Find, Segment-Bäume, Sequenzstrukturen)
- Zeit-/Platzkomplexitätsnotation (rein akademisch für dieses Projekt)
- Bitoperationen (kein Bit-Twiddling im Code)
- C/C++/FFI-Abschnitt (reines Lua-Plugin)
