---@module 'color_my_ascii.commands'
--- User command registration and management for color_my_ascii.nvim

local M = {}

local create_usercommand = vim.api.nvim_create_user_command

--- Register all plugin commands
function M.register_all()
  -- Core commands
  M.register_highlight()
  M.register_toggle()
  M.register_debug()

  -- Fence checking
  M.register_fence_check()

  -- Configuration
  M.register_show_config()

  -- Scheme management
  M.register_scheme_commands()

  -- Formatting
  M.register_ensure_blank_lines()
end

--- Register :ColorMyAscii command
function M.register_highlight()
  create_usercommand('ColorMyAscii', function()
    require('color_my_ascii').highlight_buffer()
  end, {
    desc = 'Highlight ASCII art in current buffer',
  })
end

--- Register :ColorMyAsciiToggle command
function M.register_toggle()
  create_usercommand('ColorMyAsciiToggle', function()
    require('color_my_ascii').toggle()
  end, {
    desc = 'Toggle ASCII art highlighting',
  })
end

--- Register :ColorMyAsciiDebug command
function M.register_debug()
  create_usercommand('ColorMyAsciiDebug', function()
    require('color_my_ascii.commands.debug').show_debug_info()
  end, {
    desc = 'Show debug information',
  })
end

--- Register :ColorMyAsciiCheckFences command
function M.register_fence_check()
  create_usercommand('ColorMyAsciiCheckFences', function()
    require('color_my_ascii.commands.fence_check').check_current_buffer()
  end, {
    desc = 'Check current buffer for unmatched fenced code blocks',
  })
end

--- Register :ColorMyAsciiShowConfig command
function M.register_show_config()
  create_usercommand('ColorMyAsciiShowConfig', function()
    require('color_my_ascii.commands.config').show_config()
  end, {
    desc = 'Show current configuration',
  })
end

--- Register scheme management commands
function M.register_scheme_commands()
  local schemes = require('color_my_ascii.commands.schemes')

  -- List schemes
  create_usercommand('ColorMyAsciiListSchemes', function()
    schemes.list_schemes()
  end, {
    desc = 'List available color schemes',
  })

  -- Switch scheme
  create_usercommand('ColorMyAsciiSwitchScheme', function(opts)
    schemes.switch_scheme(opts.args)
  end, {
    nargs = 1,
    complete = function(_, _, _)
      return schemes.get_scheme_names()
    end,
    desc = 'Switch to a different color scheme',
  })

  -- Telescope picker
  create_usercommand('ColorMyAsciiSchemes', function()
    schemes.telescope_picker()
  end, {
    desc = 'Pick color scheme with Telescope',
  })
end

--- Register :ColorMyAsciiEnsureBlankLines command
function M.register_ensure_blank_lines()
  create_usercommand('ColorMyAsciiEnsureBlankLines', function()
    require('color_my_ascii.commands.format').ensure_blank_lines()
  end, {
    desc = 'Ensure blank lines before and after fenced code blocks',
  })
end

return M
