# Performance & Troubleshooting

## Table of content

  - [Performance](#performance)
  - [No Highlights Visible](#no-highlights-visible)
  - [Wrong Language Detected](#wrong-language-detected)
  - [Characters Shift or Duplicate While Editing](#characters-shift-or-duplicate-while-editing)
  - [Performance Issues](#performance-issues)

---

## Performance

The plugin uses:
- Extmarks for non-intrusive highlights
- Debounced updates (100ms) on text changes
- Efficient lookup tables (O(1) access)
- Lazy-loading for Markdown files

Even large documents (>1000 lines) should not cause performance issues.

**Note**: `enable_inline_code` may cause slowdowns in very large files (>5000 lines).

---

## No Highlights Visible

1. Plugin loaded?
````vim
:ColorMyAscii debug
````

2. Buffer is Markdown?
````vim
:set filetype?
````

3. Run health check
````vim
:checkhealth color_my_ascii
````

---

## Wrong Language Detected

Use explicit language specification:
````markdown
```ascii-c
int x = 42;
```
````

Or use a standard fence tag if the language is in `fence_language_map`:
````markdown
```vim
nnoremap <leader>w :w<CR>
```
````

Or adjust detection threshold:
````lua
require('color_my_ascii').setup({
  language_detection_threshold = 3,  -- Stricter
})
````

---

## Characters Shift or Duplicate While Editing

Symptom: a block renders correctly at first, then a line garbles as soon as the
cursor visits it — a character doubled, the following one swallowed, the block
cursor sitting one cell beside the character it should be on, or a one-cell gap
in the fence background at the end of a line. Typically:

````text
- ⚠️ WARNING oil (oil.nvim)      becomes      - ⚠️ WWARNINGoil (oil.nvim)
````

This is not the plugin's highlighting. It is Neovim and your terminal
disagreeing about **how many cells a character occupies**, and the plugin only
makes it visible: a line carrying many highlight spans gets repainted in
fragments, and a fragment written at an absolute column lands one cell off.

### Check it

````vim
:echo strdisplaywidth("⚠️")
````

Compare the answer with how many cells your terminal actually paints for that
character. If they differ, that is the bug — and it will reproduce with the
plugin disabled, in `nvim --clean`, as soon as anything repaints part of the
line.

### Who disagrees, and why

The usual culprits are **East Asian *Ambiguous*** codepoints, and this plugin's
subject matter is full of them: box drawing (`─ │ ┌ ┐ ├`), arrows (`← →`), and
symbols followed by the emoji variation selector U+FE0F (`⚠️ ℹ️ ▶️ ✔️`).
Their width is not fixed by Unicode — it depends on which table each side uses:

| side | knob | note |
|---|---|---|
| Neovim | `'ambiwidth'` | `single` (default) = 1 cell, `double` = 2 |
| Neovim | `'emoji'` | on (default) makes U+FE0F sequences full width |
| terminal | its own width table | WezTerm: `unicode_version` (defaults to **9**, where U+FE0F widens nothing) |

Genuinely wide characters (`✅ ❌ 😀`, CJK) are unambiguous and rarely a problem.

### Fix

Bring both sides onto the same table — **exactly one** of these, since changing
both just moves the mismatch to the other side:

````lua
-- Neovim follows the terminal (affects Neovim only)
vim.o.emoji = false        -- ambiguous + U+FE0F sequences become 1 cell
-- vim.o.ambiwidth = "double"   -- if your terminal draws box drawing wide
````

````lua
-- or: terminal follows Neovim (WezTerm; affects every TUI in it)
Config.unicode_version = 14
````

### Related limitation

`:Fence align` / `box_align` count UTF-8 codepoints, not display cells, on the
assumption that box-drawing glyphs are single-width. That holds under
`ambiwidth=single`; under `ambiwidth=double`, or with a double-width character
inside a box, an aligned box can still look crooked. Documented limitation, same
root cause.

---

## Performance Issues

Disable features:
````lua
require('color_my_ascii').setup({
  enable_function_names = false,
  enable_inline_code = false,
})
````

---

## See Also

- [../README.md](../README.md) — project overview and quickstart
- [Configuration](configuration.md) — full `setup()` reference
- [Quickstart](QUICKSTART.md) — getting started guide with its own common-issues section
