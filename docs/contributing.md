# Contributing

Issues and pull requests are welcome. For major changes, please open an issue first.

## Table of content

  - [Add a New Language](#add-a-new-language)
  - [Add a New Character Group](#add-a-new-character-group)

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
- [Roadmap](ROADMAP.md) — planned and considered future work
