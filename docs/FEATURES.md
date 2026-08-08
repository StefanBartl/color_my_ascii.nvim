# Implemented Features Log

A running, detailed log of implemented roadmap items — one entry per feature,
with the files touched, the commit it landed in, and where it's documented.
Complements [ROADMAP.md](ROADMAP.md) (the terser public overview) with enough
detail to trace a feature back to its origin and rationale. Source items get
removed from the personal roadmap notes once logged here.

## Table of content

  - [Custom Language Definitions](#custom-language-definitions)
  - [Export/Copy with Highlighting](#exportcopy-with-highlighting)

---

## Custom Language Definitions

**Commit:** `8de65be` — `feat(config): config.languages extension point for custom languages`

Previously, adding a language required a `languages/*.lua` file inside the
plugin itself — no way to extend it from `setup()`.

- `config.languages`: user-supplied language definitions (`{ words,
  unique_words?, hl }`, same shape as the built-in `languages/*.lua` files),
  merged into the built-in set at `setup()` time. A name reused from a
  built-in language (e.g. `lua`) replaces that language's entry wholesale
  (not a field-by-field deep merge — an earlier version of this got that
  wrong, splicing the user's `words` into the built-in array index-by-index
  instead of replacing it; caught by `TESTS/config_languages_spec.lua`).
  Malformed entries (missing `words`/`hl`) are skipped with a warning
  instead of breaking keyword-lookup construction for the rest.
- Hot-reload (lightweight version): calling `setup()` again with
  already-open, plugin-managed buffers now invalidates the stale per-buffer
  parse cache and re-highlights them immediately, so an added/edited
  language takes effect without touching the buffer or restarting Neovim.
  No automatic file-watching of an external language definition — that
  remains unbuilt (would be the higher-effort half of this item).

**Files:** `lua/color_my_ascii/config/init.lua` (`merge_user_languages`),
`lua/color_my_ascii/config/DEFAULTS.lua`, `lua/color_my_ascii/@types.lua`,
`lua/color_my_ascii/init.lua` (`M.setup` re-highlight loop).

**Docs:** [languages.md#custom-languages](languages.md#custom-languages),
[configuration.md#custom-languages](configuration.md#custom-languages),
`:h color_my_ascii-config-languages`.

**Tests:** `TESTS/config_languages_spec.lua`.

---

## Export/Copy with Highlighting

**Commit:** `624c988` — `feat(fence): export/copy a block's applied highlighting as HTML/ANSI`

`:Fence export` previously wrote a fenced block's content as a **plain**
file (a "literate tangle"); there was no way to export the block **with its
color_my_ascii highlighting**.

- New module `highlight_export.lua`: re-reads a block's already-painted
  `ColorMyAscii`-namespace extmarks and reconstructs the same colors as
  either HTML (`<span class="cma-<Group>">` runs + a stylesheet covering
  only the groups the block actually uses) or 24-bit truecolor ANSI escape
  codes. Unhighlighted text passes through unstyled in both formats.
- `:Fence export --html [path]` — writes a standalone HTML document instead
  of plain text (suggested filename gets a `.html` extension regardless of
  the fence language).
- `:Fence yank [register] --ansi` — copies the block to a register as
  ANSI-colored text instead of plain text; paste-ready for a terminal or a
  chat that renders ANSI.

**Files:** `lua/color_my_ascii/highlight_export.lua` (new),
`lua/color_my_ascii/commands/fence/export.lua`,
`lua/color_my_ascii/commands/fence/yank.lua`,
`lua/color_my_ascii/commands/fence/init.lua` (completion).

**Docs:** [commands.md#fence-actions--fence-buffer-local-markdown](commands.md#fence-actions--fence-buffer-local-markdown),
`docs/BINDINGS.md`, `:h color_my_ascii-highlight-export`.

**Tests:** `TESTS/highlight_export_spec.lua`, plus `--html`/`--ansi`
coverage added to `TESTS/fence_export_spec.lua` /
`TESTS/fence_actions_spec.lua`.
