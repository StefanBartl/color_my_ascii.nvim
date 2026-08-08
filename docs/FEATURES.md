# Implemented Features Log

A running, detailed log of implemented roadmap items — one entry per feature,
with the files touched, the commit it landed in, and where it's documented.
Complements [ROADMAP.md](ROADMAP.md) (the terser public overview) with enough
detail to trace a feature back to its origin and rationale. Source items get
removed from the personal roadmap notes once logged here.

## Table of content

  - [Custom Language Definitions](#custom-language-definitions)
  - [Export/Copy with Highlighting](#exportcopy-with-highlighting)
  - [Hover Info for Characters](#hover-info-for-characters)
  - [Box-Drawing Edge Alignment](#box-drawing-edge-alignment)
  - [ASCII Blocks in Code Comments](#ascii-blocks-in-code-comments)

---

## Custom Language Definitions

**Commit:** `8de65be` — `feat(config): config.languages extension point for custom languages`

Previously, adding a language required a `languages/*.lua` file inside the
plugin itself — no way to extend it from `setup()`.

- `config.languages`: user-supplied language definitions (`{ words,
  unique_words?, hl }`, same shape as the built-in `languages/*.lua` files),
  merged into the built-in set at `setup()` time. A name reused from a
  built-in language (e.g. `lua`) replaces that language's entry wholesale
  (not a field-by-field deep merge — an earlier version of this got that
  wrong, splicing the user's `words` into the built-in array index-by-index
  instead of replacing it; caught by `TESTS/config_languages_spec.lua`).
  Malformed entries (missing `words`/`hl`) are skipped with a warning
  instead of breaking keyword-lookup construction for the rest.
- Hot-reload (lightweight version): calling `setup()` again with
  already-open, plugin-managed buffers now invalidates the stale per-buffer
  parse cache and re-highlights them immediately, so an added/edited
  language takes effect without touching the buffer or restarting Neovim.
  No automatic file-watching of an external language definition — that
  remains unbuilt (would be the higher-effort half of this item).

**Files:** `lua/color_my_ascii/config/init.lua` (`merge_user_languages`),
`lua/color_my_ascii/config/DEFAULTS.lua`, `lua/color_my_ascii/@types.lua`,
`lua/color_my_ascii/init.lua` (`M.setup` re-highlight loop).

**Docs:** [languages.md#custom-languages](languages.md#custom-languages),
[configuration.md#custom-languages](configuration.md#custom-languages),
`:h color_my_ascii-config-languages`.

**Tests:** `TESTS/config_languages_spec.lua`.

---

## Export/Copy with Highlighting

**Commit:** `624c988` — `feat(fence): export/copy a block's applied highlighting as HTML/ANSI`

`:Fence export` previously wrote a fenced block's content as a **plain**
file (a "literate tangle"); there was no way to export the block **with its
color_my_ascii highlighting**.

- New module `highlight_export.lua`: re-reads a block's already-painted
  `ColorMyAscii`-namespace extmarks and reconstructs the same colors as
  either HTML (`<span class="cma-<Group>">` runs + a stylesheet covering
  only the groups the block actually uses) or 24-bit truecolor ANSI escape
  codes. Unhighlighted text passes through unstyled in both formats.
- `:Fence export --html [path]` — writes a standalone HTML document instead
  of plain text (suggested filename gets a `.html` extension regardless of
  the fence language).
- `:Fence yank [register] --ansi` — copies the block to a register as
  ANSI-colored text instead of plain text; paste-ready for a terminal or a
  chat that renders ANSI.

**Files:** `lua/color_my_ascii/highlight_export.lua` (new),
`lua/color_my_ascii/commands/fence/export.lua`,
`lua/color_my_ascii/commands/fence/yank.lua`,
`lua/color_my_ascii/commands/fence/init.lua` (completion).

**Docs:** [commands.md#fence-actions--fence-buffer-local-markdown](commands.md#fence-actions--fence-buffer-local-markdown),
`docs/BINDINGS.md`, `:h color_my_ascii-highlight-export`.

**Tests:** `TESTS/highlight_export_spec.lua`, plus `--html`/`--ansi`
coverage added to `TESTS/fence_export_spec.lua` /
`TESTS/fence_actions_spec.lua`.

---

## Hover Info for Characters

**Commit:** `63ab446` — `feat(hover): :ColorMyAscii hover — highlight/group/keyword info at cursor`

"Which group / highlight is behind this character?" was previously only
answerable via `:ColorMyAscii inspect char <char>` (debug-mode only, prints
to `:messages`, requires typing the character as an argument).

- New module `hover.lua` combines two views for the character under the
  cursor: the live answer (the actual `hl_group` color_my_ascii's own
  extmarks painted at this exact position right now, with resolved fg/bg -
  covers overlaps between char/keyword/treesitter highlighting the same
  cell, whichever was painted last) and the config answer (which character
  groups it belongs to per config, override status - independent of
  whether anything is painted right now, e.g. cursor outside any ASCII
  block). Also reports keyword-language matches when the cursor sits on a
  recognized keyword.
- Displayed via `lib.nvim.ui.kit`'s `note` popup (`relative = "cursor"`)
  when installed, falling back to a plain `nvim_open_win` float
  (q/`<Esc>`/`<C-c>` to close) otherwise - same soft-dependency pattern
  `commands/fence/export.lua` already uses for `kit.confirm`/`kit.input`.
- The same info text is also copied to the unnamed register (+ system
  clipboard where available), for pasting into a bug report or a chat.
- Not debug-gated (unlike `inspect char`) - useful any time, not just with
  `debug_enabled = true`.
- Side fix while in the area: `:ColorMyAscii fence-jump` never got its own
  vimdoc command entry (only a keybindings-section mention) - added.

**Files:** `lua/color_my_ascii/commands/hover.lua` (new),
`lua/color_my_ascii/bindings/usrcmds.lua` (`hover` route),
`lua/color_my_ascii/bindings/keymaps.lua` (`hover` action).

**Docs:** [commands.md#core-commands](commands.md#core-commands),
`docs/BINDINGS.md`, `:h :ColorMyAscii-hover`.

**Tests:** `TESTS/hover_spec.lua`.

---

## Box-Drawing Edge Alignment

**Commit:** `6f5d6b3` — `feat(fence): :Fence align — straighten misaligned box-drawing edges`

Hand-editing an ASCII box (adding/removing text inside it) commonly drifts
its right edge out of alignment; fixing that by hand means re-counting
columns on every row.

- New module `box_align.lua`: detects simple 4-sided boxes (corner +
  horizontal + corner top/bottom, vertical-edge interior rows - light/
  heavy/rounded Unicode, or ASCII `+-|`) and widens each box to its own
  widest row. Content is only ever padded, never cut off; a missing right
  edge on an interior row is added rather than treated as "not a box".
  Column math counts UTF-8 codepoints (documented limitation: a genuinely
  double-width character - CJK, emoji - inside a box can still throw off
  visual alignment).
- Deliberately narrow v1 scope (confirmed with the user before building):
  only a box's own width is touched. Directory-tree connectors
  (`├──`/`└──` indentation depth) and anything that isn't a clean
  rectangle are left completely untouched - verified against both an
  actual directory tree and a malformed stacked-box case (a `├────┤`
  divider line breaks box detection entirely, by design, since junction
  glyphs aren't corners). A second roadmap bullet ("generic fence/buffer/
  cwd repair command applying several such rules") was explicitly out of
  scope for this pass.
- `:Fence align` - a normal buffer edit; `u` undoes it like any other
  change, no confirmation prompt needed (same convention as `:Fence wrap`/
  `unwrap`/`:ColorMyAscii ensure-blank-lines`).

**Files:** `lua/color_my_ascii/box_align.lua` (new),
`lua/color_my_ascii/commands/fence/align.lua` (new),
`lua/color_my_ascii/commands/fence/init.lua` (`align` subcommand),
`lua/color_my_ascii/bindings/keymaps.lua` (`fence_align` action).

**Docs:** [commands.md#fence-actions--fence-buffer-local-markdown](commands.md#fence-actions--fence-buffer-local-markdown),
`docs/BINDINGS.md`, vimdoc `:Fence align` entry.

**Tests:** `TESTS/box_align_spec.lua` (the algorithm, incl. adversarial
cases), plus wiring coverage in `TESTS/fence_actions_spec.lua`.

---

## ASCII Blocks in Code Comments

**Commit:** `947e274` — `feat(comment-ascii): ASCII blocks in code comments outside markdown`

The plugin previously activated only on `FileType markdown` and only
recognized ``` ``` ``` fences; there was no way to highlight an ASCII
diagram living in a Lua/Python/... source file's comments.

- New module `comment_ascii.lua`: detects `-- ascii` … `-- /ascii` marked
  blocks (comment prefix derived from the buffer's own `commentstring`,
  so it works for any language with a simple line-comment syntax - `--`,
  `#`, `//`, ...). Same open/close symmetry as a markdown fence tag
  (`ascii-<lang>` also supported for explicit language detection). Blocks
  are returned in the exact shape `parser.lua`'s markdown scanner uses, so
  the existing highlighter (character/keyword passes + the treesitter
  overlay) highlights them completely unchanged - no parallel highlighting
  logic needed.
- `config.comment_ascii = { enable, filetypes }` - **off by default**,
  unlike most other features, since enabling it activates the plugin on
  non-markdown filetypes. `parser.find_ascii_blocks`/`find_inline_codes`
  dispatch to `comment_ascii` for buffers whose filetype is in the
  configured list.
- `bindings/autocmds.lua` now registers a `FileType` autocmd for the
  configured filetypes, and is re-callable: `init.lua`'s `M.setup()` calls
  it again on every `setup()`, so a `comment_ascii.filetypes` list supplied
  by the user takes effect regardless of load order relative to the
  `plugin/` bootstrap's own (default-config-only) call to it.
- Explicitly scoped to **highlighting only**, confirmed before building:
  the `:Fence` toolkit and fence-line/fence-content background highlighting
  remain markdown-only. The roadmap item's other framing point
  ("README.org/.rst/.adoc support") was prose context, not an actual
  checkbox task, and wasn't built.

**Files:** `lua/color_my_ascii/comment_ascii.lua` (new),
`lua/color_my_ascii/parser.lua` (dispatch),
`lua/color_my_ascii/bindings/autocmds.lua` (FileType registration,
re-callable), `lua/color_my_ascii/init.lua` (re-calls `autocmds.enable()`),
`lua/color_my_ascii/config/DEFAULTS.lua`, `lua/color_my_ascii/@types.lua`.

**Docs:** [configuration.md#ascii-blocks-in-code-comments](configuration.md#ascii-blocks-in-code-comments),
`:h color_my_ascii-config-comment_ascii`.

**Tests:** `TESTS/comment_ascii_spec.lua` (the marker scanner, incl.
different comment syntaxes and unclosed-block handling), plus dispatch
coverage in the same file.
