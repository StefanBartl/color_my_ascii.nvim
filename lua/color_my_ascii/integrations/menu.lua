---@module 'color_my_ascii.integrations.menu'
---@brief Context-menu entries for nvzone/menu (soft, opt-in integration).
---@description
--- color_my_ascii.nvim does not depend on a menu plugin. It *provides* a
--- list of entries in the shape nvzone/menu expects, built with
--- `lib.nvim.contextmenu`'s helpers, and a host — typically the user's own
--- RightMouse dispatcher — composes them into its own menu, e.g.:
--- >
---   local items = require("color_my_ascii.integrations.menu").items()
---   -- prepend/append `items` to your own menu table, then menu.open(composed)
--- <
--- Markdown buffers only, mirroring where `:ColorMyAscii`/`:Fence` are
--- themselves active (`:Fence` is registered buffer-local to markdown
--- buffers only). The `:Fence *` entries are further gated on the cursor
--- actually being inside a fenced block — the same check
--- `color_my_ascii.commands.fence.util.current_block()` runs before every
--- `:Fence` subcommand — so right-click never offers a fence action with
--- nothing under the cursor to apply it to. Opt-out via `config.menu.enable`.

local contextmenu = require('lib.nvim.contextmenu')

local M = {}

--- Build the color_my_ascii.nvim menu entries for `bufnr`.
--- Returns an empty list when the integration is disabled or the buffer
--- isn't markdown, so a host can safely `vim.list_extend` it unconditionally.
---@param bufnr? integer defaults to the current buffer
---@return Lib.ContextMenu.Item[]
function M.items(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local cfg = require('color_my_ascii.config').get()
  local mcfg = cfg.menu or {}
  if mcfg.enable == false then return {} end
  if vim.bo[bufnr].filetype ~= 'markdown' then return {} end

  local _, block = require('color_my_ascii.commands.fence.util').current_block()
  local in_fence = block ~= nil

  local out = {}

  contextmenu.group(
    out,
    contextmenu.entry(true, '  Toggle ASCII highlighting', function() vim.cmd('ColorMyAscii toggle') end),
    contextmenu.entry(true, '  Switch color scheme', function() vim.cmd('ColorMyAscii schemes pick') end),
    contextmenu.entry(true, '  Highlight info for character under cursor', function() vim.cmd('ColorMyAscii hover') end)
  )

  contextmenu.group(
    out,
    contextmenu.entry(in_fence, '  Yank fence content', function() vim.cmd('Fence yank') end),
    contextmenu.entry(in_fence, '  Open fence in split', function() vim.cmd('Fence open') end),
    contextmenu.entry(in_fence, '  Run fence content', function() vim.cmd('Fence run') end)
  )

  contextmenu.group(
    out,
    contextmenu.entry(in_fence, '  Format fence', function() vim.cmd('Fence format') end),
    contextmenu.entry(in_fence, '  Straighten box-drawing edges (align)', function() vim.cmd('Fence align') end),
    contextmenu.entry(in_fence, '  Unwrap fence under cursor', function() vim.cmd('Fence unwrap') end)
  )

  -- Unlike the group above, `wrap` *creates* a fence around the current
  -- line/range -- it has no "already in a fence" precondition, so it is not
  -- gated on `in_fence` (see commands/fence/wrap.lua's M.wrap).
  contextmenu.group(
    out,
    contextmenu.entry(true, '  Wrap line in a fence', function() vim.cmd('Fence wrap') end)
  )

  return out
end

--- Convenience: the color_my_ascii.nvim entries wrapped as a single nested
--- submenu entry, for hosts that prefer a "Color My ASCII ▸" fly-out
--- instead of inline entries. Returns nil when there is nothing to show.
---@param label? string submenu label (default "  Color My ASCII")
---@param bufnr? integer
---@return Lib.ContextMenu.Item|nil
function M.submenu(label, bufnr)
  return contextmenu.submenu(label or '  Color My ASCII', M.items(bufnr))
end

return M
