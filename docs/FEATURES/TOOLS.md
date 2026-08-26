# Tools

Cursor-side introspection and diagnostics: what's happening at this exact
character, whether the plugin's environment is set up right, and (in debug
mode) deeper statistics.

## Hover info for characters

`:ColorMyAscii hover` shows a float combining two views of "why is this
character colored the way it is" for whatever is under the cursor: the
*live* answer (the actual `hl_group` color_my_ascii's own extmarks painted
at this exact position right now, with resolved fg/bg — covers overlaps
between char/keyword/treesitter highlighting the same cell, whichever was
painted last) and the *config* answer (which character groups it belongs to
per config, and override status — independent of whether anything is
painted right now, e.g. cursor outside any ASCII block). Also reports
keyword-language matches when the cursor sits on a recognized keyword. The
same text is copied to the unnamed register (and system clipboard, where
available) for pasting into a bug report. Not gated behind `debug_enabled` —
useful any time.

Displayed via `lib.nvim.ui.kit`'s `note` popup when installed, falling back
to a plain floating window (`q`/`<Esc>`/`<C-c>` to close) otherwise.

- **Module:** `commands/hover.lua` (`M.show`, `M.info_at_cursor`)
- **Usercmds:** [../BINDINGS.md#user-commands](../BINDINGS.md#user-commands)
- **Keymaps:** `hover`
- **Tests:** `TESTS/hover_spec.lua`
- **Commit:** `63ab446`

## Health check

`:checkhealth color_my_ascii` verifies the plugin's own setup: dependencies
(`lib.nvim`), the installed treesitter parsers relevant to the current
buffer's fence languages, and the resolved plugin root — run once per new
repo/machine, not per edit.

- **Module:** `health.lua`

## Plugin management commands

The small set of always-available commands for the plugin as a whole:
`:ColorMyAscii` (manual re-highlight of the current buffer),
`:ColorMyAscii toggle [global|buffer]` (enable/disable),
`:ColorMyAscii debug` (basic debug info), `:ColorMyAscii show-config` (dump
the resolved configuration table).

### Toggle scope (2026-08-24)

`toggle` is and has always been **global**: one `state.enabled` flag applied
across every managed buffer. The flag/option audit recorded it as
"current-buffer only" and asked for a bang or range to reach several buffers
— that premise was backwards. What genuinely had no expression was the
opposite: turning highlighting off in *one* buffer.

`:ColorMyAscii toggle buffer` is that. `global` stays the default, so the
bare command is unchanged. It reuses the existing `state.buffers` model — a
buffer is highlighted when it is managed — instead of introducing a second
piece of state, and the two switches stay independent.

Two deliberate edges: enabling a single buffer while the plugin is globally
off is **refused** (it would mark the buffer managed and then highlight
nothing, which reads as a bug rather than a setting), and the per-buffer
state does not survive a re-attach — the FileType/BufReadPost autocmds call
`setup_buffer` again. It is for the buffer as it is open now; the
`filetypes`/`disable` config is the persistent opt-out.

- **Module:** `commands/debug.lua`, `commands/config.lua`,
  `init.lua` (`toggle`, `toggle_buffer`)
- **Usercmds:** [../BINDINGS.md#user-commands](../BINDINGS.md#user-commands)
- **Keymaps:** `highlight`, `toggle`, `toggle_buffer`, `debug`, `show_config`
- **Tests:** `TESTS/toggle_buffer_spec.lua`

## Debug-mode inspect & stats commands

Gated behind `debug_enabled = true` (off by default): `:ColorMyAscii inspect
char <char>` (which groups/highlight a character resolves to),
`:ColorMyAscii inspect group <group>` (every character in a group),
`:ColorMyAscii inspect inline` (parses the current line's inline-code
segments and shows what each character/keyword resolved to), `:ColorMyAscii
inspect highlight <hl>` (every group using a given highlight), and
`:ColorMyAscii stats` (group/language/lookup-table counts and override
counts across the whole resolved config). These routes are only registered
while debug mode is on — enabling `debug_enabled` at runtime re-registers
the whole `:ColorMyAscii` command to add them.

- **Module:** `debug/commands.lua`, `debug/inspect.lua`
- **Config:** `opts.debug_enabled` (default `false`), `opts.debug_verbose`
- **Usercmds:** [../BINDINGS.md#user-commands](../BINDINGS.md#user-commands)
