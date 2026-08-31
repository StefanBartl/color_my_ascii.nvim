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

## Highlight read-back API (for plugin authors)

color_my_ascii's coloring lives entirely in extmarks, which means it exists
only inside the buffer: copy a block out, render it somewhere else, and the
colors are gone. This API hands the same information out **as data**, so
another plugin can reproduce the buffer's look in its own medium.

Its first consumer is [mdview.nvim](https://github.com/StefanBartl/mdview.nvim),
which paints fenced code blocks in its browser preview with exactly what the
buffer next to it shows (`browser.highlighter = "nvim"`), instead of guessing
the language again with a JavaScript highlighter.

````lua
local cma = require('color_my_ascii')          -- available without setup()
local blocks = cma.fences.list_blocks(bufnr)

-- The applied highlighting of one block: one array of runs per content row.
-- A run is a stretch of text sharing one highlight group; group = nil means
-- color_my_ascii painted nothing there. Concatenating a row's run texts
-- reproduces the row byte for byte (multi-byte characters are never split).
local rows = cma.highlight.runs_for_block(bufnr, blocks[1])
for i, runs in ipairs(rows) do            -- row i == buffer row content_start + i - 1
  for _, run in ipairs(runs) do
    if run.group then
      -- Colors as "#rrggbb", styles as booleans, `link=` chains followed.
      -- Absent attributes stay nil, so "sets no background" is
      -- distinguishable from "sets a black one".
      local attrs = cma.highlight.attrs_for_group(run.group)
      -- attrs = { fg?, bg?, bold?, italic?, underline?, strikethrough? }
    end
  end
end
````

Both functions are read-only and side-effect free; neither triggers a highlight
pass. **A block color_my_ascii has not painted yields runs whose `group` is nil
throughout** — the honest answer, and the caller's cue to fall back to whatever
it would otherwise have done. Which blocks get painted follows
`fence_language_map` in the configuration (31 language tags by default), so a
consumer should always have that fallback.

---

## See Also

- [../README.md](../README.md) — project overview and quickstart
- [Commands](commands.md) — the `:Fence` user commands built on top of this API
- [Configuration](configuration.md) — full `setup()` reference
