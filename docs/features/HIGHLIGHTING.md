# Highlighting

The core painting engine: how a fenced block gets found, what gets colored
inside it, and how that stays correct as the buffer and the colorscheme
change.

## Automatic ASCII block detection

Finds fenced code blocks in a Markdown buffer and decides which are ASCII
art, via a state-machine line scanner (backtick and tilde fences, explicit
`` ```ascii ``/`` ```ascii-<lang> `` markers, standard fence-tag matches, and
context-aware handling of empty fences as opening vs. closing). Optionally
backed by the markdown treesitter grammar instead of the heuristic scanner
for block detection itself (`treesitter.block_detection`), which is more
robust for nested fences and unusual indentation; falls back silently to the
heuristic scanner when no `markdown` parser is installed.

- **Module:** `parser.lua`, `parser_ts.lua` (`find_ascii_blocks`, `find_inline_codes`)
- **Config:** `opts.treesitter.block_detection` (default `true`), `opts.treat_empty_fence_as_ascii` (default `true`)

## Character groups

Five built-in groups of related characters that share one highlight style —
box-drawing (`─│┌┐└┘├┤┬┴┼...`), blocks (`█▓▒░▀▄▌▐...`), arrows
(`←→↑↓⇐⇒...`), symbols (`•★☆✓✔...`), operators (`+-*/%=<>!&|^~()[]{}...`).
Fully replaceable or extensible from `setup()`; the last-defined group wins
on character overlap, and per-character `overrides` win over any group.

- **Module:** `groups/*.lua` (`box_drawing`, `blocks`, `arrows`, `symbols`, `operators`)
- **Config:** `opts.groups`

## Function name detection

Heuristic highlighting of `identifier(` patterns (word characters, optional
whitespace, then `(`) as the `Function` highlight group — language-agnostic,
not syntax-aware. A name that is also a language keyword is highlighted as
the keyword instead, not double-highlighted as a function.

- **Config:** `opts.enable_function_names` (default `true`)

## Bracket highlighting

Highlights `()`, `[]`, `{}` with the `Operator` group when they aren't
already covered by a character group — a group's own definition always wins
if it already contains brackets, so enabling this on top of a custom
`operators` group that already has brackets is a no-op, not a conflict.

- **Config:** `opts.enable_bracket_highlighting` (default `true`)

## Inline code highlighting

Applies the same character/keyword/function-name highlighting rules inside
Markdown inline code spans (`` `...` ``) as inside fenced blocks. Unlike
fenced blocks, inline code has no language detection — the span is too short
for the heuristic to be reliable — so keywords from every loaded language are
checked at once. Escaped backticks, nested backticks, and spans across
multiple lines are not recognized.

- **Config:** `opts.enable_inline_code` (default `true`)

## Custom highlights & overrides

Any character can be pinned to an exact highlight, independent of whichever
group it would otherwise belong to — either a built-in highlight-group name
(theme-adaptive) or a full RGB/hex attribute table (`fg`, `bg`, `bold`,
`italic`, `underline`, `undercurl`, `strikethrough`). Priority, highest to
lowest: `overrides` → `groups` → `keywords` → `default_hl`.

- **Config:** `opts.overrides`, `opts.default_hl`, `opts.default_text_hl`

## Treesitter syntax overlay

On top of the character/keyword highlighting above, overlays a fenced
block's *actual* language grammar (real `@`-prefixed treesitter highlight
groups) for blocks whose language treesitter can parse — best-effort, since
ASCII art is usually not valid syntax, so this mostly affects blocks (or
portions of blocks) that happen to contain real code. Requires the
corresponding parser (`:TSInstall <language>`); silently does nothing where
one isn't installed. `:checkhealth color_my_ascii` reports which fence
languages in the current buffer are missing a parser.

- **Module:** `highlighter_ts.lua`
- **Config:** `opts.treesitter.syntax_highlight` (default `true`, requires `opts.treesitter.enabled`)

## ASCII blocks in code comments

Extends detection beyond markdown: explicitly-marked `-- ascii` … `-- /ascii`
blocks (comment prefix derived from the buffer's own `commentstring`, so it
works for `--`, `#`, `//`, ... alike) get the same character/keyword/
treesitter highlighting as a markdown fence, in whichever filetypes are
configured. **Off by default** — unlike most other features here, turning it
on activates the plugin on non-markdown filetypes. **Highlighting only**: the
`:Fence` toolkit and fence-line/fence-content background highlighting (see
[FENCES.md](FENCES.md)) remain markdown-only; only single-line comment syntax
is supported, not block comments (`/* ... */`).

- **Module:** `comment_ascii.lua`
- **Config:** `opts.comment_ascii.enable` (default `false`), `opts.comment_ascii.filetypes` (broad built-in list, see `config/DEFAULTS.lua`)

## Colorscheme-safe highlight re-application

color_my_ascii creates its own dynamically-computed (fixed-hex) highlight
groups for ASCII art; Neovim's implicit `:hi clear` on a `:colorscheme`
switch would otherwise silently wipe them. A `ColorScheme` autocommand
re-applies them (and separately re-resolves fence-line highlight groups)
right after every colorscheme change, so highlighting never goes stale after
switching themes.

- **Module:** `init.lua` (`ColorMyAsciiHl` / `ColorMyAsciiFenceLineHl` autocmd groups)
- **Autocmds:** [../BINDINGS.md#autocommands](../BINDINGS.md#autocommands)
