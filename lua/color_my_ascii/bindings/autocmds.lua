---@module 'color_my_ascii.bindings.autocmds'
--- Static (startup-time) autocommand registration for color_my_ascii.nvim.
--- Dynamic, buffer-scoped autocommands (TextChanged/BufDelete) are set up per-buffer
--- in lua/color_my_ascii/init.lua's setup_buffer(), since they depend on runtime state.
--- See docs/BINDINGS.md for a full cheatsheet of all registered autocommands.

local M = {}

local autocmd = require('lib.nvim.autocmd')

--- Register the plugin's static autocommands
function M.enable()
  local group = autocmd.augroup.create.clear('ColorMyAscii')

  autocmd.create({ 'FileType' }, function(args)
    require('color_my_ascii').setup_buffer(args.buf)
    -- Buffer-local :Fence command (export, ...). Independent of the highlight
    -- enable state, so fence actions work even when highlighting is toggled off.
    require('color_my_ascii.commands.fence').register(args.buf)
  end, {
    group = group,
    pattern = 'markdown',
    desc = 'Setup ASCII art highlighting + :Fence command for markdown files',
  })
end

return M
