---@module 'color_my_ascii.bindings.usrcmds'
--- Registers :ColorMyAscii <subcommand>, one verb built via lib.nvim's
--- composer (:Verb sub … + <Tab> completion + Markdown docgen).
--- See docs/BINDINGS.md for a full cheatsheet of all registered subcommands.
---
--- Re-callable: the `inspect …`/`stats` routes only exist while
--- config.debug_enabled is true. Since composer.verb() rebuilds the whole
--- command on each call (force=true under the hood), debug/init.lua simply
--- calls M.enable() again when debug mode turns on at runtime (it is off by
--- default at plugin-load time, before the user's own setup() has run) —
--- there is no separate self-registration path to keep in sync.

local composer = require('lib.nvim.usercmd.composer')

local M = {}

--- Register all plugin user commands. Safe to call more than once (e.g. once
--- at plugin load, again from debug/init.lua once debug_enabled flips true).
function M.enable()
  local schemes = require('color_my_ascii.commands.schemes')

  local routes = {
    {
      path = { 'toggle' },
      desc = 'Toggle ASCII art highlighting',
      run = function()
        require('color_my_ascii').toggle()
      end,
    },

    {
      path = { 'debug' },
      desc = 'Show debug information',
      run = function()
        require('color_my_ascii.commands.debug').show_debug_info()
      end,
    },

    {
      path = { 'check-fences' },
      desc = 'Check current buffer for unmatched fenced code blocks',
      run = function()
        require('color_my_ascii.commands.fence_check').check_current_buffer()
      end,
    },

    {
      path = { 'show-config' },
      desc = 'Show current configuration',
      run = function()
        require('color_my_ascii.commands.config').show_config()
      end,
    },

    {
      path = { 'ensure-blank-lines' },
      desc = 'Ensure blank lines before and after fenced code blocks',
      run = function()
        require('color_my_ascii.commands.format').ensure_blank_lines()
      end,
    },

    {
      path = { 'fence-jump' },
      desc = "Jump between a fence's opening/closing delimiter (%-style); falls back to the built-in % elsewhere",
      run = function()
        require('color_my_ascii.fence_jump').percent()
      end,
    },

    {
      path = { 'schemes', 'list' },
      desc = 'List available color schemes',
      run = function()
        schemes.list_schemes()
      end,
    },
    {
      path = { 'schemes', 'switch' },
      args = { { name = 'name', type = 'STRING', values = schemes.get_scheme_names() } },
      desc = 'Switch to a different color scheme',
      run = function(ctx)
        schemes.switch_scheme(ctx.args.name)
      end,
    },
    {
      path = { 'schemes', 'pick' },
      desc = 'Pick a color scheme with Telescope',
      run = function()
        schemes.telescope_picker()
      end,
    },
  }

  if require('color_my_ascii.config').get().debug_enabled then
    vim.list_extend(routes, require('color_my_ascii.debug.commands').routes())
  end

  composer.verb('ColorMyAscii', {
    desc = 'ASCII art syntax highlighting',
    default = function()
      require('color_my_ascii').highlight_buffer()
    end,
    routes = routes,
  })
end

return M
