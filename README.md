> **Beta stage — active development.** This repository is past its first shape and in
> active use, but the surface is not frozen: breaking changes are still possible. Pin a
> commit or tag if you depend on it.

# color_my_ascii.nvim

```
    ╔══════════════════════════════════════════╗
    ║   c o l o r _ m y _ a s c i i . n v i m   ║
    ║   ┌─┐ → ★ ┌─┐   function() end   ┌─┐      ║
    ╚══════════════════════════════════════════╝
```

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Neovim](https://img.shields.io/badge/Neovim-0.10%2B-57A143?logo=neovim&logoColor=white)](https://neovim.io)
[![Lua](https://img.shields.io/badge/Lua-5.1%2FLuaJIT-2C2D72?logo=lua&logoColor=white)](https://www.lua.org)
![Status](https://img.shields.io/badge/status-beta-orange)

Colorful highlighting for ASCII art in Markdown code blocks, with automatic
language detection, custom highlights and predefined color schemes.

A fenced block full of box-drawing characters is, to every other tool, one
undifferentiated grey wall. This one reads it — and then gives you a small
literate-programming toolkit over the same blocks.

---

## Table of contents

- [Documentation](#documentation)
- [What it does](#what-it-does)
- [Around it](#around-it)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quickstart](#quickstart)
- [Integrations](#integrations)
- [Health check](#health-check)
- [Contributing](#contributing)
- [Feedback](#feedback)
- [License](#license)

---

## Documentation

[docs/README.md](./docs/README.md) names every page and the question it answers.
The ones people open first:

- [Quickstart](./docs/QUICKSTART.md) — getting started, first steps, and typical configurations.
- [Configuration](./docs/configuration.md) — full `setup()` reference, treesitter integration, fence-line and fence-content highlighting.
- [Commands](./docs/commands.md) — all user commands, the `:Fence` toolkit, and its configuration.
- [Supported languages](./docs/languages.md) — the 31 built-in languages and standard fence-tag support.
- [Fence API](./docs/api.md) — public APIs for plugin authors: fenced-block detection, and reading back the applied highlighting.
- [Color schemes](./docs/schemes.md) — built-in schemes and how to create your own.
- [Bindings cheatsheet](./docs/BINDINGS.md) — every command, keymap and autocommand in one table.
- [Features](./docs/FEATURES/README.md) — the full catalog, grouped by theme: highlighting, languages, fences, schemes, tools.
- [Troubleshooting](./docs/troubleshooting.md) — performance notes and common issues.
- [Contributing](./docs/contributing.md) — dev setup (stylua/luacheck/CI), adding a language or a character group.
- [Manual fixture](./TESTS/FIXTURE.md) — a Markdown file that exercises every feature by hand, with [FIXTURE-CONFIG.md](./TESTS/FIXTURE-CONFIG.md) to turn them all on.
- [Changelog](./docs/CHANGELOG.md) — version history.

`:help color_my_ascii` is the same reference inside the editor.

---

## What it does

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

---

## Around it

> **[markdown.nvim](https://github.com/StefanBartl/markdown.nvim)** — structures
> the document around the block (TOC, folding, tables); this one paints what is
> inside the block.
>
> **[mdview.nvim](https://github.com/StefanBartl/mdview.nvim)** — the one real
> consumer of the highlight read-back API: it repaints the same colors in a
> browser preview, so the rendered page and the buffer agree.
>
> Both are soft: without them everything else works unchanged.
> [lib.nvim](https://github.com/StefanBartl/lib.nvim) is the one real
> dependency — see [Requirements](#requirements).

---

## Requirements

| | |
| --- | --- |
| Neovim | **0.10+** |
| [lib.nvim](https://github.com/StefanBartl/lib.nvim) | required — the `:ColorMyAscii` and `:Fence` command trees are built on it |

Optional, each detected at runtime and degrading to nothing when absent:

| | |
| --- | --- |
| A Treesitter Markdown parser | Sharper fence detection than the line-scan fallback — see [configuration.md](./docs/configuration.md) |
| [nvzone/menu](https://github.com/nvzone/menu) | A host for the context-menu entries — see [Integrations](#integrations) |
| A formatter on `PATH` | `:Fence format` shells out to whatever the block's language declares |

---

## Installation

```lua
-- lazy.nvim
{
  "StefanBartl/color_my_ascii.nvim",
  ft = "markdown",
  dependencies = { "StefanBartl/lib.nvim" }, -- required
  opts = {},
}
```

`ft = "markdown"` rather than a blanket `event = "VeryLazy"`: there is nothing to
do until a Markdown file is actually open. `opts` is all that is needed — lazy
calls `setup()` with it; call `require("color_my_ascii").setup()` yourself only
if your plugin manager does not.

Other plugin managers, including packer, are in
[docs/QUICKSTART.md](./docs/QUICKSTART.md).

---

## Quickstart

Open a Markdown file and write a fenced block tagged `ascii`:

````markdown
```ascii
┌─────────────────────┐
│  Hello World!       │
└─────────────────────┘
```
````

The box-drawing characters are highlighted immediately — no command to run.

Then, with the cursor inside a block, the `:Fence` toolkit acts on it:

```vim
:Fence yank --ansi         " copy the block with its colors, for a terminal
:Fence export --html       " write it out as HTML, highlighting included
:Fence align               " straighten the box-drawing edges
:Fence open --vsplit       " edit it in a real split; :w syncs it back
:ColorMyAscii hover        " what group and color is this character
```

Verify your setup any time with:

```vim
:checkhealth color_my_ascii
```

`:ColorMyAscii check-fences` validates the fences in the current buffer.

---

## Integrations

### Context menu

`color_my_ascii.integrations.menu` contributes context-aware entries in the shape
[nvzone/menu](https://github.com/nvzone/menu) expects. color_my_ascii.nvim has
**no** dependency on `menu` and never opens a context menu itself; a host —
typically your own `<RightMouse>` dispatcher — composes these entries into its
own menu:

```lua
local items = require("color_my_ascii.integrations.menu").items()
-- prepend or append `items` to your own menu table, then menu.open(composed)
```

Entries appear in Markdown buffers only, mirroring where `:ColorMyAscii` and
`:Fence` are themselves active, and the `:Fence *` entries are further gated on
the cursor actually being inside a fenced block — so a right-click never offers a
fence action with nothing to apply it to. Opt out with `config.menu.enable`.

---

## Health check

```vim
:checkhealth color_my_ascii
```

Reports whether `lib.nvim` resolved, whether a Markdown Treesitter parser is
available, which color scheme is active, and whether the configured highlight
groups could be created. Common issues and the performance notes are in
[docs/troubleshooting.md](./docs/troubleshooting.md).

---

## Contributing

Clone the repository and either symlink it or add it to your runtime path.
[docs/contributing.md](./docs/contributing.md) has the dev setup (stylua,
luacheck, CI) and walks adding a new language or character group;
[TESTS/FIXTURE.md](./TESTS/FIXTURE.md) is the by-hand check that every feature
still renders.

Pull requests very welcome.

---

## Feedback

Your feedback is very welcome. Use the
[issue tracker](https://github.com/StefanBartl/color_my_ascii.nvim/issues) to
report bugs, suggest features or ask usage questions; anything more open-ended
fits a
[discussion](https://github.com/StefanBartl/color_my_ascii.nvim/discussions).

If you find this plugin useful, a ⭐ on GitHub supports its development.

---

## License

MIT — see [LICENSE](./LICENSE).
