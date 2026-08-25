# Implementation Plan

A synthesis of [Arch&Coding.md](Arch&Coding.md), [Zentral-Prinzipien.md](Zentral-Prinzipien.md),
[Checklist.md](Checklist.md) and the existing [../ROADMAP.md](../ROADMAP.md).

color_my_ascii.nvim by now satisfies **all** the code and tooling points
derived from those three checklists. The gaps originally identified are
worked off; what remains are deliberately deferred design decisions (see
below).

## Completed

The concrete code and tooling fixes from earlier rounds are implemented and
verified — they are no longer listed individually here (see the git history /
[../CHANGELOG.md](../CHANGELOG.md)):

- ~~Hot path: repeated API access in `highlighter.lua` (`line_content` is now
  passed through instead of being fetched again per character).~~
- ~~The `enable_treesitter` flag replaced by a real `treesitter` config table
  plus block detection (`parser_ts.lua`) and grammar highlighting
  (`highlighter_ts.lua`).~~
- ~~`.luarc.json` created.~~
- ~~**Formatter/linter (stylua, luacheck) plus CI.** `.stylua.toml` (2 spaces,
  single quotes, 120 columns, matching the existing style), `.luacheckrc`
  (luajit std, `vim` as a global, length checking delegated to stylua) and
  `.github/workflows/lint.yml` (`stylua --check` plus `luacheck` on push/PR).
  The existing code was formatted through once; both linters run green
  locally (0 errors / 0 warnings).~~

## Deliberately deferred (not open tasks)

These points are documented decisions, **not** open work — they get built
only on demonstrated demand:

- **An external highlighter API for fences** (phases 1–3): see
  [fence_highlighter_api.md](fence_highlighter_api.md). No concrete consumer
  known; phase 1 (`User ColorMyAsciiFenceBlock`) is ready to start as soon as
  there is one.
- **Full LSP in the fence**: see [lsp_integration_fence.md](lsp_integration_fence.md).
  Recommendation: evaluate an otter.nvim adapter first, instead of building
  an embedded LSP engine of our own.
- **A per-directory `@types` folder**: the current structure (root
  `@types.lua` plus `debug/@types.lua`) covers the need; additional nearly
  empty types files would be overengineering for the current size of the code.
- **An automated test framework** (plenary/busted): deliberately left out
  (the "state of the art" clause); manual verification through `TESTS/`.
- **Deeper `lib.nvim` integration** in performance-critical modules: depends
  on `lib.nvim` stabilizing, see [../ROADMAP.md](../ROADMAP.md) "Under
  Consideration".
