---@module 'color_my_ascii.commands.fence.yank'
--- `:Fence yank [register] [--ansi]` — copy the fenced block's content
--- (without the delimiter lines) to a register. Default: unnamed `"` and
--- system `+`. `--ansi` copies the block's *applied* color_my_ascii
--- highlighting instead of plain text, as 24-bit ANSI escape codes -
--- paste-ready for a terminal or a chat that renders ANSI.
local M = {}

local util = require('color_my_ascii.commands.fence.util')

--- `:Fence yank` entry point.
---@param argv string[] Tokens after `yank`; an optional register name and/or `--ansi`, in any order.
function M.run(argv)
  local buf, block = util.current_block()
  if not block then
    util.notify('no fenced block under the cursor', vim.log.levels.WARN)
    return
  end

  local ansi = false
  local reg = nil
  for _, a in ipairs(argv or {}) do
    if a == '--ansi' then
      ansi = true
    elseif not reg then
      reg = a
    end
  end

  local text, count
  if ansi then
    text = require('color_my_ascii.highlight_export').to_ansi(buf, block)
    count = #util.content(buf, block)
  else
    local content = util.content(buf, block)
    text = table.concat(content, '\n')
    count = #content
  end

  if type(reg) == 'string' and #reg >= 1 then
    reg = reg:sub(1, 1)
    vim.fn.setreg(reg, text)
    util.notify(("yanked %d line(s)%s to register '%s'"):format(count, ansi and ' (ANSI)' or '', reg))
  else
    vim.fn.setreg('"', text)
    pcall(vim.fn.setreg, '+', text)
    util.notify(('yanked %d line(s)%s'):format(count, ansi and ' (ANSI)' or ''))
  end
end

return M
