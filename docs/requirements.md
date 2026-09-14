# Requirements

| | |
| --- | --- |
| Neovim | **0.10+** |
| [lib.nvim](https://github.com/StefanBartl/lib.nvim) | required — the `:ColorMyAscii` and `:Fence` command trees are built on it |

Optional, each detected at runtime and degrading to nothing when absent:

| | |
| --- | --- |
| A Treesitter Markdown parser | Sharper fence detection than the line-scan fallback — see [configuration.md](configuration.md) |
| [ui.nvim](https://github.com/StefanBartl/ui.nvim) | Backs `:ColorMyAscii hover`'s note popup, `:Fence export`'s confirm/input prompts, and the context-menu entries; falls back to a plain float / `vim.ui.*` when absent |
| [nvzone/menu](https://github.com/nvzone/menu) | A host for the context-menu entries — see [Integrations](integrations.md) |
| A formatter on `PATH` | `:Fence format` shells out to whatever the block's language declares |

## See also

- [Installation & Quickstart](QUICKSTART.md) — plugin managers and load-trigger variants.
- [Integrations](integrations.md) — the context-menu integration that needs nvzone/menu.
