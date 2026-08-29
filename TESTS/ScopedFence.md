# What to test live

**Setup:** restart Neovim (lazy now loads `color_my_ascii` as a dependency of markdown.nvim). Check: `:checkhealth markdown_nvim` → should show `fenced_scope: enabled … provider: color_my_ascii fence API`. And `:checkhealth color_my_ascii` → the fence API plus the fence-line highlight status.

Test document (the outer fence uses 4 backticks so that the inner 3-backtick one nests cleanly):

````markdown
Doc Title
## Section A

````markdown
Inner Title
## Inner A
## Inner B
````

## Section B
````

**1. TOC scope** (`<leader>toc`)
- Put the cursor **inside** the fence → the TOC is inserted **within the block** and lists only `Inner A`/`Inner B`.
- Cursor **outside** → the outer TOC lists `Section A`/`Section B`, **not** the inner headings.

**2. Heading navigation** (`<C-f>`/`<C-p>`, and `[[`/`]]`)
- Inside the block: jumps only between inner headings, and **does not leave the block**.
- Outside (e.g. on `## Section A`): `<C-f>` **skips over** the fence and lands on `## Section B`.
- With a count: `2<C-f>` / `4<C-p>` (next/previous level-2/4 heading) — block-relative inside the block.

**3. Anchor jump** (`mj`) — cursor on a `[text](#inner-a)` link inside the block → jumps to the inner heading.

**4. Shift-all** (`<S-Right>`/`<S-Left>`) — cursor inside the block → shifts **only** the block's headings (the outer ones stay).

**5. Toggle**
- `:Markdown scope off` → everything falls back to the old behaviour (navigation then runs *into* fences). `:Markdown scope on` / `toggle` / `status`.

**6. Fold scope** (opt-in) — set `fenced_scope.operations.fold = true` in the config; a `# comment` inside a ```python block then **no longer** folds (it did before: a bug).

**7. Fence-line highlight** (color_my_ascii) — in the `color_my_ascii` `opts`:
```lua
fence_line_highlight = { enable = true, preset = "accent", apply_to = "all" }
```
→ the opening and closing line of every fence (including ` ```javascript `) get highlighted across the full width. Try the presets `subtle`/`accent`/`underline`/`bar`; override `open`/`close` with a highlight group of your own or with `{ fg=…, bg=… }`.

If something snags during the live test (above all the TOC insertion position inside the block, or the navigation boundaries with nested fences), those are the likeliest candidates for polish.
