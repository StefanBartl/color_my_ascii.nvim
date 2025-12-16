---@module 'color_my_ascii'
--- Plugin initialization file for color_my_ascii.nvim
--- This file is automatically loaded by Neovim when the plugin is installed.
--- It sets up the necessary autocommands and commands for the plugin.

local api = vim.api

-- Prevent double-loading
if vim.g.loaded_color_my_ascii then
  return
end
vim.g.loaded_color_my_ascii = 1

-- Initialize plugin with default config
-- This must happen before any buffer setup
require('color_my_ascii').setup()

-- Register all commands
require('color_my_ascii.commands').register_all()

-- Create autogroup for plugin autocommands
local group = api.nvim_create_augroup('ColorMyAscii', { clear = true })

-- Setup highlighting for markdown files
api.nvim_create_autocmd({ 'FileType' }, {
  group = group,
  pattern = 'markdown',
  callback = function(args)
    require('color_my_ascii').setup_buffer(args.buf)
  end,
  desc = 'Setup ASCII art highlighting for markdown files',
})
