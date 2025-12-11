---@module 'color_my_ascii'
--- Plugin initialization file for color_my_ascii.nvim
--- This file is automatically loaded by Neovim when the plugin is installed.
--- It sets up the necessary autocommands and commands for the plugin.

-- Prevent double-loading
if vim.g.loaded_color_my_ascii then
  return
end
vim.g.loaded_color_my_ascii = 1

-- Initialize plugin with default config
-- This must happen before any buffer setup
require('color_my_ascii').setup()

-- Create user command to manually trigger highlighting
vim.api.nvim_create_user_command('ColorMyAscii', function()
  require('color_my_ascii').highlight_buffer()
end, {
  desc = 'Highlight ASCII art in current buffer',
})

-- Create user command to toggle the plugin
vim.api.nvim_create_user_command('ColorMyAsciiToggle', function()
  require('color_my_ascii').toggle()
end, {
  desc = 'Toggle ASCII art highlighting',
})

-- Create debug command to show loaded configuration
vim.api.nvim_create_user_command('ColorMyAsciiDebug', function()
  local config = require('color_my_ascii.config')
  local cfg = config.get()

  local langs = vim.tbl_keys(cfg.keywords)
  table.sort(langs)

  local groups = vim.tbl_keys(cfg.groups)
  table.sort(groups)

  local char_count = vim.tbl_count(config.char_lookup)
  local keyword_count = vim.tbl_count(config.keyword_lookup)

  print('=== color_my_ascii.nvim Debug Info ===')
  print('Languages loaded: ' .. #langs)
  print('  ' .. table.concat(langs, ', '))
  print('Groups loaded: ' .. #groups)
  print('  ' .. table.concat(groups, ', '))
  print('Character lookup entries: ' .. char_count)
  print('Keyword lookup entries: ' .. keyword_count)
  print('Language detection: ' .. tostring(cfg.enable_language_detection))
  print('Keywords enabled: ' .. tostring(cfg.enable_keywords))
end, {
  desc = 'Show debug information about color_my_ascii configuration',
})

-- Create autogroup for plugin autocommands
local group = vim.api.nvim_create_augroup('ColorMyAscii', { clear = true })

-- Setup highlighting for markdown files
vim.api.nvim_create_autocmd({ 'FileType' }, {
  group = group,
  pattern = 'markdown',
  callback = function(args)
    require('color_my_ascii').setup_buffer(args.buf)
  end,
  desc = 'Setup ASCII art highlighting for markdown files',
})
