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

-- Register documentation
local function register_help()
  local doc_path = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h") .. '/doc'

  -- Check if doc directory exists
  if vim.fn.isdirectory(doc_path) == 1 then
    -- Add to runtimepath if not already there
    local rtp = vim.opt.runtimepath:get()
    local plugin_root = vim.fn.fnamemodify(doc_path, ":h")

    local already_in_rtp = false
    for _, path in ipairs(rtp) do
      if path == plugin_root then
        already_in_rtp = true
        break
      end
    end

    if not already_in_rtp then
      vim.opt.runtimepath:append(plugin_root)
    end

    -- Generate helptags
    vim.cmd('silent! helptags ' .. vim.fn.fnameescape(doc_path))
  end
end

-- Register help on first load
register_help()

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
