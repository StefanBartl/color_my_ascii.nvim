---@module 'color_my_ascii.bindings.autocmds'
--- Static (startup-time) autocommand registration for color_my_ascii.nvim.
--- Dynamic, buffer-scoped autocommands (TextChanged/BufDelete) are set up per-buffer
--- in lua/color_my_ascii/init.lua's setup_buffer(), since they depend on runtime state.
--- See docs/BINDINGS.md for a full cheatsheet of all registered autocommands.
---
--- Re-callable: the `plugin/` bootstrap calls this once with only the default
--- config (before the user's own setup() has necessarily run), so
--- lua/color_my_ascii/init.lua's M.setup() calls it again on every setup() -
--- the augroup is cleared and rebuilt each time, so a user-configured
--- `comment_ascii.filetypes` list takes effect regardless of load order
--- (same pattern as usrcmds.lua's debug-route re-registration).

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

  local ca = require('color_my_ascii.config').get().comment_ascii
  if ca and ca.enable and type(ca.filetypes) == 'table' and #ca.filetypes > 0 then
    autocmd.create({ 'FileType' }, function(args)
      require('color_my_ascii').setup_buffer(args.buf)
    end, {
      group = group,
      pattern = ca.filetypes,
      desc = 'Setup comment_ascii highlighting for configured filetypes',
    })
  end
end

return M
