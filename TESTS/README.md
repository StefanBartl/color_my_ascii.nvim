# TESTS

The headless suite for color_my_ascii.nvim, plus the two hand-driven fixtures.

## Table of content

  - [Running the suite](#running-the-suite)
  - [Lint gates](#lint-gates)
  - [How a spec is written](#how-a-spec-is-written)
  - [The harness](#the-harness)
  - [No network, no subprocesses](#no-network-no-subprocesses)
  - [Spec register](#spec-register)
  - [Coverage](#coverage)
  - [Pinned bugs and findings](#pinned-bugs-and-findings)
  - [The manual fixtures](#the-manual-fixtures)

---

## Running the suite

From the repo root, exactly as CI does:

```sh
nvim --headless -u NONE -c "set rtp+=." -l TESTS/run.lua
```

It prints one line per spec, exits non-zero on the first failing one, and ends
with `COLOR_MY_ASCII_TESTS_OK` when everything passed.

`TESTS/run.lua` holds an explicit spec list — a new `*_spec.lua` file is *not*
picked up automatically and has to be added there.

**lib.nvim is a runtime dependency** (notifications, the `:ColorMyAscii`
composer, autocommand/keymap registries, `safe_api`), so the runner puts it on
the runtimepath *and* on `package.path` before loading anything. It looks, in
order, at:

1. `$LIB_NVIM_PATH`
2. `../lib.nvim` next to this checkout (what CI arranges)
3. `stdpath("data")/lazy/lib.nvim`

A sibling checkout deliberately wins over the plugin-manager copy: the
bootstrap clone is frequently older than the working checkout, and testing
against a stale lib.nvim produces misleading failures.

Nothing else is required. `ui.nvim` and `telescope.nvim` are soft dependencies
and are **not** checked out in CI — the specs that touch them substitute a stub
or assert the "not installed" branch (see below).

## Lint gates

`TESTS/` is part of both gates, so spec files are held to the same style as
`lua/`:

```sh
stylua --check lua/ plugin/ TESTS/
luacheck lua/ plugin/ TESTS/
```

## How a spec is written

No test framework. Each spec file returns a single function that receives the
shared harness:

```lua
return function(H)
  local eq, ok = H.eq, H.ok
  ...
end
```

An assertion that fails raises; `run.lua` catches it, prints `FAIL <spec>` with
the message, and the process exits non-zero. Specs run in one Neovim instance,
in the order listed in `run.lua`, and share global state — so a spec that
changes the configuration puts it back with `config.setup({})` when it is done,
and one that creates buffers deletes them.

## The harness

`TESTS/harness.lua`:

| Helper | Purpose |
|---|---|
| `H.eq(actual, expected, msg)` | equality |
| `H.ok(value, msg)` | truthiness |
| `H.scratch(ft, lines)` | a fresh scratch buffer, made current |
| `H.marks(bufnr, ns_name)` | every extmark of a **named** namespace, as `{row, col, end_col, hl}`, sorted by position |
| `H.has_mark(marks, row, col, end_col, hl)` | exact-position membership |
| `H.with_modules({ [name] = stub\|false }, fn)` | swap `package.loaded` entries for the duration of `fn` |
| `H.capture_notify(fn)` | collect `vim.notify` calls made during `fn` |
| `H.reload_notify({ names }, fn)` | same, for modules that bind `vim.notify` at load time |
| `H.notified(seen, needle)` | plain-substring search over collected notifications |

Two of these encode rules the rest of the suite follows.

**`H.marks` exists because highlighting *is* extmark positions.** Asserting
that a highlight call "succeeded" proves nothing: every position in this plugin
is a byte offset computed with Lua string arithmetic, and the failure mode is a
mark that lands in the wrong column, not an error. The specs therefore compare
hand-counted byte offsets against the marks that were actually written.

**`H.with_modules` / `H.reload_notify` exist because dependencies are bound to
upvalues at load time.** `local notify = vim.notify`, `local util =
require(...)` — patching the field afterwards is too late. A seam has to be in
place *before* the module under test is required, which is what these two do.

## No network, no subprocesses

Nothing in this suite spawns a process or opens a socket. Where the plugin
would, the seam is replaced and what gets asserted is the argv that *would*
have been spawned, plus each branch of the completion callback:

| Plugin path | Seam | Spec |
|---|---|---|
| `:Fence run` → interpreter | `vim.system` (a field on `vim`, resolved at call time) | `commands_spec` |
| `:Fence format` → formatter | `vim.system` | `commands_spec` |
| `schemes pick` → telescope | `pcall(require, 'telescope')` fails; the "not installed" branch is the one under test | `commands_spec`, `bindings_spec` |
| `integrations/menu` → `ui.contextmenu` | `package.loaded['ui.contextmenu']` replaced before the module is required | `health_menu_spec` |
| treesitter block detection | `package.loaded['color_my_ascii.parser_ts']` replaced with an "unavailable" and a "raises" double | `parser_spec` |
| treesitter syntax highlighting | the real, bundled `lua` grammar — gated on `vim.treesitter.language.add('lua')` | `highlighter_spec` |

Temp files are `vim.fn.tempname()` and are deleted again.

## Spec register

**Positions and parsing**

| Spec | Covers |
|---|---|
| `byte_offsets_spec` | multibyte extmark positions (umlauts, arrows, CJK, emoji) across all four passes and inline code |
| `parser_spec` | `is_ascii_fence`, the heuristic block scanner, backend dispatch, `tokenize_line`, `find_inline_codes` |
| `fences_spec` | the public fence API against both backends, asserting they agree |
| `fence_api_contract_spec` | the fence API *as a contract* for markdown.nvim: reachability, call shapes, caching, invalidation |
| `comment_ascii_spec` | the `-- ascii` … `-- /ascii` marker scanner |

**Highlighting**

| Spec | Covers |
|---|---|
| `highlighter_spec` | the four heuristic passes, their feature flags, precedence, rejected extmarks, the treesitter addition |
| `highlight_export_spec`, `api_highlight_spec` | reading the applied highlighting back out as data |
| `fence_hl_spec`, `fence_content_hl_spec` | fence-line and fence-interior background painting |
| `box_align_spec` | box-drawing edge alignment |
| `hover_spec` | the per-character highlight report |

**Configuration and state**

| Spec | Covers |
|---|---|
| `config_spec` | merge semantics, schemes, lookup tables, generated highlight groups, and the "no `nvim_set_hl` in a render pass" contract |
| `config_languages_spec` | the `languages` extension point |
| `scheme_loader_spec` | the scheme registry, its four failure modes, and the shape of every bundled scheme |
| `language_detector_spec` | all four detection strategies and their priority order |
| `cache_manager_spec` | the per-buffer parse cache: four invalidation rules, eviction, statistics, the cleanup timer |
| `debounce_manager_spec` | adaptive debouncing |
| `lifecycle_spec` | `setup`, per-buffer attachment, cached highlight passes, teardown through every deletion route, `toggle`, the `plugin/` bootstrap |
| `toggle_buffer_spec` | the per-buffer switch vs. the global one |

**Commands, wiring, reporting**

| Spec | Covers |
|---|---|
| `bindings_spec` | `:ColorMyAscii` (every route, run for real), the optional keymaps, the static autocommands, the debug module |
| `commands_spec` | the report commands, `ensure-blank-lines`, `check-fences`, the scheme commands, the `:Fence` helpers, `:Fence run`/`format` without spawning |
| `fence_actions_spec`, `fence_export_spec`, `fence_jump_spec` | the `:Fence` subcommands |
| `health_menu_spec` | `:checkhealth` and the opt-in context-menu entries |
| `debug_inspect_spec` | the inspection helpers behind `:ColorMyAscii inspect …` |
| `data_tables_spec` | the shape of all 31 language files and 5 group files, plus the cross-file properties a single file cannot show |

## Coverage

Every module under `lua/` has a spec, except for the deliberate omissions
below. What is *not* attempted anywhere, by design:

- **Rendering.** What an extmark looks like on screen is Neovim's business; the
  specs assert the extmark.
- **`---@meta` type modules.** `@types.lua` and `debug/@types.lua` hold
  annotations and no runtime code. Only "requiring them does not raise" is
  asserted, which is what keeps a syntax error in them from surfacing solely in
  someone's editor.
- **Declarative colour and keyword data.** `languages/*.lua`, `groups/*.lua`
  and `schemes/*.lua` are transcribed data; re-asserting each entry would
  duplicate the file rather than test it. Instead `data_tables_spec` and
  `scheme_loader_spec` check the *contract* each file has to satisfy, applied
  to every file that ships, plus the cross-file properties that no single file
  reveals (a keyword listed twice, a word claimed as "unique" by two languages,
  a character claimed by two groups).
- **Real subprocesses.** `:Fence run` and `:Fence format` are covered up to and
  including the argv and every callback branch; the interpreter and the
  formatter themselves are not run.
- **Picker plumbing.** `commands/schemes.telescope_picker` past its
  "telescope not installed" guard. telescope.nvim is neither a dependency nor a
  CI checkout, and the entry shape it would build is pure data assembly around
  a backend that is not there.
- **`ui.nvim`'s own behaviour.** `integrations/menu.lua` is covered against a
  stubbed `ui.contextmenu`: what is pinned is the entries this plugin
  contributes and their enabled/disabled gating, not how ui.nvim renders them.

## Pinned bugs and findings

Assertions marked `BUG:` or `FINDING:` pin behaviour that is *wrong* — they
document it so it cannot change unnoticed, and they will fail loudly when it is
fixed (which is the point).

Two defects that used to be pinned here are fixed as of commit `0437fe0`, and
the specs that pinned them now assert the fix instead (`regression` comments,
not `BUG:`):

- `:ColorMyAscii ensure-blank-lines` promised blank lines *around* a fenced
  block and inserted them *inside* one too (`commands_spec`).
- `build_unique_keyword_lookup` resolved an eight-word `unique_words` clash
  between two languages by table iteration order instead of dropping it
  (`data_tables_spec`). The clash list itself is still pinned, so a ninth
  collision is a deliberate decision in the data, not a silent loss.

Three remain open:

1. **comment_ascii highlights land `#prefix + 1` bytes too far left**
   (`byte_offsets_spec`). `comment_ascii.find_blocks` strips the buffer's
   comment prefix from every content line, and the highlighter then uses those
   stripped strings *both* as the text to scan *and* as the coordinate system
   for extmarks written into the unstripped buffer line. In a `-- ascii` block
   an arrow at byte 9 of the real line is painted at byte 6, and the
   default-text span stops three bytes short of the line's end.

2. **`enable_bracket_highlighting` cannot switch bracket highlighting off**
   (`highlighter_spec`). The lookup adds the six brackets in a step that skips
   any character a *group* already claims — and the bundled
   `groups/operators.lua` claims all six. Its own comment there calls them
   "optional, can be controlled by enable_bracket_highlighting"; they are not.
   The flag only takes effect once the groups stop covering them.

3. **Twelve keywords are listed twice inside their own language file**
   (`data_tables_spec`): `bash:unset`, `cpp:constexpr`, `cpp:decltype`,
   `llvm:label`, `llvm:uge`, `llvm:ugt`, `llvm:ule`, `llvm:ult`, `lua:goto`,
   `typescript:default`, `vim:map`, `zig:volatile`. Harmless to the character
   lookup, but the keyword lookup then holds two identical entries, so the word
   is painted twice at each position and counts twice towards that language's
   detection tiebreaker. Related: `bash` declares `bash` and `sh` as unique
   words without listing them as keywords, so they steer detection while never
   being highlighted themselves.

Two smaller things are pinned as *documented behaviour* rather than as
defects: the inline-code default-text span starts after the opening backtick
but ends past the closing one (`byte_offsets_spec`), and the `Empty buffer`
guard in `commands/format.lua` is unreachable, because a Neovim buffer always
has at least one line (`commands_spec`).

A fifth defect was found and fixed directly during a re-audit rather than
pinned, because the fix carries no behaviour-change risk for the healthy case:
`:checkhealth` reported "lib.nvim not found" via `health.error` and then
unconditionally re-required the exact same module to hand the report over to
it — raising and aborting the report right after the warning that was supposed
to explain why. `health.lua` now reuses the module it already tried to load
instead of requiring it a second time, and only hands off when that succeeded.
`health_menu_spec` simulates a missing lib.nvim at the require seam and asserts
the report completes and still names the missing dependency.

A sixth defect, found the same way, is fixed too: `parser.get_byte_offset`
drove `vim.str_utf_pos(line)` — which returns a *table* of each character's
byte start, not an iterator function — as a generic-for loop, so every call
with `col > 0` raised "attempt to call a table value" instead of converting
anything. Nothing in the plugin called it, which is the only reason it had
never been seen, but it is a public, documented function on a module other
code requires. It now indexes into the table directly. `byte_offsets_spec`
pins the converted byte offsets instead of the crash.

## The manual fixtures

Unrelated to the headless suite, and not run by it:

- [`FIXTURE.md`](./FIXTURE.md) — a markdown file that exercises every feature by
  hand, with [`FIXTURE-CONFIG.md`](./FIXTURE-CONFIG.md) to turn them all on.
- [`ScopedFence.md`](./ScopedFence.md) — the fenced-scope feature as a
  walkthrough.
