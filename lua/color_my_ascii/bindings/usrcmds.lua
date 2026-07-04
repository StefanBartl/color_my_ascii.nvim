---@module 'color_my_ascii.bindings.usrcmds'
--- User command registration for color_my_ascii.nvim.
--- See docs/BINDINGS.lua for a full cheatsheet of all registered commands.

local M = {}

local create_usercommand = vim.api.nvim_create_user_command

--- Register :ColorMyAscii command
local function register_highlight()
  create_usercommand('ColorMyAscii', function()
    require('color_my_ascii').highlight_buffer()
  end, {
    desc = 'Highlight ASCII art in current buffer',
  })
end

--- Register :ColorMyAsciiToggle command
local function register_toggle()
  create_usercommand('ColorMyAsciiToggle', function()
    require('color_my_ascii').toggle()
  end, {
    desc = 'Toggle ASCII art highlighting',
  })
end

--- Register :ColorMyAsciiDebug command
local function register_debug()
  create_usercommand('ColorMyAsciiDebug', function()
    require('color_my_ascii.commands.debug').show_debug_info()
  end, {
    desc = 'Show debug information',
  })
end

--- Register :ColorMyAsciiCheckFences command
local function register_fence_check()
  create_usercommand('ColorMyAsciiCheckFences', function()
    require('color_my_ascii.commands.fence_check').check_current_buffer()
  end, {
    desc = 'Check current buffer for unmatched fenced code blocks',
  })
end

--- Register :ColorMyAsciiShowConfig command
local function register_show_config()
  create_usercommand('ColorMyAsciiShowConfig', function()
    require('color_my_ascii.commands.config').show_config()
  end, {
    desc = 'Show current configuration',
  })
end

--- Register scheme management commands
local function register_scheme_commands()
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
local function register_ensure_blank_lines()
  create_usercommand('ColorMyAsciiEnsureBlankLines', function()
    require('color_my_ascii.commands.format').ensure_blank_lines()
  end, {
    desc = 'Ensure blank lines before and after fenced code blocks',
  })
end

--- Register all plugin user commands
function M.enable()
  -- Core commands
  register_highlight()
  register_toggle()
  register_debug()

  -- Fence checking
  register_fence_check()

  -- Configuration
  register_show_config()

  -- Scheme management
  register_scheme_commands()

  -- Formatting
  register_ensure_blank_lines()
end

return M
