---@module 'color_my_ascii.commands.fence.yank'
--- `:Fence yank [register]` — copy the fenced block's content (without the
--- delimiter lines) to a register. Default: unnamed `"` and system `+`.
local M = {}

local util = require('color_my_ascii.commands.fence.util')

---@param argv string[]
function M.run(argv)
  local buf, block = util.current_block()
  if not block then
    util.notify('no fenced block under the cursor', vim.log.levels.WARN)
    return
  end
  local content = util.content(buf, block)
  local text = table.concat(content, '\n')

  local reg = argv and argv[1]
  if type(reg) == 'string' and #reg >= 1 then
    reg = reg:sub(1, 1)
    vim.fn.setreg(reg, text)
    util.notify(("yanked %d line(s) to register '%s'"):format(#content, reg))
  else
    vim.fn.setreg('"', text)
    pcall(vim.fn.setreg, '+', text)
    util.notify(('yanked %d line(s)'):format(#content))
  end
end

return M
