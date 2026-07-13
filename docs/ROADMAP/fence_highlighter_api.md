# Externe Highlighter-API für Fences

Status-Dokument (Deutsch), Schlachtplan. Frage: Können andere Neovim-Plugins,
externe Apps/Tools oder CLI-Tools das Highlighting **innerhalb** eines Fences
(Marker-Zeilen und/oder Inhalt) selbst übernehmen bzw. steuern? Wenn ja: wie.

---

## 1. Ausgangslage

Heute gibt es zwei Bausteine:

- **`color_my_ascii.api.fences`** ([lua/color_my_ascii/api/fences.lua](../../lua/color_my_ascii/api/fences.lua)):
  stabile, sprachagnostische Fence-Erkennung. `list_blocks`/`block_at` liefern
  `ColorMyAscii.FenceBlock`-Deskriptoren (Ranges, Sprache, `is_ascii`), gecacht
  per `(bufnr, changedtick)`. Bereits heute von markdown.nvim konsumiert.
- **`color_my_ascii.fence_hl`** ([lua/color_my_ascii/fence_hl.lua](../../lua/color_my_ascii/fence_hl.lua)):
  malt Marker-Zeilen (`fence_line_highlight`) und Block-Interior
  (`fence_content_highlight`) volflächig via `line_hl_group`-Extmarks in einer
  eigenen Namespace, mit fest verdrahteten Prioritäten (90 / 80, unter den
  Zeichen-Highlights bei 100+).

Beide sind heute **read-only nach außen**: andere können unsere Ranges lesen,
aber nicht in *unsere* Highlight-Passes eingreifen oder eigene Maler
registrieren.

---

## 2. Ist das grundsätzlich möglich?

**Innerhalb des Neovim-Prozesses (Lua-Plugins): ja, uneingeschränkt.**
Highlighting läuft über Extmarks/Highlight-Groups in eigenen Namespaces — jedes
Plugin, das unsere `list_blocks`/`block_at`-Ranges kennt, kann schon *heute* in
eigenen Extmarks auf denselben Zeilen malen (Namespaces sind additiv, keine
Kollisionsgefahr). Was fehlt, ist nicht *Machbarkeit*, sondern **Komfort und
ein Vertrag**: wann werden Blöcke neu erkannt, wo/mit welcher Priorität sollte
man malen, wie erfährt man von Änderungen ohne selbst zu pollen.

**Außerhalb des Neovim-Prozesses (externe Apps/CLI-Tools): eingeschränkt
möglich, mit einer wichtigen Einschränkung.** Highlighting ist ein reines
Neovim-UI-Konzept (Extmarks/Highlight-Groups existieren nur *in* einer
laufenden Instanz). Ein CLI-Tool ohne laufende Neovim-Instanz kann nichts
"highlighten" — es kann nur:
  a) **Daten liefern**, die *wir* dann interpretieren und selbst malen (z.B.
     eine Klassifikations-/Sprach-Zuordnung pro Fence), oder
  b) **eine laufende Neovim-Instanz fernsteuern** über deren eingebautes
     msgpack-RPC (`nvim --remote-expr`, `nvim --server ... --remote-expr
     "v:lua.require'color_my_ascii'.fences.list_blocks()"`, oder ein
     RPC-Client, der `nvim_exec_lua` aufruft) und darüber unsere Lua-API
     benutzt, so als wäre es selbst ein Neovim-Plugin.

Es gibt keinen sinnvollen dritten Weg (kein "highlighte diese Zeilen" ohne
Neovim-Instanz). **Fazit: möglich, aber (b) ist der einzig echte Weg für
"externe Tools" — und der ist bereits heute nutzbar, weil er nur Neovims
Bordmitteln + unserer bestehenden `M.fences`-API bedarf.** Der neue Teil ist
ausschließlich (a) — eine Erweiterung, die *Highlighting-Beiträge* statt nur
*Range-Lesezugriff* erlaubt.

---

## 3. Vorgeschlagene Architektur (phasiert)

### Phase 1 — `User`-Autocmd-Events (minimal-invasiv, günstig)

Vor/nach jedem `fence_hl.apply`- bzw. `highlighter.highlight_block`-Pass ein
`User`-Event feuern, mit Block-Daten in einem kleinen, dokumentierten
Tabellen-Feld (analog zu `vim.v.event`):

```lua
vim.api.nvim_exec_autocmds("User", {
  pattern = "ColorMyAsciiFenceBlock",
  data = { bufnr = bufnr, block = block }, -- block: ColorMyAscii.FenceBlock
})
```

Jedes andere Plugin kann sich darauf registrieren und in einer **eigenen**
Namespace zusätzlich malen — ohne dass wir dafür Code außer dem Event-Feuern
brauchen. Kosten: sehr gering (ein `pcall(nvim_exec_autocmds, ...)` pro Block
in der ohnehin laufenden Highlight-Pass). Kein Registrierungs-Overhead, keine
Prioritäts-Verwaltung nötig — Konsumenten benutzen einfach höhere/niedrigere
`priority`-Werte in ihren eigenen Extmarks.

**Empfehlung: das ist der erste Schritt, sobald ein konkreter Konsument
(z.B. markdown.nvim oder ein LSP-Adapter) das braucht.**

### Phase 2 — Registry-API (mehr Kontrolle, opt-in)

Falls Phase 1 nicht reicht (z.B. weil ein Konsument *unsere* Standard-Malerei
für einen Block unterdrücken oder priorisiert vor uns laufen lassen will):

```lua
-- color_my_ascii.api.fences
M.register_highlighter({
  name = "my-plugin",
  priority = 50,                         -- Reihenfolge relativ zu anderen Registrierten
  filter = function(block) ... end,       -- optional: welche Blöcke
  highlight = function(bufnr, block) ... end, -- malt selbst, eigene Namespace
})
M.unregister_highlighter("my-plugin")
M.list_highlighters()
```

Wir rufen registrierte Highlighter nach unseren eigenen Passes auf (oder,
mit einem `suppress_default = true`-Flag im Rückgabewert, *statt* unserer).
Das ist strikt mehr Aufwand als Phase 1 (Reihenfolge, Fehlerisolation via
`pcall`, Lifecycle bei Buffer-Delete) und lohnt sich nur mit echtem Bedarf.

**Empfehlung: nur bauen, wenn ein Plugin tatsächlich mehr braucht als das
Event aus Phase 1 bietet — sonst totes Gerüst wie das verworfene
`fence_syntax` in [lsp_integration_fence.md](lsp_integration_fence.md).**

### Phase 3 — Cross-Process-Zugriff (RPC)

Kein neuer Code nötig — nur Dokumentation, wie ein externes Tool eine
laufende Neovim-Instanz über `nvim --remote-expr` / msgpack-RPC anspricht, um
`require("color_my_ascii").fences.list_blocks(...)` (und ab Phase 1/2 auch
Highlighter-Registrierung) fernzusteuern. Das funktioniert bereits heute mit
Neovim-Bordmitteln, sobald `M.fences` stabil ist (ist es).

---

## 4. Offene Fragen

- **Versionierung:** Sollten `ColorMyAscii.FenceBlock`-Felder ein
  `schema_version` bekommen, damit externe Konsumenten sich gegen künftige
  Breaking Changes absichern können? Empfehlung: ja, spätestens mit Phase 1.
- **Fehlerisolation:** Ein fehlerhafter externer Highlighter darf niemals
  unsere eigene Highlight-Pass zum Absturz bringen — jeder Callback/Autocmd
  läuft in `pcall`.
- **Performance:** Externe Highlighter laufen auf ihrem eigenen Schedule;
  unser `debounce_manager` deckt nur unsere eigenen Passes ab. Bei Phase 1
  liegt das in der Verantwortung des Konsumenten (dokumentieren, nicht lösen).

---

## 5. Entscheidung

**Möglich — ja, mit der Einschränkung aus Abschnitt 2 (b).** Aktuell **kein
konkreter Konsument bekannt**, daher **vertagt**, aber startbereit: Phase 1
(`User ColorMyAsciiFenceBlock`) ist klein genug, um sie einzuführen, sobald ein
erstes Plugin (oder ein RPC-gesteuertes externes Tool) sie tatsächlich
braucht. Phase 2 nur bei nachgewiesenem Bedarf. Phase 3 ist bereits heute
nutzbar, ohne dass wir etwas bauen müssen.
