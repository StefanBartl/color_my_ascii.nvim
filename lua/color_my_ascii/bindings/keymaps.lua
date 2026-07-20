---@module 'color_my_ascii.bindings.keymaps'
--- Optional, user-configurable keymaps for color_my_ascii.nvim.
--- Disabled by default (config.keymaps = false). Enable by passing a table mapping
--- action names to key sequences via setup({ keymaps = { ... } }).
--- See docs/BINDINGS.md for the full list of action names.
---
--- lib.nvim is a required dependency (the :ColorMyAscii command itself is
--- built on lib.nvim.usercmd.composer, see bindings/usrcmds.lua); lib.nvim.map
--- specifically stays soft-guarded here, falling back to vim.keymap.set.

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

--- Action name -> { command, description }. `cmd` is the full :ColorMyAscii
--- invocation (subcommand included where applicable).
---@type table<string, {cmd: string, desc: string}>
local ACTIONS = {
  highlight = { cmd = 'ColorMyAscii', desc = 'color_my_ascii: highlight buffer' },
  toggle = { cmd = 'ColorMyAscii toggle', desc = 'color_my_ascii: toggle highlighting' },
  schemes = { cmd = 'ColorMyAscii schemes pick', desc = 'color_my_ascii: switch color scheme' },
  ensure_blank_lines = { cmd = 'ColorMyAscii ensure-blank-lines', desc = 'color_my_ascii: format code blocks' },
  show_config = { cmd = 'ColorMyAscii show-config', desc = 'color_my_ascii: show config' },
  debug = { cmd = 'ColorMyAscii debug', desc = 'color_my_ascii: show debug info' },
  check_fences = { cmd = 'ColorMyAscii check-fences', desc = 'color_my_ascii: check fences' },
  fence_jump = { cmd = 'ColorMyAscii fence-jump', desc = 'color_my_ascii: jump between fence markers (%-style)' },
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
