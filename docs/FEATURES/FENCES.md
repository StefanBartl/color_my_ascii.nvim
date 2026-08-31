# Fences

Everything about the fenced block itself: visual boundaries around it,
navigation, validation, a public API other plugins can build on, and the
`:Fence` literate-programming toolkit for the block under the cursor.

## Fence-line highlighting

Paints the **whole** opening (`` ```lang ``) and closing (`` ``` ``) line of
fenced code blocks as a visual boundary — on by default, with
`preset = "auto"` matching the current colorscheme (falling back to
`subtle` on an unrecognized theme). Other presets: `subtle` (links
`CursorLine`), `accent` (links `Visual`), `underline`, `bar` (links
`ColorColumn`), or a named theme. `apply_to` scopes it to `"all"` fenced
blocks or `"ascii"` only. `open`/`close` accept a full override (highlight
group name or attribute table). See [COLORSCHEMES.md](COLORSCHEMES.md) for
the bundled theme-matched palettes.

The fill is a `line_hl_group` extmark, so every cell shares the fence
background (backticks, language tag, code, blank rows). For an indented
block, `respect_indent` (default `true`) carves that into a rectangle:
it starts at the block's own indent column — the opening fence's first
backtick — on every row (closing fence and blank interior lines included)
rather than at column 0, and holds `right_pad` columns (default `1`) off
the window's right edge. `right_pad` is recomputed on window resize; `0`
runs flush to the edge. `respect_indent = false` restores the plain
full-line paint from column 0.

- **Config:** `opts.fence_line_highlight`

## Fence-content highlighting

Paints the fenced block's **interior** — every line between the delimiters,
including trailing whitespace and blank lines, not just where characters
are. Starts at the block's indent column and holds `right_pad` off the
window edge by default (`respect_indent` / `right_pad`, as above);
`respect_indent = false` paints from column 0. On by default,
independent of fence-line highlighting; by
default shades the *resolved* fence-line color darker or lighter
(`shade = "auto"`, `amount` 0-100) so the interior reads as a related but
distinguishable tint. `hl` bypasses shading with a direct override.

- **Config:** `opts.fence_content_highlight`

## Fence-jump (`%`-style navigation)

`:ColorMyAscii fence-jump` jumps from a fence's opening delimiter line to its
closing one and back — the same mental model Neovim's built-in `%` applies to
`()`/`{}`/`[]` pairs, extended to fenced blocks. Falls back to the built-in
`%` when the cursor isn't on a delimiter line, so binding it directly to `%`
only adds behavior, never removes it. Works with any fence color_my_ascii
detects (heuristic or treesitter), not just ASCII-tagged ones.

- **Module:** `fence_jump.lua` (`M.percent`)
- **Usercmds:** [../BINDINGS.md#user-commands](../BINDINGS.md#user-commands)
- **Keymaps:** [../BINDINGS.md#keymaps](../BINDINGS.md#keymaps) (`fence_jump`, suggested lhs `%`)

## Fence validation & spacing

`:ColorMyAscii check-fences` scans the buffer for unmatched fenced code
blocks (unclosed fences, mismatched fence length) and reports them.
`:ColorMyAscii ensure-blank-lines` inserts a blank line before/after every
fenced block where one is missing, a common Markdown-linting requirement.

- **Module:** `commands/fence_check.lua`, `commands/format.lua`
- **Usercmds:** [../BINDINGS.md#user-commands](../BINDINGS.md#user-commands)

## Fence API (for plugin authors)

Public, robust, CommonMark-compatible fenced-block detection other plugins
can consume instead of reimplementing fence parsing — `markdown.nvim` uses
this to scope a `` ```markdown `` block as its own document. `list_blocks`
returns every block in document order (open/close rows, content range,
language, fence character/length, `is_ascii`); `block_at` finds the
innermost block containing a given row. Range-only queries are cached per
buffer `changedtick`, so `block_at` is cheap to call on every keystroke.

- **Module:** `api/fences.lua` (`list_blocks`, `block_at`, `is_markdown_lang`)
- **Usage:** `require('color_my_ascii').fences` — available without calling `setup()`

## Highlight read-back API (for plugin authors)

The applied highlighting, handed out **as data**, so another plugin can
reproduce the buffer's look in its own medium. The coloring lives in extmarks
and therefore exists only inside the buffer; this is how it gets out.
`runs_for_block` returns a block's painted spans, one array of runs per content
row (concatenating a row's run texts reproduces it byte for byte);
`attrs_for_group` resolves a highlight group to `#rrggbb` plus style flags,
following `link=` chains, leaving unset attributes nil.

**A block this plugin has not painted reports no groups at all** — the honest
answer, and the consumer's cue to fall back to whatever it would otherwise have
done. Not an edge case: `fence_language_map` covers 31 language tags.

First consumer: [mdview.nvim](https://github.com/StefanBartl/mdview.nvim)'s
`browser.highlighter = "nvim"`, which paints its browser preview with exactly
what the buffer next to it shows and hands the rest to highlight.js.

- **Module:** `api/highlight.lua` (`runs_for_block`, `attrs_for_group`), built on `highlight_export.lua`
- **Usage:** `require('color_my_ascii').highlight` — available without calling `setup()`
- **Docs:** [api.md](../api.md#highlight-read-back-api-for-plugin-authors)

## Fence export & yank

`:Fence export [path] [--open] [--replace]` extracts the block under the
cursor into a standalone file — omit the path for a prompt with a suggested
filename (extension derived from the fence language) and file completion.
`--replace` swaps the block for a link reference (a literate tangle).
`:Fence yank [reg]` copies the block content (markers stripped) to a
register, default `"` and `+`.

- **Module:** `commands/fence/export.lua`, `commands/fence/yank.lua`
- **Usercmds:** [../BINDINGS.md#user-commands](../BINDINGS.md#user-commands)
- **Keymaps:** `fence_yank`, `fence_export` (added 2026-08-24 — it was the
  one `Fence` subcommand with no entry in the keymap ACTIONS table, closing
  the flag/option audit's entry. The mapping runs the bare `:Fence export`,
  i.e. the prompt-for-a-path form, which is what every other entry in that
  table does with its own optional arguments.)

## Highlight export & copy — HTML & ANSI

- **Tab:** true
- **Module:** [`highlight_export.lua`](../../lua/color_my_ascii/highlight_export.lua)
- **Usercmds:** `:Fence export --html [path]`, `:Fence yank [reg] --ansi`

`:Fence export --html [path]` and `:Fence yank [reg] --ansi` export or copy a
fenced block with its *applied* color_my_ascii highlighting, not just plain
text — the same colors that are on screen, reconstructed as a portable
format.

### Why this exists

The plain `:Fence export`/`yank` above only ever produced text — the color
that made an ASCII diagram worth looking at in the first place was lost the
moment it left the buffer. `highlight_export.lua` closes that gap by
re-reading the block's already-painted `ColorMyAscii`-namespace extmarks and
reconstructing the same colors as either format, rather than recomputing
highlighting from scratch — what gets exported is exactly what is currently
on screen, overlaps and all.

### The two formats

- **HTML** (`--html`): `<span class="cma-<Group>">` runs plus a stylesheet
  covering only the highlight groups the block actually uses (not every
  group the plugin knows about). `--html`'s suggested filename always gets a
  `.html` extension, regardless of the fence's own language tag.
- **ANSI** (`--ansi`): 24-bit truecolor escape codes, paste-ready for a
  terminal or any chat client that renders ANSI. Works with any `:Fence
  yank` register argument.

Unhighlighted text passes through unstyled in both formats.

- **Module:** `highlight_export.lua`
- **Commit:** `624c988`
- **Tests:** `TESTS/highlight_export_spec.lua`, plus `--html`/`--ansi` coverage in `TESTS/fence_export_spec.lua` / `TESTS/fence_actions_spec.lua`

## Fence open (otter-lite editing)

`:Fence open [--split|--vsplit|--tab|--edit]` writes the block to a temp file
with the right extension and opens it in a real split, so LSP/formatters
attach normally — the fence interior stays anchored via extmarks, and `:w`
in the split syncs the edited content back into the fence.

- **Module:** `commands/fence/init.lua`
- **Keymaps:** `fence_open`

## Fence run & format

`:Fence run` runs the block with its language's interpreter and shows output
in a scratch split (`fence_run.runners`, merged on top of built-ins like
`python3`/`node`/`lua`/`bash`/`ruby`/`go run`). `:Fence format` formats the
block in place with the language's formatter (`fence_format.formatters`,
merged on top of `stylua`/`black`/`prettier`/`gofmt`/`shfmt`/`rustfmt`).

- **Config:** `opts.fence_run.runners`, `opts.fence_format.formatters`
- **Keymaps:** `fence_run`, `fence_format`

## Fence editing utilities

`:Fence import <file>` replaces the block content with a file's content (the
inverse of export). `:Fence lang <language>` changes the fence's language
tag. `:Fence select` visually selects the block interior.
`:'<,'>Fence wrap [lang]` wraps the current line or visual range in a fence;
`:Fence unwrap` removes the fence around the block under the cursor.

- **Module:** `commands/fence/init.lua`
- **Keymaps:** `fence_select`, `fence_wrap`, `fence_unwrap`

## Box-drawing edge alignment

- **Tab:** true
- **Module:** [`box_align.lua`](../../lua/color_my_ascii/box_align.lua), command in [`commands/fence/align.lua`](../../lua/color_my_ascii/commands/fence/align.lua)
- **Usercmds:** `:Fence align`

`:Fence align` straightens a box-drawing box under the cursor whose right
edge has drifted after hand-editing — content added or removed inside a
`┌─┐`/`│.../└─┘` box commonly leaves its right edge out of alignment, and
fixing that by hand means re-counting columns on every row.

### How it works

Detects simple 4-sided boxes (a corner + horizontal run + corner on the top
and bottom border, a vertical-edge interior in between — light, heavy, or
rounded Unicode box-drawing, or ASCII `+-|`) and widens every row to the
box's own widest row. Content is only ever **padded, never cut off**; a
missing right edge on an interior row is added rather than treated as "not a
box". Column math counts UTF-8 codepoints, not full display width — a
genuinely double-width character (CJK, emoji) inside a box can still throw
off visual alignment, a documented limitation rather than a bug.

### Deliberately narrow scope

Only a box's own width is touched — confirmed with the user before building.
Directory-tree connectors (`├──`/`└──` indentation) and anything that isn't
a clean rectangle are left completely untouched: verified against both a
real directory tree and a malformed stacked-box case (a `├────┤` divider
line breaks box detection entirely, by design, since junction glyphs aren't
corners). A broader "generic fence/buffer/cwd repair command" was explicitly
out of scope for this pass.

`:Fence align` is a normal buffer edit — `u` undoes it like any other change,
no confirmation prompt, same convention as `:Fence wrap`/`unwrap`/
`:ColorMyAscii ensure-blank-lines`.

- **Module:** `box_align.lua`, `commands/fence/align.lua`
- **Commit:** `6f5d6b3`
- **Keymaps:** `fence_align`
- **Tests:** `TESTS/box_align_spec.lua` (algorithm, incl. adversarial cases), plus wiring coverage in `TESTS/fence_actions_spec.lua`

## Syntax highlighting inside fences

A `` ```javascript `` block also gets Neovim's native treesitter injection
highlighting (`:TSInstall javascript` + `nvim-treesitter` highlight) on top
of color_my_ascii's own overlay for languages it recognizes — see
[HIGHLIGHTING.md#treesitter-syntax-overlay](HIGHLIGHTING.md#treesitter-syntax-overlay).
Full LSP inside fences (completion/hover/diagnostics) is not built.

- **Config:** `treesitter.syntax_highlight` (default `true`, only applies when `treesitter.enabled`)
- **Docs:** [HIGHLIGHTING.md#treesitter-syntax-overlay](HIGHLIGHTING.md#treesitter-syntax-overlay)

## Right-click context menu

`color_my_ascii.integrations.menu` contributes entries — Toggle
highlighting, Switch color scheme, Highlight info, and the `:Fence`
toolkit (Yank/Open/Run/Format/Align/Unwrap/Wrap) — in the shape
[nvzone/menu](https://github.com/nvzone/menu) expects, in markdown buffers
only (where `:ColorMyAscii`/`:Fence` are themselves active). The `:Fence *`
entries beyond `wrap` are further gated on the cursor actually being inside
a fenced block — the same check `commands.fence.util.current_block()` runs
before every `:Fence` subcommand — so right-click never offers a fence
action with nothing under the cursor to apply it to. `wrap` has no such
precondition (it *creates* a fence around the current line/range), so it
stays available everywhere in a markdown buffer. color_my_ascii.nvim has no
dependency on `menu` and never opens a context menu itself — a host
(typically your own `<RightMouse>` dispatcher) composes the entries into
its own menu.

- **Module:** `integrations/menu.lua` (`M.items`, `M.submenu`)
- **Config:** `opts.menu.enable` (default `true`)
