# color_my_ascii.nvim — Binding Cheatsheet

Every user command, keymap, and autocommand `color_my_ascii.nvim` defines.

## Table of content

  - [User Commands](#user-commands)
  - [Keymaps](#keymaps)
  - [Autocommands](#autocommands)
    - [Static](#static)
    - [Dynamic](#dynamic)

---

## User Commands

One command, `:ColorMyAscii <subcommand>` (built via
[`lib.nvim.bindings.usercmd.composer`](https://github.com/StefanBartl/lib.nvim), with
`<Tab>` completion), registered in `lua/color_my_ascii/bindings/usrcmds.lua` —
distinct from the separate buffer-local `:Fence` toolkit below.

| command | desc |
| --- | --- |
| `:ColorMyAscii` | Highlight ASCII art in current buffer |
| `:ColorMyAscii toggle [global\|buffer]` | Toggle ASCII art highlighting. Defaults to `global` (every managed buffer), which is what this command has always done; `buffer` toggles just the current one. |
| `:ColorMyAscii debug` | Show debug information |
| `:ColorMyAscii show-config` | Show current configuration |
| `:ColorMyAscii check-fences` | Check current buffer for unmatched fenced code blocks |
| `:ColorMyAscii ensure-blank-lines` | Ensure blank lines before and after fenced code blocks |
| `:ColorMyAscii fence-jump` | Jump between a fence's opening/closing delimiter (%-style); falls back to the built-in `%` elsewhere |
| `:ColorMyAscii hover` | Show a float with the applied highlight/group/keyword info for the character under the cursor (also copied to a register) |
| `:ColorMyAscii schemes list` | List available color schemes |
| `:ColorMyAscii schemes switch <name>` | Switch to a different color scheme |
| `:ColorMyAscii schemes pick` | Pick color scheme with Telescope (live preview) |
| `:ColorMyAscii inspect char <char>` | (debug mode only) inspect a character's groups/highlight |
| `:ColorMyAscii inspect group <group>` | (debug mode only) inspect a group's characters |
| `:ColorMyAscii inspect inline` | (debug mode only) inspect inline code on the current line |
| `:ColorMyAscii inspect highlight <hl>` | (debug mode only) list groups using a highlight |
| `:ColorMyAscii stats` | (debug mode only) show comprehensive plugin statistics |
| `:Fence export [path] [--open] [--replace] [--html]` | Buffer-local (markdown): extract the fenced block under the cursor into a file (or an HTML file with its applied highlighting, `--html`) |
| `:Fence yank [reg] [--ansi]` | Copy the block content (no markers) to a register; `--ansi` copies it with its applied highlighting as ANSI escape codes |
| `:Fence open [--split\|--vsplit\|--tab\|--edit]` | Edit the block in a split (full LSP); `:w` syncs back |
| `:Fence run` | Run the block with its interpreter; output in a scratch split |
| `:Fence format` | Format the block in place with the language's formatter |
| `:Fence import <file>` | Replace the block content with a file's content |
| `:Fence lang <language>` | Change the fence's language tag |
| `:Fence select` | Visually select the block interior |
| `:[range]Fence wrap [lang]` | Wrap the current line / range in a fence |
| `:Fence unwrap` | Remove the fence around the block under the cursor |
| `:Fence align` | Straighten misaligned box-drawing edges in the block |

---

## Keymaps

All opt-in, disabled by default. Registered in
`lua/color_my_ascii/bindings/keymaps.lua` via `setup({ keymaps = {...} })`.
[lib.nvim](https://github.com/StefanBartl/lib.nvim) is a required dependency
(the `:ColorMyAscii` command itself is built on it); the keymaps are declared
through `lib.nvim.bindings.keymap`'s registry, which also reports a mistyped
action name instead of silently binding nothing. Every mapping sets `desc`,
so which-key.nvim picks them up automatically — no separate which-key
registration needed.

| action key | maps to command | example lhs |
| --- | --- | --- |
| `highlight` | `:ColorMyAscii` | `<leader>ah` |
| `toggle` | `:ColorMyAscii toggle` | `<leader>at` |
| `toggle_buffer` | `:ColorMyAscii toggle buffer` | `<leader>ab` |
| `schemes` | `:ColorMyAscii schemes pick` | `<leader>as` |
| `ensure_blank_lines` | `:ColorMyAscii ensure-blank-lines` | `<leader>af` |
| `show_config` | `:ColorMyAscii show-config` | `<leader>ac` |
| `debug` | `:ColorMyAscii debug` | `<leader>ad` |
| `check_fences` | `:ColorMyAscii check-fences` | `<leader>ax` |
| `fence_jump` | `:ColorMyAscii fence-jump` | `%` |
| `hover` | `:ColorMyAscii hover` | `<leader>ai` |
| `fence_yank` | `:Fence yank` | `<leader>fy` |
| `fence_open` | `:Fence open` | `<leader>fo` |
| `fence_run` | `:Fence run` | `<leader>fr` |
| `fence_format` | `:Fence format` | `<leader>fi` |
| `fence_select` | `:Fence select` | `<leader>fv` |
| `fence_wrap` | `:Fence wrap` | `<leader>fw` |
| `fence_unwrap` | `:Fence unwrap` | `<leader>fu` |
| `fence_align` | `:Fence align` | `<leader>fg` |
| `fence_export` | `:Fence export` | `<leader>fx` |

The `fence_*` actions call the argument-less `:Fence` sub-commands (see
[User Commands](#user-commands) above); like `check_fences`/`fence_jump` they
only do anything useful in a markdown buffer, since `:Fence` itself is
registered buffer-local there.

Example setup enabling a subset of the available actions:

```lua
require('color_my_ascii').setup({
  keymaps = {
    highlight           = '<leader>ah',
    toggle              = '<leader>at',
    toggle_buffer       = '<leader>ab',
    schemes             = '<leader>as',
    ensure_blank_lines  = '<leader>af',
    show_config         = '<leader>ac',
    debug               = '<leader>ad',
    check_fences        = '<leader>ax',
    fence_jump          = '%',
    hover               = '<leader>ai',
    fence_yank          = '<leader>fy',
    fence_open          = '<leader>fo',
    fence_run           = '<leader>fr',
    fence_format        = '<leader>fi',
    fence_select        = '<leader>fv',
    fence_wrap          = '<leader>fw',
    fence_unwrap        = '<leader>fu',
    fence_align         = '<leader>fg',
    fence_export        = '<leader>fx',
  },
})
```

---

## Right-click context menu

`color_my_ascii.integrations.menu` contributes `toggle` (global), `schemes`,
`hover`, and the `fence_yank`/`fence_open`/`fence_run`/`fence_format`/`fence_align`/
`fence_unwrap`/`fence_wrap` actions above. It leaves out `highlight`,
`toggle_buffer`, `ensure_blank_lines`, `show_config`, `debug`, `check_fences`,
`fence_jump`, `fence_select`, `fence_export`, and `:Fence import`/`:Fence lang` —
commands needing arguments or acting on a range aren't a great fit for a
no-argument menu click. Entries are in the shape [nvzone/menu](https://github.com/nvzone/menu)
expects, in markdown buffers only. `:Fence *` entries beyond `wrap` are
further gated on the cursor being inside a fenced block. No dependency on
`menu` itself — a host (typically your own `<RightMouse>` dispatcher)
composes the entries into its own menu. See
[docs/FEATURES/FENCES.md#right-click-context-menu](FEATURES/FENCES.md#right-click-context-menu).
`opts.menu.enable = false` opts out.

---

## Autocommands

---

### Static

Registered once at startup in `lua/color_my_ascii/bindings/autocmds.lua`.
Augroup: `ColorMyAscii`.

| event | pattern | desc |
| --- | --- | --- |
| `FileType` | `markdown` | Setup ASCII art highlighting + buffer-local `:Fence` command for markdown files |
| `FileType` | `comment_ascii.filetypes` | Setup comment_ascii highlighting for the configured filetypes — only registered when `comment_ascii.enable` is set and `comment_ascii.filetypes` is non-empty |

Three further autocommands are registered directly in `setup()`
(`lua/color_my_ascii/init.lua`), since they only make sense once the plugin
is configured:

| event | augroup | desc |
| --- | --- | --- |
| `ColorScheme` | `ColorMyAsciiFenceLineHl` | Re-resolve fence-line highlight groups after a colorscheme change |
| `ColorScheme` | `ColorMyAsciiHl` | Re-apply dynamically created (fixed-hex) ASCII-art highlight groups after a colorscheme change, so highlighting doesn't go stale after Neovim's implicit `hi clear` |
| `WinResized`, `VimResized` | `ColorMyAsciiFenceResize` | Recompute the `fence_*_highlight.right_pad` right-edge inset (measured from window width) after a resize; no-op unless a `right_pad` is set |

---

### Dynamic

Registered per-buffer in `setup_buffer()` in `lua/color_my_ascii/init.lua`.
Augroup: `ColorMyAsciiBuffer_<bufnr>`.

| event | pattern | desc |
| --- | --- | --- |
| `TextChanged`, `TextChangedI` | — | Re-highlight ASCII art on text change with debouncing |
| `BufDelete` | — | Cleanup ASCII art highlighting on buffer delete |
| `BufDelete` | `ColorMyAsciiDebounce` | Cancel any pending debounce timer for the deleted buffer |
| `BufDelete`, `BufWipeout` | `ColorMyAsciiFenceApiCache` | Invalidate the fences-API range-cache entry for the deleted buffer — consumed by other plugins, e.g. markdown.nvim, via `require("color_my_ascii.api.fences")` |
| `BufWritePost` | `ColorMyAsciiFenceOpen_<tbuf>` (temp scratch buffer) | Sync `:Fence open`'s edited content back into the source buffer |
| `BufWipeout`, `BufDelete`, `BufUnload` (once) | `ColorMyAsciiFenceOpen_<tbuf>` | Clean up `:Fence open`'s temp file/extmarks/session state |
| `CursorMoved` | (no augroup — Telescope wipes the prompt buffer itself on close) | Live-apply the scheme under cursor to all managed buffers during `:ColorMyAscii schemes pick` |

---

