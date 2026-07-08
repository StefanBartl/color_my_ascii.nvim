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
local util = require("color_my_ascii.commands.fence.util")

local function cfg()
  return require("color_my_ascii.config").get().fence_export or {}
end

--- Suggested default export path for the block.
---@param bufnr integer
---@param block table
---@return string
local function suggest_path(bufnr, block)
  local c = cfg()
  local bufname = api.nvim_buf_get_name(bufnr)
  local dir
  if c.default_dir == "cwd" or bufname == "" then
    dir = vim.fn.getcwd()
  else
    dir = vim.fn.fnamemodify(bufname, ":h")
  end
  local stem = (bufname ~= "" and vim.fn.fnamemodify(bufname, ":t:r")) or "fence"
  return dir .. "/" .. stem .. "_fence." .. util.ext_for(block.lang)
end

--- Best-effort path relative to `base` (falls back to absolute).
---@param target string
---@param base string
---@return string
local function relpath(target, base)
  target = vim.fn.fnamemodify(target, ":p"):gsub("\\", "/")
  base = vim.fn.fnamemodify(base, ":p"):gsub("\\", "/"):gsub("/$", "")
  if target:sub(1, #base + 1) == base .. "/" then
    return "./" .. target:sub(#base + 2)
  end
  return target
end

--- Replace the fenced block with a link reference to the exported file.
---@param bufnr integer
---@param block table
---@param path string
local function replace_block_with_ref(bufnr, block, path)
  local bufname = api.nvim_buf_get_name(bufnr)
  local base = bufname ~= "" and vim.fn.fnamemodify(bufname, ":h") or vim.fn.getcwd()
  local name = vim.fn.fnamemodify(path, ":t")
  local rel = relpath(path, base)
  local fmt = cfg().replace_format or "[%s](%s)"
  local ref = fmt:format(name, rel)
  api.nvim_buf_set_lines(bufnr, block.open_row, block.close_row + 1, false, { ref })
end

--- Write `content` to `path` and run the requested follow-ups.
---@param bufnr integer
---@param block table
---@param content string[]
---@param path string
---@param flags { open?: boolean, replace?: boolean }
local function write_and_finish(bufnr, block, content, path, flags)
  path = vim.fn.expand(path)
  path = vim.fn.fnamemodify(path, ":p")

  local dir = vim.fn.fnamemodify(path, ":h")
  if vim.fn.isdirectory(dir) == 0 then
    pcall(vim.fn.mkdir, dir, "p")
  end

  if vim.fn.filereadable(path) == 1 then
    local choice = vim.fn.confirm(("'%s' exists. Overwrite?"):format(vim.fn.fnamemodify(path, ":~")), "&Yes\n&No", 2)
    if choice ~= 1 then
      vim.notify("Fence export cancelled", vim.log.levels.INFO)
      return
    end
  end

  local ok = pcall(vim.fn.writefile, content, path)
  if not ok then
    vim.notify("Fence export: failed to write " .. path, vim.log.levels.ERROR)
    return
  end
  vim.notify(("Fence: exported %d line(s) to %s"):format(#content, vim.fn.fnamemodify(path, ":~:.")), vim.log.levels.INFO)

  local c = cfg()
  if flags.replace or c.replace then
    pcall(replace_block_with_ref, bufnr, block, path)
  end
  if flags.open or c.open_after then
    local open_cmd = c.open_cmd or "vsplit"
    pcall(vim.cmd, open_cmd .. " " .. vim.fn.fnameescape(path))
  end
end

--- `:Fence export` entry point.
---@param argv string[] Tokens after `export` (path + flags, in any order).
function M.run(argv)
  local flags = { open = false, replace = false }
  local path = nil
  for _, a in ipairs(argv or {}) do
    if a == "--open" then
      flags.open = true
    elseif a == "--replace" then
      flags.replace = true
    elseif a:sub(1, 2) == "--" then
      vim.notify("Fence export: unknown flag " .. a, vim.log.levels.WARN)
    elseif not path then
      path = a
    end
  end

  local bufnr = api.nvim_get_current_buf()
  local row = api.nvim_win_get_cursor(0)[1] - 1
  local block = require("color_my_ascii.api.fences").block_at(bufnr, row, { include_fence = true })
  if not block then
    vim.notify("Fence export: no fenced block under the cursor", vim.log.levels.WARN)
    return
  end

  local content = api.nvim_buf_get_lines(bufnr, block.content_start, block.content_end, false)

  if path then
    write_and_finish(bufnr, block, content, path, flags)
    return
  end

  -- No path given: prompt with the suggested default + file completion.
  vim.ui.input({
    prompt = "Export fence to: ",
    default = suggest_path(bufnr, block),
    completion = "file",
  }, function(input)
    if input == nil or vim.trim(input) == "" then
      vim.notify("Fence export cancelled", vim.log.levels.INFO)
      return
    end
    write_and_finish(bufnr, block, content, input, flags)
  end)
end

return M
