---@module 'color_my_ascii.bindings.keymaps'
--- Optional, user-configurable keymaps for color_my_ascii.nvim.
--- Disabled by default (config.keymaps = false). Enable by passing a table mapping
--- action names to key sequences via setup({ keymaps = { ... } }).
--- See docs/BINDINGS.md for the full list of action names.
---
--- lib.nvim is a required dependency: the :ColorMyAscii command is built on
--- lib.nvim.bindings.usercmd.composer (see bindings/usrcmds.lua), and the
--- keymaps are declared through lib.nvim.bindings.keymap's registry. The soft
--- guard that used to sit here fell back to vim.keymap.set for a dependency
--- the plugin cannot run without anyway.

local M = {}

--- Resolve the keymap-setting function, preferring lib.nvim.bindings.keymap if installed
--- Action name -> { command, description }. `cmd` is the full :ColorMyAscii
--- invocation (subcommand included where applicable).
---@type table<string, {cmd: string, desc: string}>
local ACTIONS = {
  highlight = { cmd = 'ColorMyAscii', desc = 'highlight buffer' },
  toggle = { cmd = 'ColorMyAscii toggle', desc = 'toggle highlighting' },
  toggle_buffer = {
    cmd = 'ColorMyAscii toggle buffer',
    desc = 'toggle highlighting for this buffer',
  },
  schemes = { cmd = 'ColorMyAscii schemes pick', desc = 'switch color scheme' },
  ensure_blank_lines = { cmd = 'ColorMyAscii ensure-blank-lines', desc = 'format code blocks' },
  show_config = { cmd = 'ColorMyAscii show-config', desc = 'show config' },
  debug = { cmd = 'ColorMyAscii debug', desc = 'show debug info' },
  check_fences = { cmd = 'ColorMyAscii check-fences', desc = 'check fences' },
  fence_jump = { cmd = 'ColorMyAscii fence-jump', desc = 'jump between fence markers (%-style)' },
  hover = {
    cmd = 'ColorMyAscii hover',
    desc = 'show highlight info for the character under the cursor',
  },
  fence_yank = { cmd = 'Fence yank', desc = 'yank fence content' },
  fence_open = { cmd = 'Fence open', desc = 'open fence content in a split' },
  fence_run = { cmd = 'Fence run', desc = 'run fence content' },
  fence_format = { cmd = 'Fence format', desc = 'format fence content' },
  fence_select = { cmd = 'Fence select', desc = 'select fence content' },
  fence_wrap = { cmd = 'Fence wrap', desc = 'wrap line in a fence' },
  fence_unwrap = { cmd = 'Fence unwrap', desc = 'unwrap fence under cursor' },
  fence_align = { cmd = 'Fence align', desc = 'straighten box-drawing edges in the fence' },
  -- The one `Fence` subcommand that had no entry here. It takes optional
  -- arguments (`[path] [--open] [--replace]`); the keymap runs the bare
  -- form, which is the same thing every other entry in this table does.
  fence_export = { cmd = 'Fence export', desc = 'export fence content to a file' },
}

--- Declare and bind the user-configured keymaps.
---
--- Declared through `lib.nvim.bindings.keymap`'s registry. Every action is
--- unset by default, so naming a key is what claims it -- and a mistyped
--- action name is now *reported* rather than silently binding nothing, which
--- for a table of twenty names is the difference between noticing in seconds
--- and not noticing at all.
---@param km table<string, string>|false|nil Map of action name to key sequence
---@return Lib.Keymap.Registered[]|nil
function M.attach(km)
  if km ~= false and type(km) ~= 'table' then
    return
  end

  ---@type table<string, Lib.Keymap.Action>
  local actions = {}
  ---@type string[]
  local order = {}
  for name, spec in pairs(ACTIONS) do
    actions[name] = { rhs = '<cmd>' .. spec.cmd .. '<cr>', desc = spec.desc }
    order[#order + 1] = name
  end
  table.sort(order)

  return require('lib.nvim.bindings.keymap').register('color_my_ascii', { order = order, actions = actions }, km)
end

return M
