# An external highlighter API for fences

A status document, a battle plan. The question: can other Neovim plugins,
external apps/tools or CLI tools take over or steer the highlighting
**inside** a fence (marker lines and/or content) themselves? And if so, how.

---

## 1. Where things stand

Today there are two building blocks:

- **`color_my_ascii.api.fences`** ([lua/color_my_ascii/api/fences.lua](../../lua/color_my_ascii/api/fences.lua)):
  stable, language-agnostic fence detection. `list_blocks`/`block_at` return
  `ColorMyAscii.FenceBlock` descriptors (ranges, language, `is_ascii`), cached
  per `(bufnr, changedtick)`. Already consumed by markdown.nvim today.
- **`color_my_ascii.fence_hl`** ([lua/color_my_ascii/fence_hl.lua](../../lua/color_my_ascii/fence_hl.lua)):
  paints marker lines (`fence_line_highlight`) and the block interior
  (`fence_content_highlight`) across the full width via `line_hl_group`
  extmarks in a namespace of its own, with hard-wired priorities (90 / 80,
  below the character highlights at 100+).

Both are **read-only to the outside** today: others can read our ranges, but
cannot hook into *our* highlight passes or register painters of their own.

---

## 2. Is it possible in principle?

**Inside the Neovim process (Lua plugins): yes, without restriction.**
Highlighting runs through extmarks/highlight groups in separate namespaces —
any plugin that knows our `list_blocks`/`block_at` ranges can paint on those
same lines in its own extmarks *today* (namespaces are additive, no risk of
collision). What is missing is not *feasibility* but **convenience and a
contract**: when do blocks get re-detected, where and at what priority should
one paint, how does one learn about changes without polling.

**Outside the Neovim process (external apps/CLI tools): possible with
limits, and one important restriction.** Highlighting is a pure Neovim UI
concept (extmarks/highlight groups exist only *inside* a running instance).
A CLI tool without a running Neovim instance cannot "highlight" anything — it
can only:
  a) **supply data** that *we* then interpret and paint ourselves (e.g. a
     classification/language assignment per fence), or
  b) **drive a running Neovim instance remotely** through its built-in
     msgpack RPC (`nvim --remote-expr`, `nvim --server ... --remote-expr
     "v:lua.require'color_my_ascii'.fences.list_blocks()"`, or an RPC client
     calling `nvim_exec_lua`) and use our Lua API through that, as if it were
     a Neovim plugin itself.

There is no sensible third way (no "highlight these lines" without a Neovim
instance). **Conclusion: possible, but (b) is the only real path for
"external tools" — and it is already usable today, because it needs nothing
beyond Neovim's own facilities plus our existing `M.fences` API.** The new
part is exclusively (a) — an extension that allows *highlighting
contributions* rather than only *read access to ranges*.

---

## 3. Proposed architecture (in phases)

### Phase 1 — `User` autocommand events (minimally invasive, cheap)

Fire a `User` event before/after every `fence_hl.apply` or
`highlighter.highlight_block` pass, with the block data in a small,
documented table field (analogous to `vim.v.event`):

```lua
vim.api.nvim_exec_autocmds("User", {
  pattern = "ColorMyAsciiFenceBlock",
  data = { bufnr = bufnr, block = block }, -- block: ColorMyAscii.FenceBlock
})
```

Any other plugin can register for that and paint additionally in a namespace
of **its own** — with no code needed on our side beyond firing the event.
Cost: very low (one `pcall(nvim_exec_autocmds, ...)` per block inside the
highlight pass that runs anyway). No registration overhead, no priority
management needed — consumers simply use higher/lower `priority` values in
their own extmarks.

**Recommendation: this is the first step, as soon as a concrete consumer
(e.g. markdown.nvim or an LSP adapter) needs it.**

### Phase 2 — a registry API (more control, opt-in)

Should phase 1 not suffice (e.g. because a consumer wants to suppress *our*
default painting for a block, or run with priority ahead of us):

```lua
-- color_my_ascii.api.fences
M.register_highlighter({
  name = "my-plugin",
  priority = 50,                         -- order relative to other registrants
  filter = function(block) ... end,       -- optional: which blocks
  highlight = function(bufnr, block) ... end, -- paints itself, own namespace
})
M.unregister_highlighter("my-plugin")
M.list_highlighters()
```

We call registered highlighters after our own passes (or, with a
`suppress_default = true` flag in the return value, *instead of* ours).
That is strictly more work than phase 1 (ordering, error isolation via
`pcall`, lifecycle on buffer delete) and is only worth it given real demand.

**Recommendation: only build it when a plugin actually needs more than the
event from phase 1 offers — otherwise it is dead scaffolding, like the
discarded `fence_syntax` in [lsp_integration_fence.md](lsp_integration_fence.md).**

### Phase 3 — cross-process access (RPC)

No new code needed — only documentation on how an external tool addresses a
running Neovim instance over `nvim --remote-expr` / msgpack RPC in order to
drive `require("color_my_ascii").fences.list_blocks(...)` (and, from phase
1/2 on, highlighter registration too) remotely. That already works today with
Neovim's own facilities, as soon as `M.fences` is stable (it is).

---

## 4. Open questions

- **Versioning:** should `ColorMyAscii.FenceBlock` fields get a
  `schema_version`, so external consumers can guard themselves against future
  breaking changes? Recommendation: yes, at the latest with phase 1.
- **Error isolation:** a faulty external highlighter must never bring down our
  own highlight pass — every callback/autocommand runs inside a `pcall`.
- **Performance:** external highlighters run on their own schedule; our
  `debounce_manager` covers only our own passes. With phase 1 that is the
  consumer's responsibility (document it, don't solve it).

---

## 5. Decision

**Possible — yes, with the restriction from section 2 (b).** Currently **no
concrete consumer is known**, so it is **deferred**, but ready to start:
phase 1 (`User ColorMyAsciiFenceBlock`) is small enough to introduce as soon
as a first plugin (or an RPC-driven external tool) actually needs it. Phase 2
only on demonstrated demand. Phase 3 is usable today, without us having to
build anything.
