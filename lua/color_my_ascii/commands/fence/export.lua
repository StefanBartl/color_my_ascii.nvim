---@module 'color_my_ascii.commands.fence.export'
---@brief `:Fence export ["path"] [--open] [--replace]` — extract the fenced
---       block under the cursor into a standalone file.
---@description
--- Resolves the block at the cursor via the public fence API, writes its content
--- to `path` (prompted with file completion when omitted), and optionally opens
--- the new file (`--open`) and/or replaces the block with a link reference in a
--- "literate tangle" style (`--replace`). Behaviour defaults come from
--- `config.fence_export`; the flags override them per call.

local M = {}

local api = vim.api
local util = require('color_my_ascii.commands.fence.util')

local function cfg()
  return require('color_my_ascii.config').get().fence_export or {}
end

--- Suggested default export path for the block.
---@param bufnr integer
---@param block table
---@return string
local function suggest_path(bufnr, block)
  local c = cfg()
  local bufname = api.nvim_buf_get_name(bufnr)
  local dir
  if c.default_dir == 'cwd' or bufname == '' then
    dir = vim.fn.getcwd()
  else
    dir = vim.fn.fnamemodify(bufname, ':h')
  end
  local stem = (bufname ~= '' and vim.fn.fnamemodify(bufname, ':t:r')) or 'fence'
  return dir .. '/' .. stem .. '_fence.' .. util.ext_for(block.lang)
end

--- Best-effort path relative to `base` (falls back to absolute).
---@param target string
---@param base string
---@return string
local function relpath(target, base)
  target = vim.fn.fnamemodify(target, ':p'):gsub('\\', '/')
  base = vim.fn.fnamemodify(base, ':p'):gsub('\\', '/'):gsub('/$', '')
  if target:sub(1, #base + 1) == base .. '/' then
    return './' .. target:sub(#base + 2)
  end
  return target
end

--- Replace the fenced block with a link reference to the exported file.
---@param bufnr integer
---@param block table
---@param path string
local function replace_block_with_ref(bufnr, block, path)
  local bufname = api.nvim_buf_get_name(bufnr)
  local base = bufname ~= '' and vim.fn.fnamemodify(bufname, ':h') or vim.fn.getcwd()
  local name = vim.fn.fnamemodify(path, ':t')
  local rel = relpath(path, base)
  local fmt = cfg().replace_format or '[%s](%s)'
  local ref = fmt:format(name, rel)
  api.nvim_buf_set_lines(bufnr, block.open_row, block.close_row + 1, false, { ref })
end

--- Yes/No confirm: kit.confirm (soft dependency, matching
--- lib.nvim.fs.write.to_file's convention just below) when lib.nvim is
--- installed, else the native vim.fn.confirm.
---@param question string
---@param on_answer fun(yes: boolean)
local function confirm(question, on_answer)
  local ok_kit, kit = pcall(require, 'lib.nvim.ui.kit')
  if ok_kit then
    kit.confirm({ question = question, on_answer = on_answer })
    return
  end
  on_answer(vim.fn.confirm(question, '&Yes\n&No', 2) == 1)
end

--- Actually write `content` to `path` (overwrite already confirmed if needed).
---@param bufnr integer
---@param block table
---@param content string[]
---@param path string
---@param flags { open?: boolean, replace?: boolean }
local function write_content(bufnr, block, content, path, flags)
  -- mkdir -p + write: prefer lib.nvim.fs.write.to_file (soft dependency,
  -- matching bindings/keymaps.lua's convention) when installed; it takes a
  -- single string, so the lines are joined first. Falls back to the
  -- original mkdir+writefile sequence otherwise.
  local ok_lib_write, lib_write_to_file = pcall(require, 'lib.nvim.fs.write.to_file')
  local ok, err
  if ok_lib_write then
    ok, err = lib_write_to_file(path, table.concat(content, '\n'))
  else
    local dir = vim.fn.fnamemodify(path, ':h')
    if vim.fn.isdirectory(dir) == 0 then
      pcall(vim.fn.mkdir, dir, 'p')
    end
    ok = pcall(vim.fn.writefile, content, path)
    err = ok and nil or 'write failed'
  end
  if not ok then
    util.notify('export: failed to write ' .. path .. (err and (': ' .. err) or ''), vim.log.levels.ERROR)
    return
  end
  util.notify(('exported %d line(s) to %s'):format(#content, vim.fn.fnamemodify(path, ':~:.')))

  local c = cfg()
  if flags.replace or c.replace then
    pcall(replace_block_with_ref, bufnr, block, path)
  end
  if flags.open or c.open_after then
    local open_cmd = c.open_cmd or 'vsplit'
    pcall(vim.cmd, open_cmd .. ' ' .. vim.fn.fnameescape(path))
  end
end

--- Write `content` to `path` and run the requested follow-ups.
---@param bufnr integer
---@param block table
---@param content string[]
---@param path string
---@param flags { open?: boolean, replace?: boolean }
local function write_and_finish(bufnr, block, content, path, flags)
  path = vim.fn.expand(path)
  path = vim.fn.fnamemodify(path, ':p')

  local function do_write()
    write_content(bufnr, block, content, path, flags)
  end

  if vim.fn.filereadable(path) == 1 then
    confirm(("'%s' exists. Overwrite?"):format(vim.fn.fnamemodify(path, ':~')), function(yes)
      if not yes then
        util.notify('export cancelled')
        return
      end
      do_write()
    end)
    return
  end

  do_write()
end

--- `:Fence export` entry point.
---@param argv string[] Tokens after `export` (path + flags, in any order).
function M.run(argv)
  local flags = { open = false, replace = false }
  local path = nil
  for _, a in ipairs(argv or {}) do
    if a == '--open' then
      flags.open = true
    elseif a == '--replace' then
      flags.replace = true
    elseif a:sub(1, 2) == '--' then
      util.notify('export: unknown flag ' .. a, vim.log.levels.WARN)
    elseif not path then
      path = a
    end
  end

  local bufnr = api.nvim_get_current_buf()
  local row = api.nvim_win_get_cursor(0)[1] - 1
  local block = require('color_my_ascii.api.fences').block_at(bufnr, row, { include_fence = true })
  if not block then
    util.notify('no fenced block under the cursor', vim.log.levels.WARN)
    return
  end

  local content = api.nvim_buf_get_lines(bufnr, block.content_start, block.content_end, false)

  if path then
    write_and_finish(bufnr, block, content, path, flags)
    return
  end

  -- No path given: prompt with the suggested default + file completion.
  vim.ui.input({
    prompt = 'Export fence to: ',
    default = suggest_path(bufnr, block),
    completion = 'file',
  }, function(input)
    if input == nil or vim.trim(input) == '' then
      util.notify('export cancelled')
      return
    end
    write_and_finish(bufnr, block, content, input, flags)
  end)
end

return M
