---@module 'color_my_ascii.commands.fence.export'
--- Extracts the fenced block under the cursor into a standalone file via
--- `:Fence export ["path"] [--open] [--replace] [--html]`.
--- Resolves the block at the cursor via the public fence API, writes its content
--- to `path` (prompted with file completion when omitted), and optionally opens
--- the new file (`--open`) and/or replaces the block with a link reference in a
--- "literate tangle" style (`--replace`). Behaviour defaults come from
--- `config.fence_export`; the flags override them per call.
--- `--html` exports the block's *applied* color_my_ascii highlighting instead
--- of plain text (`<span>` runs + a stylesheet, via `highlight_export.to_html`).

local M = {}

local api = vim.api
local util = require('color_my_ascii.commands.fence.util')

local function cfg()
  return require('color_my_ascii.config').get().fence_export or {}
end

--- Suggested default export path for the block.
---@internal
---@param bufnr integer
---@param block table
---@param ext? string Extension override (default: derived from the block's language)
---@return string
local function suggest_path(bufnr, block, ext)
  local c = cfg()
  local bufname = api.nvim_buf_get_name(bufnr)
  local dir
  if c.default_dir == 'cwd' or bufname == '' then
    dir = vim.fn.getcwd()
  else
    dir = vim.fn.fnamemodify(bufname, ':h')
  end
  local stem = (bufname ~= '' and vim.fn.fnamemodify(bufname, ':t:r')) or 'fence'
  return dir .. '/' .. stem .. '_fence.' .. (ext or util.ext_for(block.lang))
end

--- Best-effort path relative to `base` (falls back to absolute).
---@internal
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
---@internal
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
---@internal
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

--- Prompt for a path with file completion: kit.input (soft dependency, same
--- convention as confirm() above) when lib.nvim is installed -- its
--- completion = "file" now covers the cmdline-style Tab-completion this
--- needs (lib.nvim Phase 11) -- else the native vim.ui.input.
---@internal
---@param prompt string
---@param default string
---@param on_input fun(path: string|nil)  # nil on cancel or an empty submit
local function prompt_path(prompt, default, on_input)
  local ok_kit, kit = pcall(require, 'lib.nvim.ui.kit')
  if ok_kit then
    kit.input({
      prompt = prompt,
      default = default,
      completion = 'file',
      on_submit = function(path)
        on_input(vim.trim(path) ~= '' and path or nil)
      end,
      on_cancel = function()
        on_input(nil)
      end,
    })
    return
  end
  vim.ui.input({ prompt = prompt, default = default, completion = 'file' }, function(input)
    on_input((input and vim.trim(input) ~= '') and input or nil)
  end)
end

--- Actually write `content` to `path` (overwrite already confirmed if needed).
---@internal
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
    -- `vim.cmd` is a callable table, not a function: the closure form is what
    -- `pcall` takes.
    pcall(function()
      vim.cmd(open_cmd .. ' ' .. vim.fn.fnameescape(path))
    end)
  end
end

--- Write `content` to `path` and run the requested follow-ups.
---@internal
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
  local flags = { open = false, replace = false, html = false }
  local path = nil
  for _, a in ipairs(argv or {}) do
    if a == '--open' then
      flags.open = true
    elseif a == '--replace' then
      flags.replace = true
    elseif a == '--html' then
      flags.html = true
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

  local content
  if flags.html then
    local html = require('color_my_ascii.highlight_export').to_html(bufnr, block)
    content = vim.split(html, '\n', { plain = true })
  else
    content = api.nvim_buf_get_lines(bufnr, block.content_start, block.content_end, false)
  end

  if path then
    write_and_finish(bufnr, block, content, path, flags)
    return
  end

  -- No path given: prompt with the suggested default + file completion.
  local suggested = suggest_path(bufnr, block, flags.html and 'html' or nil)
  prompt_path('Export fence to: ', suggested, function(chosen_path)
    if not chosen_path then
      util.notify('export cancelled')
      return
    end
    write_and_finish(bufnr, block, content, chosen_path, flags)
  end)
end

return M
