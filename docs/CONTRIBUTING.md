# Contributing

Issues and pull requests are welcome. For major changes, please open an issue first.

## Table of content

  - [Development](#development)
  - [Add a New Language](#add-a-new-language)
  - [Add a New Character Group](#add-a-new-character-group)

---

## Development

The code is formatted with [stylua](https://github.com/JohnnyMorganz/StyLua) and
linted with [luacheck](https://github.com/lunarmodules/luacheck). Both configs live
at the repo root (`.stylua.toml`, `.luacheckrc`) and are enforced in CI
(`.github/workflows/lint.yml`) on every push and pull request.

Before opening a PR, run both locally:

```sh
stylua lua/ plugin/          # format (use --check to only verify)
luacheck lua/ plugin/        # lint
```

- **Style**: 2-space indent, single quotes, 120-column width. `stylua` owns line
  width, so `luacheck`'s length check is disabled to avoid conflicts.
- **`vim` global**: `.luacheckrc` declares `vim` as a writable global, so plugin
  code may set `vim.g.*`, `vim.bo[b].*`, etc. without warnings.

---

## Add a New Language

1. Create file: `lua/color_my_ascii/languages/NAME.lua`
2. Define keywords:
````lua
---@module 'color_my_ascii.languages.NAME'
---@type ColorMyAscii.KeywordGroup
return {
  words = { 'keyword1', 'keyword2', ... },
  unique_words = { 'unique1', 'unique2', ... },
  hl = 'Function',
}
````

3. Reload plugin

---

## Add a New Character Group

1. Create file: `lua/color_my_ascii/groups/NAME.lua`
2. Define characters:
````lua
---@module 'color_my_ascii.groups.NAME'
---@type ColorMyAscii.CharGroup
local group = {
  chars = '',
  hl = 'Keyword',
}

local chars = { '⚡', '★', '☆' }
group.chars = table.concat(chars, '')

return group
````

3. Reload plugin

---

## See Also

- [../README.md](../README.md) — project overview and quickstart
- [Supported Languages](languages.md) — the languages shipped today
