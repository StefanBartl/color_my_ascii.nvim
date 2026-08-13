# Workflow

How `color_my_ascii.nvim`'s pieces combine in real, daily use — a
literate-programming-ish loop of writing ASCII art and diagrams inside
Markdown fenced code blocks, coloring them for readability, and occasionally
treating a block as real, runnable code. This complements
[docs/features/](features/README.md) (what each piece does) with how they
chain together and where the sharp edges are.

## The core loop: write, color, verify

1. Open (or start) a Markdown fence — three or four backticks/tildes,
   optionally tagged (`` ```ascii ``, `` ```ascii-go ``, or a plain
   `` ```go ``/`` ```python `` standard tag).
2. Type ASCII art, a diagram, or real code. Highlighting applies live as you
   type — character groups (box-drawing, blocks, arrows, symbols,
   operators), function-name detection, and (if a language was resolved)
   keyword coloring.
3. If the language wasn't explicit, `:ColorMyAscii hover` on any character
   tells you both what actually got painted right now and what the config
   *would* paint there — the fastest way to confirm detection did what you
   expected before you keep typing 40 more lines assuming it did.
4. `` %`` `` (or your bound `fence_jump` key) jumps between the fence's open
   and close delimiters — useful once a block is long enough that scrolling
   to check the closing fence is annoying.

## Fence-tag vs. `ascii-` prefix: two ways to get the same coloring

A block gets language-aware coloring two ways, and it's easy to reach for
the more verbose one out of habit:

- **Standard tag** — `` ```go ``, `` ```js ``, `` ```py `` — recognized
  automatically via `fence_language_map` for all 31 built-in languages
  (including common aliases: `sh`/`ts`/`rs`/`kt`/`cs`/`py`/`js`/`rb`/`pl`).
  Prefer this for anything that's *also* meant to render as normal code in
  other Markdown tooling (GitHub, a static site generator) — the tag stays
  meaningful outside color_my_ascii too.
- **`ascii-<lang>` prefix** — `` ```ascii-go `` — the explicit,
  unambiguous form. Reach for this specifically for a block that is ASCII
  art *containing* language-flavored keywords (a diagram with `if`/`else`
  labels, for instance) where you want language coloring without implying
  to other tooling that the block is real, runnable source.

Explicit markers (either form) always beat heuristic detection, which beats
the buffer filetype fallback — so an explicit tag is also the fix when
automatic detection guesses wrong on a short or ambiguous block (raise
`language_detection_threshold` instead only if you want to fix the class of
false positive globally, not just one block).

## Treesitter vs. heuristic: what actually decides block boundaries

Two independent treesitter opt-ins exist, and they answer different
questions — conflating them is the most common misunderstanding of this
plugin's config:

- **`treesitter.block_detection`** (default `true`) — *which lines are the
  fence*. Uses the `markdown` parser instead of the heuristic line-scanner
  for finding fence boundaries — more robust for nested fences and unusual
  indentation. Falls back silently to the heuristic scanner if no
  `markdown` parser is installed; nothing breaks, detection just gets less
  robust on edge cases.
- **`treesitter.syntax_highlight`** (default `true`, requires
  `treesitter.enabled`) — *what gets painted inside a recognized block, on
  top of color_my_ascii's own character/keyword highlighting*. Requires the
  fence's *own* language parser (`:TSInstall go` for a `` ```go `` block),
  not the `markdown` one — a missing language parser silently does nothing,
  it does not fall back to anything. `:checkhealth color_my_ascii` reports
  exactly which fence languages in the current buffer are missing a parser.

Net effect: with no treesitter parsers installed at all, the plugin still
works completely via the heuristic scanner and its own character/keyword
highlighting — treesitter is a quality upgrade on both fronts, never a hard
requirement. If a block's syntax highlighting looks wrong specifically
inside real code (not ASCII art), check the *language's* parser first
(`:TSInstall <lang>`), not `markdown`'s.

## The `:Fence` toolkit: picking the right subcommand

Every `:Fence <sub>` operates on the block under the cursor (or the current
Visual range, for `wrap`) — no argument for "which block," which keeps the
common case a two-word command. The subcommands split into three groups by
what they touch:

**Extract/inspect a block's content** (never mutates the fence):
- `:Fence yank [reg] [--ansi]` — copy content (default registers `"`/`+`);
  `--ansi` copies the *colored* content as 24-bit escape codes, paste-ready
  into a terminal or ANSI-rendering chat client.
- `:Fence export [path] [--open] [--replace] [--html]` — write content to a
  file; `--replace` swaps the block for a link reference (a literate
  tangle); `--html` exports the colored version as `<span>`-per-run HTML
  with a scoped stylesheet instead of plain text.
- `:Fence select` — visually select the block interior, when you want to
  operate on it with a normal Vim operator instead of a `:Fence` verb.

**Edit a block's content in place:**
- `:Fence open [--split|--vsplit|--tab|--edit]` — real file, real LSP/
  formatter attachment; `:w` syncs back into the fence via extmark anchors.
  Reach for this over hand-editing whenever you want completion/diagnostics
  while working on a block's *actual code* (not ASCII art, where a real LSP
  buys nothing).
- `:Fence run` — execute with the language's interpreter, output in a
  scratch split. Only meaningful for a block whose language resolved to
  something runnable — an ASCII diagram tagged `ascii-go` will "run" as
  broken Go, since `run` doesn't distinguish art from code, only language.
- `:Fence format` — format in place with the language's formatter.
- `:Fence import <file>` — inverse of `export`: replace content from a file.
- `:Fence align` — straighten a box-drawing box's right edge after
  hand-editing shifted it out of alignment. Normal buffer edit, `u` undoes
  it; scoped to actual rectangular boxes only (directory-tree connectors
  and non-rectangular shapes are deliberately left untouched).

**Change the fence itself, not its content:**
- `:Fence lang <language>` — retag the fence's language.
- `:'<,'>Fence wrap [lang]` / `:Fence unwrap` — add or remove the fence
  around a line/range.

## A realistic combo: capturing a diagram for a bug report

`:ColorMyAscii hover` on the character that looks wrong → confirm whether
color_my_ascii or the underlying keyword table is at fault (hover reports
group membership independent of what's currently painted) → `:Fence yank
--ansi` to grab the colored block exactly as seen on screen → paste into
whatever chat/issue tracker renders ANSI. `hover`'s own summary is *also*
copied to the register/clipboard automatically, so the two together give a
bug report both the visual evidence and the diagnostic text without manually
transcribing either.

## Custom languages: `config.languages` vs. editing a built-in file

Add or override a language entirely from `setup()` — no fork, no new file:

```lua
require('color_my_ascii').setup({
  languages = {
    mylang = { words = { "foo", "bar" }, unique_words = { "foo" }, hl = "Keyword" },
  },
})
```

A name that collides with a built-in (`lua`, `python`, …) **replaces that
language's entry wholesale**, not a field-by-field merge — if you only want
to add one keyword to the built-in Lua set, copy its `words` list into your
override rather than assuming the two get merged. There's no file-watcher
for external language definitions; re-running `setup()` is the entire
reload path, but it does re-highlight every already-open, plugin-managed
buffer immediately — no restart, no `:e!`.

## Colorschemes: switching without losing highlighting

color_my_ascii's highlight groups are dynamically computed, fixed-hex
groups — exactly what Neovim's implicit `:hi clear` on `:colorscheme`
wipes. A `ColorScheme` autocommand re-applies them right after every switch,
so changing colorschemes mid-session is safe by default; if you're building
a *custom* colorscheme preset (see
[COLORSCHEMES.md](features/COLORSCHEMES.md)) and see it vanish on a
`:colorscheme` reload during development, that autocommand not having fired
yet (a manual `:hi clear` outside a real `:colorscheme` command, for
instance) is the first thing to check, not a bug in the preset itself.

## Where this plugin stays out of your way

`comment_ascii` (highlighting ASCII art inside `-- ascii ... -- /ascii`
comment blocks in non-Markdown files) is **off by default** specifically
because it's the one feature that activates the plugin outside Markdown —
turning it on is an explicit, filetype-scoped opt-in
(`opts.comment_ascii.filetypes`), not a global behavior change. The `:Fence`
toolkit and fence-line/fence-content background highlighting remain
Markdown-only even with `comment_ascii` enabled — comments only ever get
character/keyword/treesitter highlighting, never the fence chrome.

## See also

- [docs/features/README.md](features/README.md) — the full feature catalog
  this workflow draws its combos from.
- [docs/BINDINGS.md](BINDINGS.md) — every command/keymap/autocommand in one
  compact table.
- [docs/FEATURES.md](FEATURES.md) — a separate, personal roadmap-to-commit
  changelog (not a feature catalog); useful for tracing a feature back to
  the commit it landed in, not for learning how to use it.
