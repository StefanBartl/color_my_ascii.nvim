# Changelog

All notable changes to color_my_ascii.nvim will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Table of content

  - [[Unreleased]](#unreleased)
    - [Added](#added)
    - [Changed](#changed)
    - [Fixed](#fixed)
  - [[1.0.0] - 2025-01-XX](#100-2025-01-xx)
    - [Added](#added-1)
    - [Features](#features)
  - [[0.1.0] - Development](#010-development)
    - [Added](#added-2)
  - [Migration Guides](#migration-guides)
    - [Migrating to 1.1.0](#migrating-to-110)
    - [Breaking Changes](#breaking-changes)
  - [Upgrade Instructions](#upgrade-instructions)
    - [From 0.x to 1.0.0](#from-0x-to-100)
  - [Deprecation Warnings](#deprecation-warnings)
  - [Future Plans](#future-plans)
    - [Planned for 1.2.0](#planned-for-120)
    - [Planned for 2.0.0](#planned-for-200)
  - [Contributors](#contributors)
  - [Support](#support)

---

## [Unreleased]

### Added
- `fence_line_highlight.respect_indent` / `fence_content_highlight.respect_indent` (both default `true`): for an indented fenced block, start the delimiter/interior highlight at the block's own indent column (the opening fence's first backtick) on every row — closing fence and blank interior lines included — instead of painting from column 0. Set to `false` for the previous full-line behaviour.
- `fence_line_highlight.right_pad` / `fence_content_highlight.right_pad` (both default `1`, clamped 0–20): when `respect_indent` is on, hold this many screen columns between the fence background and the window's right edge so the highlight never quite touches the border. Recomputed on window resize; needs the buffer to be displayed in a window.
- `ColorScheme` autocommand that re-applies color_my_ascii's dynamically created (fixed-hex) ASCII-art highlight groups, so highlighting no longer goes stale after a `:colorscheme` switch (Neovim's implicit `hi clear` used to wipe them silently).
- Default keymap actions for the argument-less `:Fence` sub-commands: `fence_yank`, `fence_open`, `fence_run`, `fence_format`, `fence_select`, `fence_wrap`, `fence_unwrap`. Opt-in via `setup({ keymaps = {...} })` like the existing actions. See [BINDINGS.md](BINDINGS.md#keymaps).
- Development tooling: `.stylua.toml` (formatter config matching the existing style), `.luacheckrc` (linter config), and a `.github/workflows/lint.yml` CI workflow that runs `stylua --check` and `luacheck` on pushes and pull requests. See [Contributing](contributing.md#development).
- `fence_content_highlight`: full-width background highlight of a fenced block's interior (blank lines and trailing whitespace included), on by default, shaded from the resolved `fence_line_highlight` color
- `fence_jump` keymap action / `:ColorMyAscii fence-jump`: `%`-style jump between a fence's opening and closing delimiter, falling back to the built-in `%` elsewhere
- `config.languages`: extension point for adding a custom language from `setup()` without a `languages/*.lua` file in the plugin itself; merges into the built-in set (same-name entries replace a built-in wholesale), invalid entries are skipped with a warning. Calling `setup()` again re-highlights already-open buffers immediately (simple hot-reload).
- `:Fence export --html` / `:Fence yank --ansi`: export or copy a fenced block's *applied* color_my_ascii highlighting (not just plain text) as a standalone HTML document or 24-bit ANSI escape codes, via the new `highlight_export.lua` module.
- `:ColorMyAscii hover` (+ opt-in `hover` keymap action): float showing the applied highlight, config-level group/override, and keyword-language info for the character under the cursor; also copies the same text to a register for pasting into a bug report.
- `:Fence align` (+ opt-in `fence_align` keymap action): straightens simple box-drawing boxes whose right edge has drifted after hand-editing, widening each box to its own widest row so content is only ever padded, never cut off. Directory-tree connectors and anything that isn't a clean rectangle are left untouched. Algorithm in the new `box_align.lua`.
- `config.comment_ascii`: opt-in detection/highlighting of explicitly-marked ASCII blocks inside code comments outside markdown (`-- ascii` … `-- /ascii`, using the buffer's own line-comment prefix), activating the plugin on the configured non-markdown filetypes. Highlighting only - the `:Fence` toolkit and fence-line/fence-content background highlighting remain markdown-only.
- State-based fence parser for accurate block detection
- Support for tilde fences (`~~~`) in addition to backticks
- `ColorMyAsciiCheckFences` command to detect unmatched code blocks
- Comprehensive nil-safety checks throughout parser
- Support for tracking all code blocks (not just ASCII) to prevent false detection
- Improved EOF handling with warnings for unclosed blocks

---

### Changed
- Complete rewrite of fence detection logic using state machine approach
- Parser now tracks all code blocks but only highlights ASCII blocks
- Empty fences (```` ``` ````) are now contextually interpreted (opening vs closing)
- Improved language detection to work with new parser architecture

---

### Fixed
- Fixed incorrect highlighting of text outside ASCII blocks when `treat_empty_fence_as_ascii = true`
- Fixed closing fences of non-ASCII blocks being misinterpreted as ASCII block starts
- Fixed parser treating all empty fences as opening fences
- Fixed nil-safety issues in OpenFenceInfo handling
- Fixed fence matching to respect fence length (closing >= opening)

---

## [1.0.0] - 2025-01-XX

### Added
- Initial release
- Automatic detection of ASCII code blocks in Markdown files
- Support for 10 programming languages (C, C++, Lua, Go, Rust, TypeScript, Python, Bash, Zig, LLVM IR)
- 5 predefined character groups (Box-Drawing, Blocks, Arrows, Symbols, Operators)
- Intelligent language detection via explicit markers, heuristics, and buffer context
- Custom highlight support with RGB/Hex colors
- 5 predefined color schemes (Default, Matrix, Nord, Gruvbox, Dracula)
- Function name detection (heuristic-based)
- Bracket highlighting (parentheses, square brackets, curly braces)
- Inline code highlighting (`` `...` ``)
- Empty fence support (`treat_empty_fence_as_ascii` option)
- Default text highlighting for dimmed normal text in blocks
- Health check (`:checkhealth color_my_ascii`)
- User commands:
  - `:ColorMyAscii` - Manual highlighting
  - `:ColorMyAsciiToggle` - Toggle plugin on/off
  - `:ColorMyAsciiDebug` - Show debug information
- Vim help documentation (`:h color_my_ascii`)

---

### Features
- Non-intrusive highlighting using Neovim extmarks
- Modular language and group definitions
- Debounced updates (100ms delay)
- Efficient O(1) character and keyword lookup
- UTF-8 aware parsing
- Lazy loading for Markdown files
- Property-based configuration system

---

## [0.1.0] - Development

### Added
- Initial development version
- Basic ASCII art detection
- Simple character highlighting
- Keyword support

---

## Migration Guides

### Migrating to 1.1.0

If you're using `treat_empty_fence_as_ascii = true`:

**Before:**
````lua
require('color_my_ascii').setup({
  treat_empty_fence_as_ascii = true,
})
````

**After:**
The behavior is now more robust. Empty fences are correctly interpreted based on context:
- If outside a block: opening fence
- If inside a block: closing fence

No configuration changes needed, but behavior is more predictable.

---

### Breaking Changes

None in 1.1.0 - fully backward compatible.

---

## Upgrade Instructions

### From 0.x to 1.0.0

1. Update plugin via your package manager
2. Update configuration (optional):
````lua
-- Old style (still works)
require('color_my_ascii').setup({
  enable_keywords = true,
})

-- New style (recommended)
require('color_my_ascii').setup({
  enable_keywords = true,
  enable_function_names = true,
  enable_bracket_highlighting = true,
  enable_inline_code = true,
})
````

3. Run health check:
````vim
:checkhealth color_my_ascii
````

---

---

## Deprecation Warnings

None currently.

---

## Future Plans

### Planned for 1.2.0

- [ ] Treesitter integration for syntax-aware highlighting
- [ ] Custom language definitions via configuration
- [ ] Hot-reload of language files
- [ ] Telescope integration (ASCII block picker)
- [ ] LSP integration for semantic highlighting

---

### Planned for 2.0.0

- [ ] Breaking: Refactor configuration API
- [ ] Async rendering for large documents
- [ ] Virtual text annotations
- [ ] Block folding support

---

## Contributors

Special thanks to all contributors who helped make this plugin better!

- Community feedback and bug reports

---

## Support

- **Issues**: [GitHub Issues](https://github.com/StefanBartl/color_my_ascii.nvim/issues)
- **Discussions**: [GitHub Discussions](https://github.com/StefanBartl/color_my_ascii.nvim/discussions)

---

