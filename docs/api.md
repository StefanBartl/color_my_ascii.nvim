# Fence API (for plugin authors)

color_my_ascii owns robust, CommonMark-compatible fenced-block detection
(heuristic state machine + treesitter). Other plugins can consume it instead of
reimplementing fence parsing — this is how
[markdown.nvim](https://github.com/StefanBartl/markdown.nvim) implements its
"treat a `` ```markdown `` block as its own document scope" feature.

````lua
local fences = require('color_my_ascii').fences   -- available without setup()

-- Every fenced block in a buffer, in document order.
-- Each block: { open_row, close_row, content_start, content_end (0-indexed,
-- content is the half-open range [content_start, content_end)), lang,
-- fence_char, fence_len, is_ascii, fence_line, lines? }
local blocks = fences.list_blocks(bufnr, {
  lines    = 'none',       -- 'none' | 'ascii' | 'all' (collect content lines?)
  markdown = false,        -- true = only markdown-family langs
  lang     = nil,          -- string | string[] filter
  filter   = nil,          -- fun(block): boolean
})

-- The innermost block whose *interior* contains a row (0-indexed; defaults to
-- the cursor row). include_fence = true also matches the delimiter lines.
local block = fences.block_at(bufnr, row, { markdown = true })

-- Classify a fence language tag as markdown-family (markdown/md/mdx/…).
fences.is_markdown_lang('mdx')  -- true
````

Range-only queries (`lines = 'none'`) are cached per buffer `changedtick`, so
`block_at` is cheap to call on every keystroke.

---

## See Also

- [../README.md](../README.md) — project overview and quickstart
- [Commands](commands.md) — the `:Fence` user commands built on top of this API
- [Configuration](configuration.md) — full `setup()` reference
