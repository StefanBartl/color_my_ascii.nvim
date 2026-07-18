---@module 'color_my_ascii.commands.fence.lang'
--- `:Fence lang <language>` — change the language tag of the fence under the cursor.
local M = {}

local api = vim.api
local util = require('color_my_ascii.commands.fence.util')

---@param argv string[]
function M.run(argv)
  local newlang = argv and argv[1]
  if not newlang or newlang == '' then
    util.notify('usage: :Fence lang <language>', vim.log.levels.WARN)
    return
  end
  local buf, block = util.current_block()
  if not block then
    util.notify('no fenced block under the cursor', vim.log.levels.WARN)
    return
  end
  local open_line = api.nvim_buf_get_lines(buf, block.open_row, block.open_row + 1, false)[1] or ''
  -- Keep the indent + fence delimiters, replace the info string.
  local delim = open_line:match('^%s*[`~]+')
  if not delim then
    util.notify('could not parse the opening fence line', vim.log.levels.WARN)
    return
  end
  api.nvim_buf_set_lines(buf, block.open_row, block.open_row + 1, false, { delim .. newlang })
  util.notify('fence language -> ' .. newlang)
end

return M
