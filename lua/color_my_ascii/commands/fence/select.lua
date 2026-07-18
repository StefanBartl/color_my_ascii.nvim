---@module 'color_my_ascii.commands.fence.select'
--- `:Fence select` — visually (linewise) select the fenced block's interior.
local M = {}

local api = vim.api
local util = require('color_my_ascii.commands.fence.util')

---@param _argv string[]
function M.run(_argv)
  local _, block = util.current_block()
  if not block then
    util.notify('no fenced block under the cursor', vim.log.levels.WARN)
    return
  end
  local first = block.content_start + 1 -- 1-indexed first interior line
  local last = block.content_end -- 1-indexed last interior line
  if last < first then
    util.notify('empty fenced block (nothing to select)')
    return
  end
  api.nvim_win_set_cursor(0, { first, 0 })
  vim.cmd(('normal! V%dG'):format(last))
end

return M
