# Color Schemes

Complete `setup()` configurations bundling character-group colors, keyword
highlights, overrides, and feature flags into one named look — plus the
theme-detection color schemes use to match your actual colorscheme for
fence-line highlighting.

## Built-in color schemes

10 ready-to-use schemes, each `require('color_my_ascii').setup(require('color_my_ascii.schemes.<name>'))`:

- `default` — built-in Neovim highlight groups, maximum compatibility
- `matrix` — bright green hacker style, all features enabled
- `nord` — cool blue/cyan, function names enabled
- `gruvbox` — warm retro colors, brackets and inline code enabled
- `dracula` — vibrant purple/pink, all features enabled
- `catppuccin` — soft pastel (Catppuccin Mocha), function names and inline code enabled
- `onedark` — Atom-inspired dark theme, function names/brackets/inline code enabled
- `solarized` — Solarized Dark palette, maximum compatibility
- `tokyonight` — Tokyo Night Storm, function names/brackets/inline code enabled
- `monokai` — high-contrast neon, function names/brackets/inline code enabled

A loaded scheme is a plain Lua table — modify fields on it (or
`vim.tbl_deep_extend` over a base scheme) before passing it to `setup()` to
customize or build a variant without writing a new scheme file.

- **Module:** `schemes/*.lua`
- **Usercmds:** `:ColorMyAscii schemes list` / `switch <name>` / `pick` (Telescope live preview) — [../BINDINGS.md#user-commands](../BINDINGS.md#user-commands)

## Creating a custom scheme

A scheme file returns a `ColorMyAscii.Config`-shaped table: `groups` (the
character groups, each `{ chars, hl }`), optional `keywords` and
`overrides`, `default_hl`/`default_text_hl`, and the `enable_*` feature
flags. Save it as `lua/color_my_ascii/schemes/<name>.lua` in a fork, or keep
it entirely in your own config and pass the table straight to `setup()` —
nothing requires it to live inside the plugin.

- **Docs:** [../schemes.md](../schemes.md) — full step-by-step guide, palette-building techniques (analogous/complementary/monochromatic), and dynamic-color extraction from the active colorscheme

## Theme-matched fence-line presets

`fence_line_highlight.preset = "auto"` (the default) reads `vim.g.colors_name`
and substring-matches it against a hand-tuned palette per bundled theme — so
`catppuccin-mocha`, `tokyonight-storm`, and `gruvbox-material` all match their
base theme automatically, and it re-matches on every `:colorscheme` change.
Falls back to the generic `subtle` preset on an unrecognized theme. 17
themes are bundled: `catppuccin`, `tokyonight`, `gruvbox`,
`gruvbox-material`, `nord`, `onedark`, `dracula`, `kanagawa`, `rose-pine`,
`everforest`, `nightfox`, `material`, `sonokai`, `monokai`, `solarized`,
`github`, `oxocarbon` — a superset of the 10 full color schemes above, since
this only needs to match a fence-delimiter accent color, not a complete
highlighting configuration.

- **Module:** `theme_presets.lua`
- **Config:** `opts.fence_line_highlight.preset` — see [FENCES.md#fence-line-highlighting](FENCES.md#fence-line-highlighting)
