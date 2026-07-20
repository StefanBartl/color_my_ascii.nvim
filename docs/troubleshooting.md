# Performance & Troubleshooting

## Table of content

  - [Performance](#performance)
  - [No Highlights Visible](#no-highlights-visible)
  - [Wrong Language Detected](#wrong-language-detected)
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
