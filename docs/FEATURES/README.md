# Features

color_my_ascii.nvim colors ASCII art in Markdown fenced code blocks (plus,
opt-in, in code comments outside markdown), with automatic language
detection, custom highlights, color schemes, and a small literate-programming
toolkit (`:Fence`) for the block under the cursor.

## At a glance

- **Automatic detection** of `ascii` code blocks in Markdown files.
- **31 predefined languages** (C, C++, C#, Lua, Go, Rust, TypeScript, JavaScript,
  Python, Bash, Zig, LLVM IR, Vimscript, Java, PHP, Ruby, Kotlin, Swift, Scala,
  Dart, Elixir, Haskell, Perl, R, Clojure, Groovy, PowerShell, SQL, JSON, HTML,
  CSS) — detected explicitly, via standard fence tags, by keyword heuristic, or
  falling back to the buffer filetype; plus your own via `config.languages`, no
  fork required.
- **Modular character groups and custom highlights** with full RGB/hex control,
  plus predefined color schemes (Matrix, Nord, Gruvbox, Dracula, and more).
- **Non-intrusive**: uses extmarks, never modifies the buffer.
- **Function name and bracket highlighting**, inline code highlighting, and
  configurable treatment of empty fenced blocks.
- **Fence-line and fence-content highlighting**: full-line/full-width highlight of
  fence delimiters and interiors, on by default and theme-matched.
- **Public fence API** (`require("color_my_ascii").fences`) so other plugins can
  reuse fenced-block detection instead of re-parsing it.
- **Public highlight read-back API** (`require("color_my_ascii").highlight`) — the
  applied colors as data, so another plugin can reproduce the buffer's look in
  its own medium. mdview.nvim paints its browser preview with it.
- **`:Fence` actions** — a literate-programming toolkit for the block under the
  cursor: export (plain or HTML with its highlighting), yank (plain or
  ANSI-colored), open (edit-in-split with sync), run, format, import, change
  language, select, wrap/unwrap, align (straighten box-drawing edges).
- **ASCII blocks in code comments** (opt-in, `config.comment_ascii`): explicitly
  marked `-- ascii` … `-- /ascii` blocks get the same highlighting outside
  Markdown.
- **`:ColorMyAscii hover`** — highlight, group and keyword info for the character
  under the cursor, in a float.

This folder is grouped by theme rather than kept as one flat file, since the
plugin's surface has grown past a single-page catalog:

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
