# Features

color_my_ascii.nvim colors ASCII art in Markdown fenced code blocks (plus,
opt-in, in code comments outside markdown), with automatic language
detection, custom highlights, color schemes, and a small literate-programming
toolkit (`:Fence`) for the block under the cursor. This folder is grouped by
theme rather than kept as one flat file, since the plugin's surface has grown
past a single-page catalog:

- [HIGHLIGHTING.md](HIGHLIGHTING.md) — the core painting engine: block
  detection, character groups, function names, brackets, inline code, custom
  overrides, treesitter overlay, ASCII-in-comments.
- [LANGUAGES.md](LANGUAGES.md) — the 31 built-in languages, automatic
  detection, standard fence-tag support, and the `config.languages`
  extension point.
- [FENCES.md](FENCES.md) — everything about the fence itself: fence-line/
  fence-content highlighting, `%`-jump, validation, the two public APIs (fence
  detection, and reading the applied highlighting back out), and the full
  `:Fence` sub-command toolkit (export, yank, open, run, format, import, lang,
  select, wrap/unwrap, align).
- [COLORSCHEMES.md](COLORSCHEMES.md) — the 10 built-in color schemes and how
  to build your own.
- [TOOLS.md](TOOLS.md) — cursor-side introspection: hover, health check, and
  the debug-mode inspect/stats commands.

For a compact machine-readable table of every command, keymap, and
autocommand instead, see [../BINDINGS.md](../BINDINGS.md).

For long-form walkthroughs of single features — character groups, keywords,
function detection, brackets, inline code, custom colors and overrides — see
[../guides/](../guides/README.md). Those are the manuals this catalogue was
written from; they sit outside this folder because each is one feature
explained at length, not a theme.
