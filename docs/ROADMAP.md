# Roadmap

Ideas and planned work for color_my_ascii.nvim. Nothing here is committed to a
timeline - this is a working list of what might come next. For the full,
themed catalog of what's actually implemented, see
[FEATURES/README.md](FEATURES/README.md); for a version-by-version history,
see [CHANGELOG.md](CHANGELOG.md).

## Planned

- Additional built-in color schemes

## Implemented

- Optional treesitter-based block detection and real syntax highlighting
  (`treesitter.block_detection` / `treesitter.syntax_highlight`), on by
  default via `treesitter.enabled = true` - falls back silently to
  heuristic-only behavior wherever a parser isn't installed.
  See [README.md](../README.md#treesitter-integration).
- 31 predefined languages (up from 11), with `fence_language_map` now covering
  every one of them under its common tag(s) by default - plain ` ```go `/
  ` ```javascript `/` ```json ` etc. blocks are highlighted without needing the
  `ascii-` prefix. See [README.md](../README.md#supported-languages).
- Full `:Fence` sub-command toolkit turning the dispatcher into a small
  literate-programming tool: `yank`, `open` (sync-on-`:w` split editing),
  `run`, `format`, `import`, `lang`, `select`, `wrap`/`unwrap`, on top of the
  original `export`. See [BINDINGS.md](BINDINGS.md#user-commands) for the full
  list.
- Additional user commands for scheme/keyword introspection: `schemes list`/
  `switch`/`pick` plus the debug-mode `inspect char|group|inline|highlight`
  and `stats` commands. See [BINDINGS.md](BINDINGS.md#user-commands).
- Default keymap actions for the argument-less `:Fence` sub-commands (`yank`,
  `open`, `run`, `format`, `select`, `wrap`, `unwrap`), opt-in via
  `setup({ keymaps = {...} })` like the existing `:ColorMyAscii` actions.
  See [BINDINGS.md](BINDINGS.md#keymaps).
- `ColorScheme` autocommand that re-applies color_my_ascii's dynamically
  created (fixed-hex) ASCII-art highlight groups, so highlighting survives a
  `:colorscheme` switch instead of going stale after Neovim's implicit
  `:hi clear`. See [BINDINGS.md](BINDINGS.md#autocommands).

## Under Consideration

- Deeper `lib.nvim` integration if/once its API stabilizes

## Engineering Checklists & Implementation Plan

Internal (German) notes distilling the project's Lua/Neovim architecture and coding
checklists down to what's actually relevant for this plugin's size, plus a concrete
implementation plan derived from them:

- [ROADMAP/Arch&Coding.md](ROADMAP/Arch&Coding.md)
- [ROADMAP/Zentral-Prinzipien.md](ROADMAP/Zentral-Prinzipien.md)
- [ROADMAP/Checklist.md](ROADMAP/Checklist.md)
- [ROADMAP/IMPLEMENTATION_PLAN.md](ROADMAP/IMPLEMENTATION_PLAN.md)
