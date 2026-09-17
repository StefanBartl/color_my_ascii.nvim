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
language detection, custom highlights and predefined color schemes — a fenced
block full of box-drawing characters is, to every other tool, one
undifferentiated grey wall; this one reads it and gives you a small
literate-programming toolkit over the same blocks.

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
> dependency — see [Requirements](./docs/requirements.md).

---

## Documentation

Start at [docs/README.md](./docs/README.md) — what's where, and which question
each page answers.

**Getting started**

- [Requirements](./docs/requirements.md) — Neovim version, the required lib.nvim dependency, and what's optional.
- [Installation & Quickstart](./docs/QUICKSTART.md) — plugin managers, the first coloured block, and typical configurations.

**Reference**

- [Configuration](./docs/configuration.md) — full `setup()` reference, treesitter integration, fence-line and fence-content highlighting.
- [Commands](./docs/commands.md) — all user commands, the `:Fence` toolkit, and its configuration.
- [Supported languages](./docs/languages.md) — the 31 built-in languages and standard fence-tag support.
- [Fence API](./docs/api.md) — public APIs for plugin authors: fenced-block detection, and reading back the applied highlighting.
- [Color schemes](./docs/schemes.md) — built-in schemes and how to create your own.
- [Bindings cheatsheet](./docs/BINDINGS.md) — every command, keymap and autocommand in one table.

**The rest**

- [What you get](./docs/FEATURES/README.md) — the full capability catalog, grouped by theme: highlighting, languages, fences, schemes, tools.
- [Integrations](./docs/integrations.md) — the context-menu integration.
- [Troubleshooting](./docs/troubleshooting.md) — what `:checkhealth` reports, performance notes, and common issues.
- [Contributing](./docs/CONTRIBUTING.md) — dev setup (stylua/luacheck/CI), adding a language or a character group.
- [Tests](./TESTS/README.md) — how to run the headless suite, what it covers, and the behaviour currently pinned as a known bug.
- [Manual fixture](./TESTS/FIXTURE.md) — a Markdown file that exercises every feature by hand, with [FIXTURE-CONFIG.md](./TESTS/FIXTURE-CONFIG.md) to turn them all on.
- [Changelog](./docs/CHANGELOG.md) — version history.
- Feedback — the [issue tracker](https://github.com/StefanBartl/color_my_ascii.nvim/issues) for bugs, features and usage questions; [discussions](https://github.com/StefanBartl/color_my_ascii.nvim/discussions) for anything more open-ended.

`:help color_my_ascii` is the same reference inside the editor.

---

## License

MIT — see [LICENSE](./LICENSE).
