---@module 'color_my_ascii.commands.fence.format'
--- `:Fence format` — run the language's formatter on the block content in place.
--- Formatters read the block on stdin and write the result to stdout;
--- configurable via `config.fence_format.formatters` (tag -> string[] command).
local M = {}

local api = vim.api
local util = require('color_my_ascii.commands.fence.util')

--- Built-in stdin/stdout formatters. Override/extend via config.
---@type table<string, string[]>
local FORMATTERS = {
  lua = { 'stylua', '-' },
  python = { 'black', '-q', '-' },
  py = { 'black', '-q', '-' },
  javascript = { 'prettier', '--parser', 'babel' },
  js = { 'prettier', '--parser', 'babel' },
  typescript = { 'prettier', '--parser', 'typescript' },
  ts = { 'prettier', '--parser', 'typescript' },
  json = { 'prettier', '--parser', 'json' },
  html = { 'prettier', '--parser', 'html' },
  css = { 'prettier', '--parser', 'css' },
  scss = { 'prettier', '--parser', 'scss' },
  yaml = { 'prettier', '--parser', 'yaml' },
  yml = { 'prettier', '--parser', 'yaml' },
  markdown = { 'prettier', '--parser', 'markdown' },
  md = { 'prettier', '--parser', 'markdown' },
  go = { 'gofmt' },
  sh = { 'shfmt', '-' },
  bash = { 'shfmt', '-' },
  rust = { 'rustfmt', '--emit', 'stdout' },
  rs = { 'rustfmt', '--emit', 'stdout' },
}

---@param _argv string[]
function M.run(_argv)
  if not vim.system then
    util.notify('`:Fence format` needs Neovim 0.10+ (vim.system)', vim.log.levels.WARN)
    return
  end
  local buf, block = util.current_block()
  if not block then
    util.notify('no fenced block under the cursor', vim.log.levels.WARN)
    return
  end
  local lang = (block.lang or ''):lower()
  local user = (require('color_my_ascii.config').get().fence_format or {}).formatters or {}
  local cmd = user[lang] or FORMATTERS[lang]
  if not cmd then
    util.notify(
      "no formatter configured for '" .. lang .. "' (see config.fence_format.formatters)",
      vim.log.levels.WARN
    )
    return
  end

  local content = util.content(buf, block)
  local input = table.concat(content, '\n')

  -- Anchor the interior so a slow formatter can't corrupt a shifted region.
  local ns = api.nvim_create_namespace('ColorMyAsciiFenceFormat')
  local start_id = api.nvim_buf_set_extmark(buf, ns, block.content_start, 0, {})
  local end_id = api.nvim_buf_set_extmark(buf, ns, block.content_end, 0, {})

  vim.system(vim.deepcopy(cmd), { stdin = input, text = true }, function(res)
    vim.schedule(function()
      local sp = api.nvim_buf_get_extmark_by_id(buf, ns, start_id, {})
      local ep = api.nvim_buf_get_extmark_by_id(buf, ns, end_id, {})
      pcall(api.nvim_buf_del_extmark, buf, ns, start_id)
      pcall(api.nvim_buf_del_extmark, buf, ns, end_id)

      if (res.code or 0) ~= 0 or not res.stdout or res.stdout == '' then
        util.notify('formatter failed: ' .. (res.stderr or 'non-zero exit'), vim.log.levels.ERROR)
        return
      end
      if not sp[1] or not ep[1] or ep[1] < sp[1] then
        return
      end
      local out = vim.split(res.stdout:gsub('\n$', ''), '\n')
      api.nvim_buf_set_lines(buf, sp[1], ep[1], false, out)
      util.notify('formatted ' .. lang .. ' block')
    end)
  end)
end

return M
