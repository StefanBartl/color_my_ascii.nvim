# Integrations

## Context menu

`color_my_ascii.integrations.menu` contributes context-aware entries in the shape
[nvzone/menu](https://github.com/nvzone/menu) expects. color_my_ascii.nvim has
**no** dependency on `menu` and never opens a context menu itself; a host —
typically your own `<RightMouse>` dispatcher — composes these entries into its
own menu:

```lua
local items = require("color_my_ascii.integrations.menu").items()
-- prepend or append `items` to your own menu table, then menu.open(composed)
```

Entries appear in Markdown buffers only, mirroring where `:ColorMyAscii` and
`:Fence` are themselves active, and the `:Fence *` entries are further gated on
the cursor actually being inside a fenced block — so a right-click never offers a
fence action with nothing to apply it to. Opt out with `config.menu.enable`.

## See also

- [Requirements](requirements.md) — nvzone/menu is optional; the plugin runs fine without it.
