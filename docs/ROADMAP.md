# Roadmap

No open items are recorded right now. When something is planned it goes here
as a checklist entry until it ships; a shipped item is removed from this file
and written up under [`docs/FEATURES.md`](FEATURES.md) instead of being ticked off.

---

## `docs/ROADMAP/` — design notes, audits, concepts

Everything below lives in [`docs/ROADMAP/`](ROADMAP/) and is **not** open work
unless it says so. Indexed here because a folder next to a file is easy to
miss, and these are the documents that explain *why* the plugin is shaped the
way it is.

| Document | What it is |
| --- | --- |
| [`Arch&Coding.md`](ROADMAP/Arch&Coding.md) | Architecture and coding rules, applied to this plugin. |
| [`Checklist.md`](ROADMAP/Checklist.md) | The Lua/Neovim checklist, applied to this plugin. |
| [`Zentral-Prinzipien.md`](ROADMAP/Zentral-Prinzipien.md) | The central principles, applied to this plugin. |
| [`IMPLEMENTATION_PLAN.md`](ROADMAP/IMPLEMENTATION_PLAN.md) | Implementation plan. |
| [`fence_highlighter_api.md`](ROADMAP/fence_highlighter_api.md) | Concept: an external highlighter API for fences. |
| [`lsp_integration_fence.md`](ROADMAP/lsp_integration_fence.md) | Concept: LSP and syntax integration inside fenced blocks. |

The audits share a convention: **✅ good · 🟡 partial · ❌ gap**.
Findings that were acted on are removed rather than ticked, so what is left
standing is either an open gap or a deliberate deviation with its reasoning.
