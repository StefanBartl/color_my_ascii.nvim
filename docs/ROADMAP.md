# Roadmap

Ideas and planned work for color_my_ascii.nvim. Nothing here is committed to a
timeline - this is a working list of what might come next.

## Planned

- Additional built-in color schemes

## Implemented

- Optional treesitter-based block detection and real syntax highlighting
  (`treesitter.block_detection` / `treesitter.syntax_highlight`, off by default).
  See [README.md](../README.md#treesitter-integration).
- 31 predefined languages (up from 11), with `fence_language_map` now covering
  every one of them under its common tag(s) by default - plain ` ```go `/
  ` ```javascript `/` ```json ` etc. blocks are highlighted without needing the
  `ascii-` prefix. See [README.md](../README.md#supported-languages).

## Under Consideration

- Additional default keymap actions (see [BINDINGS.lua](BINDINGS.lua) for the current set)
- Additional autocommand hooks (e.g. re-highlight on `ColorScheme` change)
- Additional user commands for scheme/keyword introspection
- Deeper `lib.nvim` integration if/once its API stabilizes

## Engineering Checklists & Implementation Plan

Internal (German) notes distilling the project's Lua/Neovim architecture and coding
checklists down to what's actually relevant for this plugin's size, plus a concrete
implementation plan derived from them:

- [ROADMAP/Arch&Coding.md](ROADMAP/Arch&Coding.md)
- [ROADMAP/Zentral-Prinzipien.md](ROADMAP/Zentral-Prinzipien.md)
- [ROADMAP/Checklist.md](ROADMAP/Checklist.md)
- [ROADMAP/IMPLEMENTATION_PLAN.md](ROADMAP/IMPLEMENTATION_PLAN.md)
