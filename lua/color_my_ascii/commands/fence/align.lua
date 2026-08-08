---@module 'color_my_ascii.commands.fence.align'
--- `:Fence align` — straighten misaligned box-drawing edges in the block
--- under the cursor. Widens rows only (never truncates content); a normal
--- buffer edit, so `u` undoes it like any other change. See
--- `color_my_ascii.box_align` for the detection/rewrite algorithm.

local M = {}

local api = vim.api
local util = require('color_my_ascii.commands.fence.util')

--- `:Fence align` entry point.
---@param _argv string[] Unused (no flags yet)
function M.run(_argv)
  local buf, block = util.current_block()
  if not block then
    util.notify('no fenced block under the cursor', vim.log.levels.WARN)
    return
  end

  local content = util.content(buf, block)
  local aligned, changed = require('color_my_ascii.box_align').align(content)

  if changed == 0 then
    util.notify('no misaligned boxes found')
    return
  end

  api.nvim_buf_set_lines(buf, block.content_start, block.content_end, false, aligned)
  util.notify(('aligned %d box(es)'):format(changed))
end

return M
