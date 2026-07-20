---@module 'color_my_ascii.commands.fence.open'
---@brief `:Fence open [--split|--vsplit|--tab|--edit]` — edit a fenced block in
---       a real split buffer (correct filetype -> full LSP/formatter), and sync
---       the changes back into the fence on `:w`.
---@description
--- A lightweight "otter-lite": instead of proxying LSP into the markdown buffer,
--- it opens the fence content as a temp file with the right extension, so the
--- language's LSP and tooling attach normally. The fence interior is anchored
--- with extmarks in the source buffer, so edits above the block don't break the
--- write-back mapping. The temp file is removed when its buffer is wiped.

local M = {}

local api = vim.api
local util = require('color_my_ascii.commands.fence.util')
local autocmd = require('lib.nvim.autocmd')

--- Extmark namespace for the source-buffer region anchors.
local ns = api.nvim_create_namespace('ColorMyAsciiFenceOpen')

--- Active edit sessions, keyed by the temp buffer number.
---@type table<integer, { src: integer, start_id: integer, end_id: integer, tmpfile: string }>
local sessions = {}

--- Sync the temp buffer's content back into the source fence.
---@param tbuf integer
function M.sync(tbuf)
  local s = sessions[tbuf]
  if not s or not api.nvim_buf_is_valid(s.src) then
    return
  end
  local new_lines = api.nvim_buf_get_lines(tbuf, 0, -1, false)
  local sp = api.nvim_buf_get_extmark_by_id(s.src, ns, s.start_id, {})
  local ep = api.nvim_buf_get_extmark_by_id(s.src, ns, s.end_id, {})
  if not sp[1] or not ep[1] then
    return
  end
  local srow, erow = sp[1], ep[1]
  if erow < srow then
    return
  end
  api.nvim_buf_set_lines(s.src, srow, erow, false, new_lines)
end

--- Tear down a session: delete the temp file and the region anchors.
---@param tbuf integer
function M.cleanup(tbuf)
  local s = sessions[tbuf]
  if not s then
    return
  end
  pcall(vim.fn.delete, s.tmpfile)
  if api.nvim_buf_is_valid(s.src) then
    pcall(api.nvim_buf_del_extmark, s.src, ns, s.start_id)
    pcall(api.nvim_buf_del_extmark, s.src, ns, s.end_id)
  end
  sessions[tbuf] = nil
end

---@param argv string[]
function M.run(argv)
  local buf, block = util.current_block()
  if not block then
    util.notify('no fenced block under the cursor', vim.log.levels.WARN)
    return
  end

  local open_cmd = 'vsplit'
  for _, a in ipairs(argv or {}) do
    if a == '--split' then
      open_cmd = 'split'
    elseif a == '--vsplit' then
      open_cmd = 'vsplit'
    elseif a == '--tab' then
      open_cmd = 'tabedit'
    elseif a == '--edit' then
      open_cmd = 'edit'
    end
  end

  local content = util.content(buf, block)
  local lang = block.lang or ''

  -- Anchor the interior [content_start, content_end) in the source buffer.
  local start_id = api.nvim_buf_set_extmark(buf, ns, block.content_start, 0, {})
  local end_id = api.nvim_buf_set_extmark(buf, ns, block.content_end, 0, {})

  -- Temp file with the language's extension so LSP/tooling attach.
  local tmp = vim.fn.tempname() .. '.' .. util.ext_for(lang)
  vim.fn.writefile(content, tmp)

  vim.cmd(open_cmd .. ' ' .. vim.fn.fnameescape(tmp))
  local tbuf = api.nvim_get_current_buf()
  if lang ~= '' then
    pcall(function()
      vim.bo[tbuf].filetype = util.filetype_for(lang)
    end)
  end

  sessions[tbuf] = { src = buf, start_id = start_id, end_id = end_id, tmpfile = tmp }

  -- These two autocmds are buffer-scoped (opts.buffer), which
  -- lib.nvim.autocmd.create does not support, so they stay on the raw API;
  -- only augroup creation is routed through the lib.nvim wrapper.
  local grp = autocmd.augroup.create.clear('ColorMyAsciiFenceOpen_' .. tbuf)
  api.nvim_create_autocmd('BufWritePost', {
    group = grp,
    buffer = tbuf,
    callback = function()
      M.sync(tbuf)
    end,
    desc = '[color_my_ascii] Sync fence edit back to the source buffer',
  })
  api.nvim_create_autocmd({ 'BufWipeout', 'BufDelete', 'BufUnload' }, {
    group = grp,
    buffer = tbuf,
    once = true,
    callback = function()
      M.cleanup(tbuf)
    end,
    desc = '[color_my_ascii] Clean up fence edit session',
  })

  util.notify('editing fence in split — :w syncs back to the block')
end

return M
