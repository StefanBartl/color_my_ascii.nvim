# LSP and syntax integration inside fenced blocks

A status document. It describes what already exists for highlighting
**inside code fences**, and sketches the two roads to **full LSP support**
(completion/hover/diagnostics) within a fence.

---

## 1. Where things stand

A markdown file contains code fences with a language, e.g.:

````markdown
```javascript
let a = 0;
console.log(a);
```
````

The goal: the code **inside** the fence should be treated as if it were real
JavaScript code — syntax highlighting at minimum, ideally full LSP features
(completion, hover, diagnostics, go-to-definition …).

---

## 2. Highlighting — what already works today

For highlighting we need to build **nothing new**; there are three
complementary mechanisms:

### 2a) Native treesitter injection (the actual road)

`tree-sitter-markdown` ships `injections.scm`. If the fence language's parser
is installed and highlighting is active, Neovim injects the language
automatically — `` ```javascript `` gets real JS highlighting, with no plugin
at all.

- Prerequisite: `nvim-treesitter` with `highlight.enable = true` **and** the
  respective parser (`:TSInstall javascript`).
- This is the recommended, "correct" solution for real code in fences.

### 2b) color_my_ascii's own grammar highlighting (for ASCII blocks)

color_my_ascii treats fences whose language is in `fence_language_map` (or
`` ```ascii-* ``) as ASCII blocks and colours them through
[`highlighter_ts.lua`](../../lua/color_my_ascii/highlighter_ts.lua)
**additionally** with the real target grammar (pass 5 in
`highlighter.highlight_block`), provided `treesitter.syntax_highlight = true`
(the default). That already gives most common languages (`js`, `python`,
`lua`, …) a grammar layer on top of the ASCII heuristic.

### 2c) Health check (diagnosis)

`:checkhealth color_my_ascii` lists the fence languages occurring in the
current buffer and reports which of them have **no** treesitter parser
installed — that is the most common reason a `` ```lang `` block is *not*
highlighted. The fix in each case is `:TSInstall <lang>`.

> **Discarded:** a generic "highlight all fences by grammar" switch
> (`fence_syntax`) was evaluated and removed again: the intersection of "not
> already covered by the ASCII path" and "has a parser in the LANGUAGE_MAP"
> is empty — the feature would have been dead, redundant code.
> 2a + 2b cover highlighting completely.

**Conclusion on highlighting:** done via 2a/2b; our contribution is the
health check (2c) plus documentation. For real code in fences, native
injection (2a) is the right road.

---

## 3. Full LSP in the fence — the real expansion stage

This is the large, still-open chunk. One **cannot** point a real language
server directly at a line range of a markdown file. What is needed is the
classic **"embedded / injected language LSP"** architecture:

1. **Hidden proxy buffers** per embedded language, into which the fence
   content is mirrored (with the correct filetype, so that e.g. `ts_ls`/
   `pyright` attach).
2. **Synchronisation** of markdown buffer ↔ proxy buffer on every change.
3. **Position remapping** in both directions (cursor/range in the MD buffer ↔
   line in the proxy buffer) for every LSP request/response.
4. **Request proxying**: pass `hover`, `completion`, `definition`,
   `references`, `diagnostics`, `rename` and `formatting` through and map the
   results back (diagnostics as extmarks/virtual text on the right MD line).
5. Merging several blocks of the same language.

There are two realistic roads to that:

### Option A — integrating otter.nvim (recommended)

[otter.nvim](https://github.com/jmbuhr/otter.nvim) is built for exactly this
(it is the engine behind quarto-nvim) and already implements points 1–5
robustly.

- **Effort:** low. Optionally a thin adapter that hands otter our fence ranges
  (`require("color_my_ascii").fences.list_blocks`), or calls
  `otter.activate()` for the active languages.
- **Advantage:** full LSP features immediately, and proven.
- **Disadvantage:** a third-party dependency; otherwise otter finds regions
  through TS injections. Our added value: `list_blocks` delivers
  `(lang, range)` **even without** a configured TS injection → it works in
  more setups.

### Option B — our own embedded LSP engine (self-contained)

Build points 1–5 ourselves, on top of our fence API.

- **Effort:** very high (several weeks for a robust version) — at its core a
  reimplementation of otter.
- **Advantage:** no third-party dependency; uses our robust fence detection
  (heuristic plus treesitter) as the region source, even without TS
  injections.
- **Recommended approach, if chosen:** keep the MVP small —
  **one** language, only `diagnostics` + `hover` + `completion`, as a module
  `color_my_ascii.embedded` on top of the fence API. Further
  requests/languages only after that.

### Decision

Currently **deferred**. Recommendation: evaluate option A (an otter adapter)
first; option B only if being self-contained is deliberately wanted. In both
cases the place for it is where the fence API lives (currently
`color_my_ascii`).
