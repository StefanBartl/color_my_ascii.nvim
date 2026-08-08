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
---@internal
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
  hover = {
    cmd = 'ColorMyAscii hover',
    desc = 'color_my_ascii: show highlight info for the character under the cursor',
  },
  fence_yank = { cmd = 'Fence yank', desc = 'color_my_ascii: yank fence content' },
  fence_open = { cmd = 'Fence open', desc = 'color_my_ascii: open fence content in a split' },
  fence_run = { cmd = 'Fence run', desc = 'color_my_ascii: run fence content' },
  fence_format = { cmd = 'Fence format', desc = 'color_my_ascii: format fence content' },
  fence_select = { cmd = 'Fence select', desc = 'color_my_ascii: select fence content' },
  fence_wrap = { cmd = 'Fence wrap', desc = 'color_my_ascii: wrap line in a fence' },
  fence_unwrap = { cmd = 'Fence unwrap', desc = 'color_my_ascii: unwrap fence under cursor' },
  fence_align = { cmd = 'Fence align', desc = 'color_my_ascii: straighten box-drawing edges in the fence' },
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
