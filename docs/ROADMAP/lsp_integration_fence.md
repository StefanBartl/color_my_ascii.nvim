# LSP- & Syntax-Integration in Fenced Blocks

Status-Dokument (Deutsch). Beschreibt, was für Highlighting **innerhalb von
Code-Fences** bereits existiert, und skizziert die zwei Wege zu **voller
LSP-Unterstützung** (Completion/Hover/Diagnostics) im Fence.

---

## 1. Ausgangslage

In einer Markdown-Datei stehen Code-Fences mit einer Sprache, z.B.:

````markdown
```javascript
let a = 0;
console.log(a);
```
````

Ziel: Der Code **im** Fence soll so behandelt werden, als wäre es echter
JavaScript-Code — mindestens Syntax-Highlighting, idealerweise volle LSP-Features
(Completion, Hover, Diagnostics, Go-to-Definition …).

---

## 2. Highlighting — was heute schon funktioniert

Für Highlighting brauchen wir **nichts Neues zu bauen**; es gibt drei sich
ergänzende Mechanismen:

### 2a) Native Treesitter-Injection (der eigentliche Weg)

`tree-sitter-markdown` liefert `injections.scm`. Ist der Parser der Fence-Sprache
installiert und Highlighting aktiv, injiziert Neovim die Sprache automatisch —
`` ```javascript `` bekommt echtes JS-Highlighting, ganz ohne Plugin.

- Voraussetzung: `nvim-treesitter` mit `highlight.enable = true` **und** der
  jeweilige Parser (`:TSInstall javascript`).
- Das ist die empfohlene, „richtige" Lösung für echten Code in Fences.

### 2b) color_my_ascii's eigenes Grammar-Highlighting (für ASCII-Blöcke)

color_my_ascii behandelt Fences, deren Sprache in `fence_language_map` steht (bzw.
`` ```ascii-* ``), als ASCII-Blöcke und färbt sie über
[`highlighter_ts.lua`](../../lua/color_my_ascii/highlighter_ts.lua) **zusätzlich**
mit der echten Ziel-Grammatik (Pass 5 in `highlighter.highlight_block`), sofern
`treesitter.syntax_highlight = true` (Default). Damit erhalten die meisten
gängigen Sprachen (`js`, `python`, `lua`, …) bereits eine Grammatik-Ebene über
der ASCII-Heuristik.

### 2c) Health-Check (Diagnose)

`:checkhealth color_my_ascii` listet die im aktuellen Buffer vorkommenden
Fence-Sprachen und meldet, für welche **kein** Treesitter-Parser installiert ist
— das ist der häufigste Grund, warum ein `` ```lang ``-Block *nicht* gehighlightet
wird. Fix jeweils `:TSInstall <lang>`.

> **Verworfen:** Ein generischer „highlighte alle Fences per Grammatik"-Schalter
> (`fence_syntax`) wurde evaluiert und wieder entfernt: Die Schnittmenge aus
> „nicht bereits vom ASCII-Pfad abgedeckt" und „hat einen Parser in der
> LANGUAGE_MAP" ist leer — das Feature wäre toter, redundanter Code gewesen.
> 2a + 2b decken Highlighting vollständig ab.

**Fazit Highlighting:** Erledigt über 2a/2b; unser Beitrag ist der Health-Check
(2c) + Doku. Für echten Code in Fences ist native Injection (2a) der richtige Weg.

---

## 3. Volle LSP im Fence — die eigentliche Ausbaustufe

Das ist der große, noch offene Brocken. Man kann einen echten Sprachserver
**nicht** direkt auf einen Zeilenbereich einer Markdown-Datei richten. Nötig ist
die klassische **„embedded / injected language LSP"**-Architektur:

1. **Versteckte Proxy-Buffer** pro eingebetteter Sprache, in die der
   Fence-Inhalt gespiegelt wird (korrekter Filetype, damit z.B. `ts_ls`/`pyright`
   attached).
2. **Synchronisation** Markdown-Buffer ↔ Proxy-Buffer bei jeder Änderung.
3. **Positions-Remapping** in beide Richtungen (Cursor/Range im MD-Buffer ↔
   Zeile im Proxy-Buffer) für jede LSP-Anfrage/Antwort.
4. **Request-Proxy**: `hover`, `completion`, `definition`, `references`,
   `diagnostics`, `rename`, `formatting` durchreichen und Ergebnisse zurückmappen
   (Diagnostics als Extmarks/virtual an die richtige MD-Zeile).
5. Mehrere Blöcke derselben Sprache zusammenführen.

Dafür gibt es zwei realistische Wege:

### Variante A — Integration von otter.nvim (empfohlen)

[otter.nvim](https://github.com/jmbuhr/otter.nvim) ist genau dafür gebaut (die
Engine hinter quarto-nvim) und implementiert Punkte 1–5 bereits robust.

- **Aufwand:** niedrig. Optional ein dünner Adapter, der otter unsere
  Fence-Ranges (`require("color_my_ascii").fences.list_blocks`) übergibt bzw.
  `otter.activate()` für die aktiven Sprachen aufruft.
- **Vorteil:** Volle LSP-Features sofort, bewährt.
- **Nachteil:** Fremd-Dependency; otter findet Regionen sonst über
  TS-Injections. Unser Mehrwert: `list_blocks` liefert `(lang, range)` **auch
  ohne** konfigurierte TS-Injection → funktioniert in mehr Setups.

### Variante B — Eigene Embedded-LSP-Engine (self-contained)

Punkte 1–5 selbst bauen, auf Basis unserer Fence-API.

- **Aufwand:** sehr hoch (mehrere Wochen für eine robuste Version) — im Kern eine
  Neuimplementierung von otter.
- **Vorteil:** keine Fremd-Dependency; nutzt unsere robuste Fence-Erkennung
  (heuristik + treesitter) als Regionsquelle, auch ohne TS-Injections.
- **Empfohlenes Vorgehen, falls gewählt:** MVP klein halten —
  **eine** Sprache, nur `diagnostics` + `hover` + `completion`, als Modul
  `color_my_ascii.embedded` über der Fence-API. Erst danach weitere
  Requests/Sprachen.

### Entscheidung

Aktuell **vertagt**. Empfehlung: zuerst Variante A (otter-Adapter) evaluieren;
Variante B nur, wenn bewusst self-contained gewünscht ist. Der Ort ist in beiden
Fällen dort, wo die Fence-API liegt (aktuell `color_my_ascii`).
