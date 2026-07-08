# color_my_ascii.nvim — Binding Cheatsheet

Machine-readable overview of every user command, keymap, and autocommand defined by `color_my_ascii.nvim`. This file is documentation only and is not required or loaded by the plugin.

## Table of content

  - [User Commands](#user-commands)
  - [Keymaps](#keymaps)
  - [Autocommands](#autocommands)
    - [Static](#static)
    - [Dynamic](#dynamic)

---

## User Commands

Registered in `lua/color_my_ascii/bindings/usrcmds.lua`.

| command | desc |
| --- | --- |
| `:ColorMyAscii` | Highlight ASCII art in current buffer |
| `:ColorMyAsciiToggle` | Toggle ASCII art highlighting |
| `:ColorMyAsciiDebug` | Show debug information |
| `:ColorMyAsciiShowConfig` | Show current configuration |
| `:ColorMyAsciiCheckFences` | Check current buffer for unmatched fenced code blocks |
| `:ColorMyAsciiEnsureBlankLines` | Ensure blank lines before and after fenced code blocks |
| `:ColorMyAsciiListSchemes` | List available color schemes |
| `:ColorMyAsciiSwitchScheme <name>` | Switch to a different color scheme |
| `:ColorMyAsciiSchemes` | Pick color scheme with Telescope (live preview) |
| `:Fence export [path] [--open] [--replace]` | Buffer-local (markdown): extract the fenced block under the cursor into a file |
| `:Fence yank [reg]` | Copy the block content (no markers) to a register |
| `:Fence open [--split\|--vsplit\|--tab\|--edit]` | Edit the block in a split (full LSP); `:w` syncs back |
| `:Fence run` | Run the block with its interpreter; output in a scratch split |
| `:Fence format` | Format the block in place with the language's formatter |
| `:Fence import <file>` | Replace the block content with a file's content |
| `:Fence lang <language>` | Change the fence's language tag |
| `:Fence select` | Visually select the block interior |
| `:[range]Fence wrap [lang]` | Wrap the current line / range in a fence |
| `:Fence unwrap` | Remove the fence around the block under the cursor |

---

## Keymaps

All opt-in, disabled by default. Registered in
`lua/color_my_ascii/bindings/keymaps.lua` via `setup({ keymaps = {...} })`.
Uses `lib.nvim.map` when [lib.nvim](https://github.com/StefanBartl/lib.nvim)
is installed, falls back to `vim.keymap.set` otherwise. Every mapping sets
`desc`, so which-key.nvim picks them up automatically — no separate
which-key registration needed.

| action key | maps to command | example lhs |
| --- | --- | --- |
| `highlight` | `:ColorMyAscii` | `<leader>ah` |
| `toggle` | `:ColorMyAsciiToggle` | `<leader>at` |
| `schemes` | `:ColorMyAsciiSchemes` | `<leader>as` |
| `ensure_blank_lines` | `:ColorMyAsciiEnsureBlankLines` | `<leader>af` |
| `show_config` | `:ColorMyAsciiShowConfig` | `<leader>ac` |
| `debug` | `:ColorMyAsciiDebug` | `<leader>ad` |
| `check_fences` | `:ColorMyAsciiCheckFences` | `<leader>ax` |

Example setup enabling a subset of the available actions:

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
  },
})
```

---

## Autocommands

---

### Static

Registered once at startup in `lua/color_my_ascii/bindings/autocmds.lua`.
Augroup: `ColorMyAscii`.

| event | pattern | desc |
| --- | --- | --- |
| `FileType` | `markdown` | Setup ASCII art highlighting for markdown files |

---

### Dynamic

Registered per-buffer in `setup_buffer()` in `lua/color_my_ascii/init.lua`.
Augroup: `ColorMyAsciiBuffer_<bufnr>`.

| event | pattern | desc |
| --- | --- | --- |
| `TextChanged`, `TextChangedI` | — | Re-highlight ASCII art on text change with debouncing |
| `BufDelete` | — | Cleanup ASCII art highlighting on buffer delete |

---

