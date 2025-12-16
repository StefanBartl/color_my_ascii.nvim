# Phase 4 Features Documentation

Complete documentation for new features in v0.3.0.

## Table of Contents

- [Custom Language Support](#custom-language-support)
- [Telescope Integration](#telescope-integration)
- [User Commands](#user-commands)
- [Examples](#examples)

---

## Custom Language Support

### Overview

Register custom programming languages at runtime without modifying plugin files. Supports hot-reload and validation.

### Basic Usage

#### Register Language Programmatically

```lua
-- Define language
local ruby = {
  words = {
    'def', 'class', 'module', 'end',
    'if', 'elsif', 'else', 'unless',
    'while', 'until', 'for', 'break', 'next',
    'return', 'yield', 'super', 'self',
  },
  unique_words = { 'def', 'elsif', 'unless' },
  hl = 'Function',
}

-- Register
local success, err = require('color_my_ascii').register_language('ruby', ruby)

if success then
  print('Ruby language registered!')
else
  print('Error: ' .. err)
end
```

#### Load from File

```lua
-- Load Ruby language from file
local success, err = require('color_my_ascii').load_language_from_file(
  '~/.config/nvim/languages/ruby.lua'
)
```

**File format** (`~/.config/nvim/languages/ruby.lua`):
```lua
---@type ColorMyAscii.KeywordGroup
return {
  words = {
    'def', 'class', 'module', 'end',
    -- ... more keywords
  },
  unique_words = { 'def', 'elsif', 'unless' },
  hl = 'Function',
}
```

### Hot-Reload

#### Manual Reload

```lua
-- Reload if file changed
local reloaded, err = require('color_my_ascii.language_registry').hot_reload(
  '~/.config/nvim/languages/ruby.lua'
)

if reloaded then
  print('Language reloaded!')
end
```

#### Automatic Watching

```lua
-- Watch directory for changes (checks every 2 seconds)
local timer = require('color_my_ascii').watch_language_directory(
  '~/.config/nvim/languages',
  2000  -- Check interval in ms
)

-- Stop watching
timer:stop()
timer:close()
```

### Language Management

#### List Languages

```lua
-- All languages
local all = require('color_my_ascii').list_languages()
print(vim.inspect(all))

-- Only user-defined
local language_registry = require('color_my_ascii.language_registry')
local user = language_registry.list_user()

-- Only built-in
local builtin = language_registry.list_builtin()
```

#### Get Language Definition

```lua
local ruby_def = require('color_my_ascii').get_language('ruby')

if ruby_def then
  print('Keywords:', #ruby_def.words)
  print('Unique:', #ruby_def.unique_words)
end
```

#### Check Registration

```lua
local language_registry = require('color_my_ascii.language_registry')
local registered, is_user = language_registry.is_registered('ruby')

if registered then
  print(is_user and 'User-defined' or 'Built-in')
end
```

#### Unregister Language

```lua
local success = require('color_my_ascii').unregister_language('ruby')
```

### Export to File

```lua
local language_registry = require('color_my_ascii.language_registry')

local success, err = language_registry.export(
  'ruby',
  '~/exported_ruby.lua'
)
```

### Validation

Language definitions are automatically validated:

```lua
-- ✓ Valid
{
  words = { 'keyword1', 'keyword2' },
  hl = 'Function',
}

-- ✗ Invalid - missing words
{
  hl = 'Function',
}

-- ✗ Invalid - empty words
{
  words = {},
  hl = 'Function',
}

-- ✗ Invalid - invalid keyword type
{
  words = { 'valid', 123 },
  hl = 'Function',
}
```

### Statistics

```lua
local language_registry = require('color_my_ascii.language_registry')
local stats = language_registry.get_stats()

print('Total languages:', stats.total_languages)
print('User languages:', stats.user_languages)
print('Built-in languages:', stats.builtin_languages)
print('Total keywords:', stats.total_keywords)
```

---

## Telescope Integration

### Requirements

```lua
-- In your package manager
{
  'nvim-telescope/telescope.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' }
}
```

### Pickers

#### Current Buffer Blocks

Show all ASCII blocks in current buffer:

```lua
require('color_my_ascii.telescope_picker').blocks()
```

**Or via command:**
```vim
:ColorMyAsciiBlocks
```

**Features:**
- Preview with syntax highlighting
- Jump to block on selection
- Line numbers displayed
- Language detection shown

#### All Buffers

Show blocks across all markdown buffers:

```lua
require('color_my_ascii.telescope_picker').blocks_all()
```

**Command:**
```vim
:ColorMyAsciiBlocksAll
```

**Features:**
- Buffer name shown
- Switch buffer and jump to block
- Preview support

#### Filter by Language

Show only blocks of a specific language:

```lua
-- Direct
require('color_my_ascii.telescope_picker').blocks_by_language('rust')

-- Interactive selector
require('color_my_ascii.telescope_picker').select_language()
```

**Commands:**
```vim
" Open language selector
:ColorMyAsciiBlocksByLanguage

" Direct filter
:ColorMyAsciiBlocksByLanguage rust
```

### Keymaps Example

```lua
-- In your Neovim config
vim.keymap.set('n', '<leader>ab', '<cmd>ColorMyAsciiBlocks<cr>', {
  desc = 'ASCII blocks (buffer)'
})

vim.keymap.set('n', '<leader>aB', '<cmd>ColorMyAsciiBlocksAll<cr>', {
  desc = 'ASCII blocks (all)'
})

vim.keymap.set('n', '<leader>al', '<cmd>ColorMyAsciiBlocksByLanguage<cr>', {
  desc = 'ASCII blocks by language'
})
```

### Custom Telescope Options

```lua
local opts = {
  layout_strategy = 'vertical',
  layout_config = {
    width = 0.9,
    height = 0.9,
  },
}

require('color_my_ascii.telescope_picker').blocks(opts)
```

---

## User Commands

### features

- [ ] Usercommand das bei ausführung wird sicherstellt, dass vor und nach jedem fenced block eine zeile abstand (leerzeile) vorhanden ist

### Language Management

#### Register Language

```vim
" Load from file
:ColorMyAsciiRegisterLanguage ruby ~/.config/nvim/languages/ruby.lua
```

#### Unregister Language

```vim
:ColorMyAsciiUnregisterLanguage ruby
```

**Tab completion** for user-defined languages.

#### List Languages

```vim
:ColorMyAsciiListLanguages
```

**Output:**
```
Registered languages:
  [BUILTIN] c
  [BUILTIN] cpp
  [USER] ruby
  [BUILTIN] lua
  ...
```

#### Language Info

```vim
:ColorMyAsciiLanguageInfo ruby
```

**Output:**
```
=== Language: ruby ===
Keywords: 45
Unique keywords: 8
Highlight: "Function"

First 10 keywords:
  def
  class
  module
  end
  if
  elsif
  ...
```

**Tab completion** for all languages.

#### Watch Directory

```vim
:ColorMyAsciiWatchLanguages ~/.config/nvim/languages
```

Enables hot-reload for all `.lua` files in directory.

#### Stop Watching

```vim
:ColorMyAsciiStopWatching
```

### Telescope Commands

```vim
" Current buffer blocks
:ColorMyAsciiBlocks

" All buffers
:ColorMyAsciiBlocksAll

" Filter by language (interactive)
:ColorMyAsciiBlocksByLanguage

" Filter by language (direct)
:ColorMyAsciiBlocksByLanguage rust
```

### Cache Management

#### Cache Statistics

```vim
:ColorMyAsciiCacheStats
```

**Output:**
```
=== Cache Statistics ===
Hits: 142
Misses: 23
Hit Rate: 86.1%
Invalidations: 18
Evictions: 5
```

#### Clear Cache

```vim
:ColorMyAsciiCacheClear
```

### Configuration

#### Show Config

```vim
:ColorMyAsciiShowConfig
```

**Output:**
```
=== Current Configuration ===
Keywords enabled: true
Language detection: true
Function names: false
Bracket highlighting: true
Inline code: true
Empty fence as ASCII: false

Languages loaded: 12
Groups loaded: 5

Debounce delays:
  Small files: 100ms
  Medium files: 200ms
  Large files: 500ms
```

---

## Examples

### Example 1: Custom Domain-Specific Language

Create DSL for a configuration language:

```lua
-- ~/.config/nvim/languages/myconfig.lua
return {
  words = {
    -- Sections
    'server', 'database', 'cache', 'logging',
    -- Properties
    'host', 'port', 'user', 'password',
    'enabled', 'disabled', 'timeout',
    -- Values
    'true', 'false', 'auto',
  },
  unique_words = { 'server', 'database' },
  hl = { fg = '#00bcd4', bold = true },
}
```

Load in config:
```lua
require('color_my_ascii').load_language_from_file(
  '~/.config/nvim/languages/myconfig.lua'
)
```

### Example 2: Hot-Reload Workflow

Directory structure:
```
~/.config/nvim/languages/
├── ruby.lua
├── kotlin.lua
└── swift.lua
```

Enable watching:
```lua
require('color_my_ascii').watch_language_directory(
  vim.fn.expand('~/.config/nvim/languages')
)
```

Now editing any `.lua` file in that directory automatically reloads it.

### Example 3: Telescope Workflow

Keymaps:
```lua
local wk = require('which-key')

wk.register({
  a = {
    name = 'ASCII',
    b = { '<cmd>ColorMyAsciiBlocks<cr>', 'Blocks (buffer)' },
    B = { '<cmd>ColorMyAsciiBlocksAll<cr>', 'Blocks (all)' },
    l = { '<cmd>ColorMyAsciiBlocksByLanguage<cr>', 'By language' },
    r = { '<cmd>ColorMyAsciiBlocksByLanguage rust<cr>', 'Rust blocks' },
  },
}, { prefix = '<leader>' })
```

Workflow:
1. Open markdown file with ASCII diagrams
2. Press `<leader>ab` → Telescope picker opens
3. Navigate with `j/k`, preview updates automatically
4. Press `<CR>` → Jump to selected block

### Example 4: Language Development Cycle

1. **Create language file:**
```lua
-- ~/new_lang.lua
return {
  words = { 'test', 'keyword' },
  hl = 'Function',
}
```

2. **Test in Neovim:**
```vim
:ColorMyAsciiRegisterLanguage testlang ~/new_lang.lua
```

3. **Verify:**
```vim
:ColorMyAsciiLanguageInfo testlang
```

4. **Make changes to file, then reload:**
```vim
:ColorMyAsciiRegisterLanguage testlang ~/new_lang.lua
```

5. **Export when satisfied:**
```lua
local language_registry = require('color_my_ascii.language_registry')
language_registry.export('testlang', '~/.config/nvim/languages/testlang.lua')
```

### Example 5: Batch Registration

Register multiple languages at once:

```lua
local languages = {
  ruby = {
    words = { 'def', 'end', 'class' },
    hl = 'Function',
  },
  kotlin = {
    words = { 'fun', 'val', 'var', 'class' },
    hl = 'Function',
  },
  swift = {
    words = { 'func', 'let', 'var', 'class' },
    hl = 'Function',
  },
}

local language_registry = require('color_my_ascii.language_registry')
local errors = language_registry.register_batch(languages)

-- Check for errors
if next(errors) then
  print('Some languages failed:')
  print(vim.inspect(errors))
else
  print('All languages registered!')
end
```

---

## Performance Notes

### Language Registration

- Registration triggers config rebuild
- Rebuilds keyword lookups (O(n*m) where n=languages, m=keywords)
- Consider batching multiple registrations

### Hot-Reload

- File stat checks are fast (O(1) per file)
- Only reloads if modification time changed
- Watching interval configurable (default 2s)

### Telescope

- Parsing only happens once per buffer
- Results cached until buffer changes
- Preview uses safe API with validation

---

## Troubleshooting

### Language Not Highlighting

**Check registration:**
```vim
:ColorMyAsciiLanguageInfo mylang
```

**Verify in blocks:**
```vim
:ColorMyAsciiBlocksByLanguage mylang
```

**Test detection:**
```lua
local language_detector = require('color_my_ascii.language_detector')
local config = require('color_my_ascii.config')

-- Get block somehow
local lang = language_detector.detect_language(bufnr, block, fence_line)
print('Detected:', lang)
```

### Telescope Not Available

```vim
:ColorMyAsciiBlocks
" Output: Module not found: telescope
```

**Solution:** Install Telescope:
```lua
{
  'nvim-telescope/telescope.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' }
}
```

### Hot-Reload Not Working

**Check watcher is running:**
```lua
print(_G.color_my_ascii_language_watcher)
-- Should print timer object
```

**Verify file changes:**
```bash
# Touch file to force modification
touch ~/.config/nvim/languages/ruby.lua
```

**Check interval:**
```lua
-- Reduce interval for faster detection
local timer = require('color_my_ascii').watch_language_directory(
  '~/.config/nvim/languages',
  500  -- Check every 500ms
)
```

---

## API Reference

### Language Registry

```lua
local registry = require('color_my_ascii.language_registry')

-- Registration
registry.register(name, definition) → success, error
registry.unregister(name) → success
registry.register_batch(definitions) → errors

-- Queries
registry.get(name) → definition
registry.is_registered(name) → registered, is_user
registry.list() → languages
registry.list_user() → languages
registry.list_builtin() → languages

-- File operations
registry.load_from_file(filepath) → success, error
registry.hot_reload(filepath) → reloaded, error
registry.export(name, filepath) → success, error

-- Watching
registry.watch_directory(directory, interval) → timer

-- Information
registry.get_stats() → stats
```

### Telescope Picker

```lua
local picker = require('color_my_ascii.telescope_picker')

-- Pickers
picker.blocks(opts)
picker.blocks_all(opts)
picker.blocks_by_language(language, opts)
picker.select_language(opts)

-- Availability
picker.is_available() → boolean
```

### Main Module Extensions

```lua
local plugin = require('color_my_ascii')

-- Language management
plugin.register_language(name, definition) → success, error
plugin.unregister_language(name) → success
plugin.get_language(name) → definition
plugin.list_languages() → languages

-- File operations
plugin.load_language_from_file(filepath) → success, error
plugin.watch_language_directory(directory, interval) → timer
```

---

## Migration from v0.2.0

No breaking changes. All v0.2.0 code continues to work.

**New features are opt-in:**
- Language registration is optional
- Telescope commands only available if Telescope installed
- No automatic watching unless explicitly enabled
