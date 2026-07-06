---@module 'color_my_ascii.bindings.keymaps'
--- Optional, user-configurable keymaps for color_my_ascii.nvim.
--- Disabled by default (config.keymaps = false). Enable by passing a table mapping
--- action names to key sequences via setup({ keymaps = { ... } }).
--- See docs/BINDINGS.md for the full list of action names.
---
--- Uses lib.nvim.map when available (https://github.com/StefanBartl/lib.nvim) and
--- falls back to vim.keymap.set otherwise, so lib.nvim remains an optional dependency.

local M = {}

--- Resolve the keymap-setting function, preferring lib.nvim.map if installed
---@return fun(mode: string, lhs: string, rhs: function|string, opts: table)
local function resolve_set()
  local ok, lib_map = pcall(require, 'lib.nvim.map')
  if ok then
    return lib_map
  end

  return function(mode, lhs, rhs, opts)
    vim.keymap.set(mode, lhs, rhs, vim.tbl_extend('force', { noremap = true, silent = true }, opts or {}))
  end
end

--- Action name -> { command, description }
---@type table<string, {cmd: string, desc: string}>
local ACTIONS = {
  highlight = { cmd = 'ColorMyAscii', desc = 'color_my_ascii: highlight buffer' },
  toggle = { cmd = 'ColorMyAsciiToggle', desc = 'color_my_ascii: toggle highlighting' },
  schemes = { cmd = 'ColorMyAsciiSchemes', desc = 'color_my_ascii: switch color scheme' },
  ensure_blank_lines = { cmd = 'ColorMyAsciiEnsureBlankLines', desc = 'color_my_ascii: format code blocks' },
  show_config = { cmd = 'ColorMyAsciiShowConfig', desc = 'color_my_ascii: show config' },
  debug = { cmd = 'ColorMyAsciiDebug', desc = 'color_my_ascii: show debug info' },
  check_fences = { cmd = 'ColorMyAsciiCheckFences', desc = 'color_my_ascii: check fences' },
}

--- Attach user-configured keymaps
---@param km table<string, string> Map of action name to key sequence
function M.attach(km)
  if type(km) ~= 'table' then
    return
  end

  local set = resolve_set()

  for action, lhs in pairs(km) do
    local spec = ACTIONS[action]
    if spec and type(lhs) == 'string' and lhs ~= '' then
      set('n', lhs, '<cmd>' .. spec.cmd .. '<cr>', { desc = spec.desc })
    end
  end
end

return M
