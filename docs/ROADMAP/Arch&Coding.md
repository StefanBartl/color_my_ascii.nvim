# Architektur & Coding-Regeln — angewendet auf color_my_ascii.nvim

Destilliert aus `Arch&Coding-Regeln.md`. Enthält nur Regeln, die für dieses Plugin
(reiner Buffer-Highlighter ohne eigene Fenster/UI-Layer, ohne Netzwerk, ohne komplexe
Datenstrukturen) tatsächlich greifen. Abschnitte zu Metatables/OOP-Datenmodellen,
Micro-Benchmarks von `require`/`vim.fn`-Aliasing und generische CPU-Kostenreferenzen
wurden ausgelassen — sie bringen für die aktuelle Codegröße keinen Mehrwert.

## 1. Sicherheitsprinzipien & Fehlerbehandlung

| Regel | Status hier |
|---|---|
| `pcall()` bevorzugt | Gut abgedeckt in `init.lua`, `highlighter.lua`, `config/init.lua`, `bindings/*.lua`. Reine Datendateien (`languages/*`, `groups/*`, `schemes/*`) brauchen keine pcalls (keine Seiteneffekte). |
| Type Guards vor API-Zugriffen | Vorhanden (`type(...)`-Checks in `config/init.lua`s Loadern). |
| Kein `notify()` in Low-Level-Code | Größtenteils eingehalten. `parser.lua:97` und `debounce_manager.lua:134` notifien direkt aus internen Modulen (nur im Debug-Fall bzw. bei Fehlern) — vertretbar, aber ein zentraler `notify`-Wrapper (siehe `bindings/keymaps.lua`s lib.nvim-Fallback-Pattern) wäre konsistenter. **Kein akuter Handlungsbedarf.** |
| Explizite Rückgaben (`true/false, err`) | Eingehalten in `init.lua` (`M.setup`, `M.setup_buffer`, `M.highlight_buffer` geben alle `ok, err` zurück). |

## 2. Modularisierung & Strukturprinzipien

| Regel | Status hier |
|---|---|
| Modul = eine Verantwortung | Eingehalten: `parser.lua` (Parsing), `highlighter.lua` (Extmarks), `config/` (Konfiguration), `bindings/` (Registrierung), `cache_manager.lua`/`debounce_manager.lua` (Performance). |
| Lokale statt globale Funktionen | Eingehalten (`local function` für interne Helfer in allen Modulen). |
| Keine globalen States | Eingehalten: Zustand liegt in Modul-lokalen Tabellen (`state` in `init.lua`, `current_config` in `config/init.lua`), kein `_G.*`. |

## 3. Buffer-Management

Kein eigenes Window-Management vorhanden (das Plugin öffnet keine Floats/Splits) —
der Window-Teil dieser Checkliste ist nicht anwendbar.

| Regel | Status hier |
|---|---|
| Buffer-Validität prüfen | Zentralisiert in `utils/safe_api.lua` (`is_valid_buffer`), genutzt in `init.lua`, `cache_manager.lua`, `debounce_manager.lua`. Gut. |
| Cleanup bei Buffer-Delete | Vorhanden: `BufDelete`-Autocmd in `init.lua` räumt Highlighter/Cache/Debounce auf. |

## 5. Dokumentation & Annotationen

| Regel | Status hier |
|---|---|
| Datei-Header (`@module`, Beschreibung) | Durchgängig vorhanden. |
| `@param`/`@return` pro Funktion | Durchgängig vorhanden. |
| `@types`-Ordner pro Ebene | **Teilweise**: nur `lua/color_my_ascii/@types.lua` (root) und `lua/color_my_ascii/debug/@types.lua` existieren. `commands/`, `bindings/`, `groups/`, `languages/`, `schemes/`, `utils/` haben keine eigenen Types-Dateien. Für die Größe dieses Plugins ist das vertretbar — die meisten dieser Verzeichnisse brauchen keine über `@types.lua` (root) hinausgehenden Typen (Sprachdefinitionen/Gruppen sind bereits durch `ColorMyAscii.KeywordGroup`/`ColorMyAscii.CharGroup` abgedeckt). **Kein Handlungsbedarf**, um keine leeren Dateien nur pro forma anzulegen. |

## 8. Performance & Speicher

| Regel | Status hier |
|---|---|
| Debounced Updates | Vorhanden (`debounce_manager.lua`, adaptiv nach Dateigröße). |
| Caching | Vorhanden (`cache_manager.lua`, TTL + `changedtick`-Invalidierung). |
| Wiederholte API-Zugriffe im Hot-Path vermeiden | ✅ Erledigt: `highlighter.lua`s `highlight_range()` bekommt `line_content` vom Aufrufer durchgereicht (aus `block.lines`/`inline.content`), statt es pro Zeichen/Keyword/Funktionsname neu über die API zu holen. |
| Lokale Variablen für häufige Zugriffe | Eingehalten (`local api = vim.api`, `local notify = vim.notify` als Modul-Header-Aliase). |

## MISC — Cross-Plattform

Bereits geprüft (siehe vorherige Session/Commit `3b55573`): kein OS-spezifischer Code
gefunden, einziger Fund war ein Datei-Casing-Mismatch (`docs/changelog.md` vs.
`docs/CHANGELOG.md`), bereits behoben.

## NVIM-Config-spezifisch (`lib.nvim`)

| Punkt | Status hier |
|---|---|
| `lib.map` statt `vim.keymap.set` | Umgesetzt in `bindings/keymaps.lua` (mit Fallback). |
| `lib.notify` statt `vim.notify` | **Nicht umgesetzt** in den internen Modulen (`parser.lua`, `highlighter.lua`, `debounce_manager.lua`, `config/init.lua`). Bewusste Entscheidung aus der letzten Session: `lib.nvim` ist als "early/instabil" deklariert, ein Umbau performance-kritischer interner Module birgt mehr Risiko als Nutzen. Nur `bindings/*.lua` und `health.lua` nutzen es gezielt. |
| `lib.usercmd`/`lib.autocmd` | Nicht genutzt — die eingebauten `vim.api.nvim_create_user_command`/`nvim_create_autocmd` reichen für die wenigen, einfachen Registrierungen dieses Plugins; `lib.nvim`s pcall-Wrapping bringt hier keinen Mehrwert, der den harten Dependency-Zuwachs rechtfertigt. |
| `lib.cross`/Cross-Plattform-Fallback | Nicht nötig, da kein OS-spezifischer Code vorhanden ist. |
| `lib.lazy` / `lib.memo` | Nicht genutzt. `cache_manager.lua` implementiert bereits eigene TTL-Memoization, spezifisch auf Buffer-`changedtick` zugeschnitten — ein Umbau auf generisches `lib.memo` wäre eine Neuimplementierung ohne funktionalen Gewinn. |

## Annotations-Regeln — `#`-Kommentare in Aliasen

Aktuell nicht genutzt (`---@alias ColorMyAscii.SchemeName` in `@types.lua` nutzt
bereits `#`-Kommentare korrekt). Kein Handlungsbedarf.

## Importreihung

Stichprobe (`init.lua`, `highlighter.lua`, `config/init.lua`) zeigt bereits die
empfohlene Reihenfolge: Vim-API zuerst, dann Konfig-/Utility-Module. Kein
Handlungsbedarf.

## Nicht anwendbar (ausgelassen)

- Methoden/Metatables/Datenmodelle (Abschnitt 4) — keine komplexen Objektmodelle nötig
- Schwache Tabellen & Memoisierung (Abschnitt 10) — `cache_manager.lua`s TTL-Ansatz deckt den Bedarf bereits ab
- Spezialfälle (Abschnitt 11), Tables/Strings-Microbenchmarks, CPU-Kostenreferenz — rein akademisch, keine Hot-Loops in dieser Größenordnung im Plugin vorhanden
