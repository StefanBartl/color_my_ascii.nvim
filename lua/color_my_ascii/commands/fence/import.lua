---@module 'color_my_ascii.commands.fence.import'
--- `:Fence import <file>` — replace the fenced block's content with a file's
--- content (inverse of export; keeps a tangled file and the fence in sync).
local M = {}

local api = vim.api
local util = require("color_my_ascii.commands.fence.util")

---@param argv string[]
function M.run(argv)
  local path = argv and argv[1]
  if not path or path == "" then
    util.notify("usage: :Fence import <file>", vim.log.levels.WARN)
    return
  end
  path = vim.fn.expand(path)
  if vim.fn.filereadable(path) == 0 then
    util.notify("file not readable: " .. path, vim.log.levels.ERROR)
    return
  end
  local buf, block = util.current_block()
  if not block then
    util.notify("no fenced block under the cursor", vim.log.levels.WARN)
    return
  end
  local lines = vim.fn.readfile(path)
  api.nvim_buf_set_lines(buf, block.content_start, block.content_end, false, lines)
  util.notify(("imported %d line(s) from %s"):format(#lines, vim.fn.fnamemodify(path, ":~:.")))
end

return M
