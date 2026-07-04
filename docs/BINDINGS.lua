--- Cheatsheet: all user commands, keymaps and autocommands defined by color_my_ascii.nvim.
--- This file is documentation only - it is not required/loaded by the plugin.

--------------------------------------------------------------------------------
-- USER COMMANDS
-- Registered in lua/color_my_ascii/bindings/usrcmds.lua
--------------------------------------------------------------------------------

local usrcmds = {
  ColorMyAscii              = 'Highlight ASCII art in current buffer',
  ColorMyAsciiToggle        = 'Toggle ASCII art highlighting',
  ColorMyAsciiDebug         = 'Show debug information',
  ColorMyAsciiShowConfig    = 'Show current configuration',
  ColorMyAsciiCheckFences   = 'Check current buffer for unmatched fenced code blocks',
  ColorMyAsciiEnsureBlankLines = 'Ensure blank lines before and after fenced code blocks',
  ColorMyAsciiListSchemes   = 'List available color schemes',
  ['ColorMyAsciiSwitchScheme <name>'] = 'Switch to a different color scheme',
  ColorMyAsciiSchemes       = 'Pick color scheme with Telescope (live preview)',
}

--------------------------------------------------------------------------------
-- KEYMAPS (all opt-in, disabled by default)
-- Registered in lua/color_my_ascii/bindings/keymaps.lua via setup({ keymaps = {...} })
-- Uses lib.nvim.map when https://github.com/StefanBartl/lib.nvim is installed,
-- falls back to vim.keymap.set otherwise. Every mapping sets `desc`, so which-key.nvim
-- picks them up automatically - no separate which-key registration needed.
--------------------------------------------------------------------------------

-- Example: enable a subset of the available actions
--
-- require('color_my_ascii').setup({
--   keymaps = {
--     highlight           = '<leader>ah',
--     toggle              = '<leader>at',
--     schemes             = '<leader>as',
--     ensure_blank_lines  = '<leader>af',
--     show_config         = '<leader>ac',
--     debug               = '<leader>ad',
--     check_fences        = '<leader>ax',
--   },
-- })

local keymap_actions = {
  highlight           = 'ColorMyAscii',
  toggle              = 'ColorMyAsciiToggle',
  schemes             = 'ColorMyAsciiSchemes',
  ensure_blank_lines  = 'ColorMyAsciiEnsureBlankLines',
  show_config         = 'ColorMyAsciiShowConfig',
  debug               = 'ColorMyAsciiDebug',
  check_fences        = 'ColorMyAsciiCheckFences',
}

--------------------------------------------------------------------------------
-- AUTOCOMMANDS
--------------------------------------------------------------------------------

local autocmds = {
  -- Static, registered once at startup in lua/color_my_ascii/bindings/autocmds.lua
  -- Augroup: ColorMyAscii
  {
    event = 'FileType',
    pattern = 'markdown',
    desc = 'Setup ASCII art highlighting for markdown files',
  },
  -- Dynamic, registered per-buffer in lua/color_my_ascii/init.lua's setup_buffer()
  -- Augroup: ColorMyAsciiBuffer_<bufnr>
  {
    event = { 'TextChanged', 'TextChangedI' },
    desc = 'Re-highlight ASCII art on text change with debouncing',
  },
  {
    event = 'BufDelete',
    desc = 'Cleanup ASCII art highlighting on buffer delete',
  },
}

return {
  usrcmds = usrcmds,
  keymap_actions = keymap_actions,
  autocmds = autocmds,
}
