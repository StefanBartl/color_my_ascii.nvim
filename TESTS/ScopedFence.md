# Was du live testen solltest

**Setup:** Neovim neu starten (lazy lädt `color_my_ascii` jetzt als Dependency von markdown.nvim). Prüfen: `:checkhealth markdown_nvim` → sollte `fenced_scope: enabled … provider: color_my_ascii fence API` zeigen. Und `:checkhealth color_my_ascii` → Fence-API + Fence-line-Highlight-Status.

Test-Dokument (äußerer Fence 4 Backticks, damit der innere 3er sauber verschachtelt):

````markdown
Doc Title
## Section A

````markdown
Inner Title
## Inner A
## Inner B
````

## Section B
````

**1. TOC-Scope** (`<leader>toc`)
- Cursor **in** den Fence setzen → TOC wird **im Block** eingefügt, listet nur `Inner A`/`Inner B`.
- Cursor **außerhalb** → äußerer TOC listet `Section A`/`Section B`, **nicht** die Inner-Headings.

**2. Heading-Navigation** (`<C-f>`/`<C-p>`, auch `[[`/`]]`)
- Im Block: springt nur zwischen Inner-Headings, **verlässt den Block nicht**.
- Außerhalb (z.B. auf `## Section A`): `<C-f>` **überspringt** den Fence und landet auf `## Section B`.
- Mit Count: `2<C-f>` / `4<C-p>` (nächstes/voriges Level-2/4-Heading) — im Block block-relativ.

**3. Anchor-Jump** (`mj`) — Cursor auf einen `[text](#inner-a)`-Link im Block → springt zum Inner-Heading.

**4. Shift-all** (`<S-Right>`/`<S-Left>`) — Cursor im Block → verschiebt **nur** die Block-Headings (äußere bleiben). *(Genau das hast du an der ROADMAP-Datei schon gesehen.)*

**5. Toggle**
- `:Markdown scope off` → alles fällt aufs alte Verhalten zurück (Nav läuft dann *in* Fences hinein). `:Markdown scope on` / `toggle` / `status`.

**6. Fold-Scope** (opt-in) — in der Config `fenced_scope.operations.fold = true` setzen; dann faltet ein `# comment` in einem ```python-Block **nicht** mehr (vorher schon: Bug).

**7. Fence-Line-Highlight** (color_my_ascii) — in der `color_my_ascii`-`opts`:
```lua
fence_line_highlight = { enable = true, preset = "accent", apply_to = "all" }
```
→ Öffnungs- und Schlusszeile jedes Fences (auch ` ```javascript `) werden ganzflächig gehighlightet. Presets `subtle`/`accent`/`underline`/`bar` durchprobieren; `open`/`close` mit eigener HL-Gruppe oder `{ fg=…, bg=… }` überschreiben.

Wenn beim Live-Test etwas hakt (v.a. TOC-Einfügeposition im Block oder Nav-Grenzen bei verschachtelten Fences), sag Bescheid — das sind die wahrscheinlichsten Kandidaten für Feinschliff.
