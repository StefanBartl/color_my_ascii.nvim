---@module 'color_my_ascii.commands.fence.run'
--- `:Fence run` — execute the fenced block with its language's interpreter and
--- show stdout/stderr in a scratch split. Runners are configurable via
--- `config.fence_run.runners` (language tag -> command as string or string[]).
local M = {}

local api = vim.api
local util = require('color_my_ascii.commands.fence.util')

--- Built-in interpreters. A string is split on spaces; the temp file is appended.
---@type table<string, string|string[]>
local RUNNERS = {
  python = 'python3',
  py = 'python3',
  javascript = 'node',
  js = 'node',
  node = 'node',
  typescript = 'ts-node',
  ts = 'ts-node',
  lua = 'lua',
  bash = 'bash',
  sh = 'sh',
  zsh = 'zsh',
  fish = 'fish',
  ruby = 'ruby',
  rb = 'ruby',
  perl = 'perl',
  pl = 'perl',
  php = 'php',
  r = 'Rscript',
  julia = 'julia',
  jl = 'julia',
  go = 'go run',
  raku = 'raku',
}

--- Render an interpreter's stdout/stderr/exit-code into a scratch split.
---@internal
---@param lang string
---@param res table Completion result from `vim.system` (`stdout`/`stderr`/`code`)
local function show_output(lang, res)
  local lines = {}
  local function add(s)
    if s and s ~= '' then
      for _, l in ipairs(vim.split(s:gsub('\n$', ''), '\n')) do
        lines[#lines + 1] = l
      end
    end
  end
  add(res.stdout)
  if res.stderr and res.stderr ~= '' then
    lines[#lines + 1] = '─── stderr ───'
    add(res.stderr)
  end
  lines[#lines + 1] = ('[%s · exit %d]'):format(lang, res.code or 0)

  vim.cmd('botright split')
  local b = api.nvim_create_buf(false, true)
  api.nvim_win_set_buf(0, b)
  vim.bo[b].buftype = 'nofile'
  vim.bo[b].bufhidden = 'wipe'
  vim.bo[b].swapfile = false
  api.nvim_buf_set_lines(b, 0, -1, false, lines)
  api.nvim_win_set_height(0, math.min(#lines + 1, 15))
end

--- `:Fence run` entry point.
---@param _argv string[] Unused; `:Fence run` takes no arguments.
function M.run(_argv)
  if not vim.system then
    util.notify('`:Fence run` needs Neovim 0.10+ (vim.system)', vim.log.levels.WARN)
    return
  end
  local buf, block = util.current_block()
  if not block then
    util.notify('no fenced block under the cursor', vim.log.levels.WARN)
    return
  end
  local lang = (block.lang or ''):lower()
  local user = (require('color_my_ascii.config').get().fence_run or {}).runners or {}
  local runner = user[lang] or RUNNERS[lang]
  if not runner then
    util.notify("no runner configured for '" .. lang .. "' (see config.fence_run.runners)", vim.log.levels.WARN)
    return
  end

  local content = util.content(buf, block)
  local tmp = vim.fn.tempname() .. '.' .. util.ext_for(lang)
  vim.fn.writefile(content, tmp)

  local cmd = type(runner) == 'table' and vim.deepcopy(runner) or vim.split(runner, '%s+')
  cmd[#cmd + 1] = tmp

  util.notify('running ' .. lang .. ' …')
  vim.system(cmd, { text = true }, function(res)
    vim.schedule(function()
      pcall(vim.fn.delete, tmp)
      show_output(lang, res)
    end)
  end)
end

return M
