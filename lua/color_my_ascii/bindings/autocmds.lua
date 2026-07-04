---@module 'color_my_ascii.bindings.autocmds'
--- Static (startup-time) autocommand registration for color_my_ascii.nvim.
--- Dynamic, buffer-scoped autocommands (TextChanged/BufDelete) are set up per-buffer
--- in lua/color_my_ascii/init.lua's setup_buffer(), since they depend on runtime state.
--- See docs/BINDINGS.lua for a full cheatsheet of all registered autocommands.

local M = {}

local api = vim.api

--- Register the plugin's static autocommands
function M.enable()
  local group = api.nvim_create_augroup('ColorMyAscii', { clear = true })

  api.nvim_create_autocmd({ 'FileType' }, {
    group = group,
    pattern = 'markdown',
    callback = function(args)
      require('color_my_ascii').setup_buffer(args.buf)
    end,
    desc = 'Setup ASCII art highlighting for markdown files',
  })
end

return M
