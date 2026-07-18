---@module 'color_my_ascii.commands.fence.wrap'
--- `:Fence wrap [lang]`   — wrap the current line or visual range in a fence.
--- `:Fence unwrap`        — remove the fence around the block under the cursor.
local M = {}

local api = vim.api
local util = require('color_my_ascii.commands.fence.util')

--- Wrap the current line (or `:'<,'>` range) in a fenced block.
---@param argv string[]
---@param ctx? table Command opts ({ range, line1, line2 })
function M.wrap(argv, ctx)
  local lang = (argv and argv[1]) or ''
  local buf = api.nvim_get_current_buf()

  local l1, l2
  if ctx and type(ctx.range) == 'number' and ctx.range > 0 then
    l1, l2 = ctx.line1, ctx.line2
  else
    l1 = api.nvim_win_get_cursor(0)[1]
    l2 = l1
  end
  if l1 > l2 then
    l1, l2 = l2, l1
  end

  -- Insert the closing fence first (higher line index) so l1 stays valid.
  api.nvim_buf_set_lines(buf, l2, l2, false, { '```' })
  api.nvim_buf_set_lines(buf, l1 - 1, l1 - 1, false, { '```' .. lang })
  util.notify(('wrapped lines %d-%d in a fence'):format(l1, l2))
end

--- Remove the fence delimiters around the block under the cursor.
---@param _argv string[]
function M.unwrap(_argv)
  local buf, block = util.current_block()
  if not block then
    util.notify('no fenced block under the cursor', vim.log.levels.WARN)
    return
  end
  -- Delete the closing fence first so open_row stays valid.
  api.nvim_buf_set_lines(buf, block.close_row, block.close_row + 1, false, {})
  api.nvim_buf_set_lines(buf, block.open_row, block.open_row + 1, false, {})
  util.notify('unwrapped fence')
end

return M
