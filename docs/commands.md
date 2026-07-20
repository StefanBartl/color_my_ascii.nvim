# Commands

Full reference for every user command, including the `:Fence` literate-programming
toolkit and its configuration. For a compact machine-readable table of every
command, keymap, and autocommand, see [Bindings Cheatsheet](BINDINGS.md).

## Table of content

  - [Core Commands](#core-commands)
  - [Fence Management](#fence-management)
  - [Fence actions — `:Fence`](#fence-actions--fence)
    - [Syntax highlighting inside fences](#syntax-highlighting-inside-fences)
  - [Scheme Management](#scheme-management)
    - [Available Schemes](#available-schemes)
  - [Keybinding Examples](#keybinding-examples)

---

One command, `:ColorMyAscii <subcommand>` (built via
[`lib.nvim.usercmd.composer`](https://github.com/StefanBartl/lib.nvim), with
`<Tab>` completion) — distinct from the separate buffer-local `:Fence`
toolkit below.

## Core Commands

| Command | Description |
|---------|-------------|
| `:ColorMyAscii` | Manually update highlighting |
| `:ColorMyAscii toggle` | Enable/disable plugin |
| `:ColorMyAscii debug` | Show debug information (basic) |
| `:ColorMyAscii show-config` | Show detailed configuration |
| `:checkhealth color_my_ascii` | Run health check |
| `:h color_my_ascii` | Open Vim help |

---

## Fence Management

| Command | Description |
|---------|-------------|
| `:ColorMyAscii check-fences` | Check for unmatched fences |
| `:ColorMyAscii ensure-blank-lines` | Ensure blank lines around code blocks |
| `:ColorMyAscii fence-jump` | Jump between a fence's opening/closing delimiter (%-style); falls back to the built-in `%` elsewhere |

---

## Fence actions — `:Fence` (buffer-local, markdown)

A small literate-programming toolkit for the fenced code block **under the
cursor**, built on the [fence API](api.md). Registered buffer-local in markdown
buffers. Argument completion suggests subcommands, flags, file paths and
language tags.

| Subcommand | Description |
|------------|-------------|
| `:Fence export [path] [--open] [--replace]` | Extract the block into a standalone file |
| `:Fence yank [reg]` | Copy the block content (no markers) to a register (default `"` + `+`) |
| `:Fence open [--split\|--vsplit\|--tab\|--edit]` | Edit the block in a real split (full LSP/formatter); `:w` syncs back |
| `:Fence run` | Run the block with its interpreter; show output in a scratch split |
| `:Fence format` | Format the block in place with the language's formatter |
| `:Fence import <file>` | Replace the block content with a file's content (inverse of export) |
| `:Fence lang <language>` | Change the fence's language tag |
| `:Fence select` | Visually select the block interior |
| `:'<,'>Fence wrap [lang]` | Wrap the current line / visual range in a fence |
| `:Fence unwrap` | Remove the fence around the block under the cursor |

**export** — path may be quoted or bare (`:Fence export "src/a.js"`,
`:Fence export 'a b.py'`, `:Fence export a.lua`); omit it for a prompt with a
suggested filename (extension derived from the fence language) + file completion.
`--open` opens the file after; `--replace` swaps the block for a link reference
(literate tangle).

**open** — the "otter-lite" editor: the block is written to a temp file with the
right extension and opened in a split, so the language server and formatters
attach normally. The fence interior is anchored with extmarks; saving the split
(`:w`) writes the changes back into the fence.

````lua
require('color_my_ascii').setup({
  fence_export = {
    default_dir    = "buffer",   -- "buffer" | "cwd"
    open_after     = false,      -- always open after export
    open_cmd       = "vsplit",   -- "edit" | "split" | "vsplit" | "tabedit"
    replace        = false,      -- always replace with a reference
    replace_format = "[%s](%s)", -- (filename, relative-path)
    ext_map        = {},         -- language-tag -> extension overrides
  },
  fence_run = {
    -- interpreter per language tag; string or string[], temp file appended.
    -- Merged on top of the built-ins (python3/node/lua/bash/ruby/go run/...).
    runners = { python = "python3" },
  },
  fence_format = {
    -- stdin/stdout formatter per language tag (string[]). Merged on top of the
    -- built-ins (stylua/black/prettier/gofmt/shfmt/rustfmt).
    formatters = { lua = { "stylua", "-" } },
  },
})
````

### Syntax highlighting inside fences

A `` ```javascript `` block is highlighted by Neovim's **native treesitter
injections** (install the parser with `:TSInstall javascript` and enable
`nvim-treesitter` highlight). For languages color_my_ascii knows
(`fence_language_map`), it additionally overlays the real grammar via
`treesitter.syntax_highlight` (on by default). `:checkhealth color_my_ascii`
reports which fence languages in the buffer are missing a parser.

Full LSP inside fences (completion/hover/diagnostics) is on the roadmap — see
[docs/ROADMAP/lsp_integration_fence.md](ROADMAP/lsp_integration_fence.md).

---

## Scheme Management

| Command | Description |
|---------|-------------|
| `:ColorMyAscii schemes list` | List available color schemes |
| `:ColorMyAscii schemes switch <name>` | Switch to a different scheme |
| `:ColorMyAscii schemes pick` | Pick scheme with Telescope (live preview) |

### Available Schemes

- `default`    - Built-in Neovim highlights
- `matrix`     - Green hacker style
- `nord`       - Cool blue/cyan
- `gruvbox`    - Warm retro colors
- `dracula`    - Vibrant purple/pink
- `catppuccin` - Soft pastel colors
- `onedark`    - Dark theme with subtle highlights
- `solarized`  - Solarized color palette
- `tokyonight` - Dark theme with blue accents
- `monokai`    - Classic Monokai color scheme

See [Color Schemes](schemes.md) for details on each scheme and how to build
your own.

---

## Keybinding Examples

Keymaps are **opt-in** and disabled by default. Enable and customize them via the
`keymaps` option in `setup()`:

```lua
require('color_my_ascii').setup({
  keymaps = {
    highlight           = '<leader>ah',
    toggle              = '<leader>at',
    schemes             = '<leader>as',
    ensure_blank_lines  = '<leader>af',
    show_config         = '<leader>ac',
    debug               = '<leader>ad',
    check_fences        = '<leader>ax',
    fence_jump          = '%',
  },
})
```

`fence_jump` is meant to be bound to `%` itself: on a fence delimiter line it
jumps to the matching delimiter (the same mental model `%` already applies to
`()`/`{}`/`[]` pairs), and falls back to the built-in `%` everywhere else, so
it only adds behavior.

Each mapping is set with a `desc`, so [which-key.nvim](https://github.com/folke/which-key.nvim)
picks them up automatically without extra configuration.
[lib.nvim](https://github.com/StefanBartl/lib.nvim) is a required dependency
(the `:ColorMyAscii` command itself is built on it); `lib.nvim.map`
specifically stays soft-guarded for keymap registration, falling back to
`vim.keymap.set` if that particular submodule isn't resolvable.

See [Bindings Cheatsheet](BINDINGS.md) for the full cheatsheet of user commands,
keymap actions, and autocommands.

---

## See Also

- [../README.md](../README.md) — project overview and quickstart
- [Fence API](api.md) — the API these commands are built on
- [Configuration](configuration.md) — full `setup()` reference
- [Bindings Cheatsheet](BINDINGS.md) — compact table of commands, keymaps, autocommands
