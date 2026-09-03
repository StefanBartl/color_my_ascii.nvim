> **Alpha stage — active development.** This repository is in its development phase — breaking changes are to be expected at any time. Pin a commit or tag if you depend on it.

# color_my_ascii.nvim

```
    ╔══════════════════════════════════════════╗
    ║   c o l o r _ m y _ a s c i i . n v i m   ║
    ║   ┌─┐ → ★ ┌─┐   function() end   ┌─┐      ║
    ╚══════════════════════════════════════════╝
```

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Neovim](https://img.shields.io/badge/Neovim-0.9%2B-57A143?logo=neovim&logoColor=white)](https://neovim.io)
[![Lua](https://img.shields.io/badge/Lua-5.1%2FLuaJIT-2C2D72?logo=lua&logoColor=white)](https://www.lua.org)
![Status](https://img.shields.io/badge/status-beta-orange)

> See also: [markdown.nvim](https://github.com/StefanBartl/markdown.nvim) - a companion
> plugin for working with Markdown files, pairs well with the ASCII highlighting here.

A Neovim plugin for colorful highlighting of ASCII art in Markdown code blocks with automatic language detection, custom highlights, and predefined color schemes.

## Table of Contents

- [Features](#features)
- [Quickstart](#quickstart)
- [Documentation](#documentation)
- [Credits](#credits)
- [See Also](#see-also)

## Features

- **Automatic Detection** of `ascii` code blocks in Markdown files
- **31 predefined languages** (C, C++, C#, Lua, Go, Rust, TypeScript, JavaScript, Python, Bash, Zig, LLVM IR, Vimscript, Java, PHP, Ruby, Kotlin, Swift, Scala, Dart, Elixir, Haskell, Perl, R, Clojure, Groovy, PowerShell, SQL, JSON, HTML, CSS), detected explicitly, via standard fence tags, by keyword heuristic, or falling back to buffer filetype — plus your own via `config.languages`, no fork required
- **Modular character groups and custom highlights** with full RGB/Hex control, plus predefined color schemes (Matrix, Nord, Gruvbox, Dracula, and more)
- **Non-intrusive**: uses extmarks, no buffer modification
- **Function name and bracket highlighting**, inline code highlighting, and configurable treatment of empty fenced blocks
- **Fence-line and fence-content highlighting**: full-line/full-width highlight of fence delimiters and interiors, on by default and theme-matched
- **Public Fence API** (`require("color_my_ascii").fences`) for other plugins to reuse fenced-block detection
- **Public highlight read-back API** (`require("color_my_ascii").highlight`) — the applied colors as data, so another plugin can reproduce the buffer's look in its own medium (mdview.nvim paints its browser preview with it)
- **`:Fence` actions**: a literate-programming toolkit for the block under the cursor — export (plain or HTML with its applied highlighting), yank (plain or ANSI-colored), open (edit-in-split + sync), run, format, import, change language, select, wrap/unwrap, align (straighten box-drawing edges)
- **ASCII blocks in code comments** (opt-in, `config.comment_ascii`): explicitly-marked `-- ascii` … `-- /ascii` blocks get the same highlighting outside markdown
- **`:ColorMyAscii hover`**: highlight/group/keyword info for the character under the cursor, in a float
- **Health check** (`:checkhealth color_my_ascii`) and fence validation (`:ColorMyAscii check-fences`)

---

## Quickstart

**Loading strategy**: the plugin is loaded via `ft = 'markdown'`, i.e. only once a
Markdown buffer is opened — more precise than a blanket `event = "VeryLazy"`, since
there is nothing to do until a Markdown file is actually being edited.

```lua
-- lazy.nvim
{
  'StefanBartl/color_my_ascii.nvim',
  ft = 'markdown',
  dependencies = { 'StefanBartl/lib.nvim' }, -- required: the :ColorMyAscii command is built on it
  opts = {
    -- Optional: configuration goes here; every option has a default.
  }
}
```

`opts` is all that is needed — lazy.nvim calls `setup()` with it. Only call
`require('color_my_ascii').setup()` yourself if you are not using a plugin
manager that does.

The plugin activates automatically for Markdown files:

````markdown
```ascii
┌─────────────────────┐
│  Hello World!       │
└─────────────────────┘
```
````

→ Box-drawing characters are automatically highlighted in color.

See [docs/QUICKSTART.md](docs/QUICKSTART.md) for the full guide, including
installation with packer.nvim.

---

## Documentation

- [Quickstart](docs/QUICKSTART.md) — getting started, first steps, and typical configurations
- [Configuration](docs/configuration.md) — full `setup()` reference, treesitter integration, fence-line/fence-content highlighting
- [Commands](docs/commands.md) — all user commands, the `:Fence` toolkit, and its configuration
- [Supported Languages](docs/languages.md) — the 31 built-in languages and standard fence-tag support
- [Fence API](docs/api.md) — public APIs for plugin authors: fenced-block detection, and reading back the applied highlighting
- [Color Schemes](docs/schemes.md) — built-in schemes and how to create your own
- [Bindings Cheatsheet](docs/BINDINGS.md) — compact table of all commands, keymaps, and autocommands
- [Troubleshooting](docs/troubleshooting.md) — performance notes and common issues
- [Contributing](docs/contributing.md) — dev setup (stylua/luacheck/CI), adding a new language or character group
- [Features](docs/FEATURES/README.md) — full feature catalog, grouped by theme (highlighting, languages, fences, color schemes, tools)
- [Test File](docs/dev/TEST.md) — test all features
- [Changelog](docs/CHANGELOG.md) — version history
- [Vim Help](doc/color_my_ascii.txt) — complete reference (`:h color_my_ascii`)

---

## Credits

- Inspired by various ASCII art highlighting plugins
- Color schemes based on popular Vim/Neovim themes
- Thanks to all contributors

## See Also

- [Neovim Documentation](https://neovim.io/doc/)
- [Extmarks API](https://neovim.io/doc/user/api.html#api-extmarks)
- [Markdown Syntax](https://www.markdownguide.org/basic-syntax/)

## License

MIT — see [LICENSE](LICENSE).
