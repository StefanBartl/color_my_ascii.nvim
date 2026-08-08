---@module 'color_my_ascii.commands.hover'
---@brief `:ColorMyAscii hover` — show what's highlighting the character/word
---@brief under the cursor, in a float near the cursor (also copied to a
---@brief register, for pasting into a bug report or a debugging session).
---@description
--- Combines two views of "why is this character colored the way it is":
---   - The *live* answer: the actual `hl_group` color_my_ascii's own extmark
---     namespace has painted at this exact buffer position right now
---     (accounts for overlaps between char/keyword/function-name highlighting
---     the same cell - whichever was painted last wins, matching what's
---     visually on screen).
---   - The *config* answer: `debug.inspect.inspect_char` - which character
---     groups this character belongs to per config, and whether it's an
---     override - independent of whether anything is actually painted right
---     now (e.g. cursor outside any ASCII block).
--- Plus, if the cursor sits on a recognized keyword, which language(s) it
--- maps to.

local M = {}

local api = vim.api
local namespace = api.nvim_create_namespace('ColorMyAscii')

--- The `hl_group` color_my_ascii's own extmarks have painted at an exact
--- buffer position, if any. Same-priority extmarks paint in insertion order,
--- so the last one covering `col` is what's actually visible.
---@param bufnr integer
---@param row integer 0-indexed
---@param col integer 0-indexed byte column
---@return string|nil hl_group
local function applied_hl_at(bufnr, row, col)
  local ok, marks = pcall(api.nvim_buf_get_extmarks, bufnr, namespace, { row, 0 }, { row, -1 }, { details = true })
  if not ok then
    return nil
  end
  local found = nil
  for _, m in ipairs(marks) do
    local mcol, details = m[3], m[4]
    local hl_group = details and details.hl_group
    if hl_group then
      local end_col = details.end_col or (mcol + 1)
      if col >= mcol and col < end_col then
        found = hl_group -- later (higher id) mark wins, matching paint order
      end
    end
  end
  return found
end

--- The single (possibly multi-byte) character at a byte column of `line`.
---@param line string
---@param col integer 0-indexed byte column
---@return string|nil char nil if `col` is past the end of the line
local function char_at(line, col)
  if col < 0 or col >= #line then
    return nil
  end
  local utf8_char_len = require('lib.lua.strings.utf8').char_len
  local len = utf8_char_len(line:byte(col + 1))
  return line:sub(col + 1, col + len)
end

--- Render a highlight spec (group name or attr table) for display.
---@param hl string|ColorMyAscii.CustomHighlight|nil
---@return string
local function hl_label(hl)
  if hl == nil then
    return 'none'
  end
  if type(hl) == 'string' then
    return hl
  end
  return vim.inspect(hl, { newline = '', indent = '' })
end

--- Best-effort "#rrggbb fg / #rrggbb bg" summary of a resolved hl_group, or
--- nil if it has neither (e.g. only bold/underline, or unresolvable).
---@param group string
---@return string|nil
local function color_summary(group)
  local ok, hl = pcall(api.nvim_get_hl, 0, { name = group, link = false })
  if not ok or not hl then
    return nil
  end
  local parts = {}
  if hl.fg then
    parts[#parts + 1] = 'fg=' .. string.format('#%06x', hl.fg)
  end
  if hl.bg then
    parts[#parts + 1] = 'bg=' .. string.format('#%06x', hl.bg)
  end
  if #parts == 0 then
    return nil
  end
  return table.concat(parts, ' ')
end

--- Gather everything to show for the cursor's current position - pure data,
--- no UI. Returns nil if the buffer/window has no current line to inspect.
---@param bufnr? integer Buffer (default: current)
---@param win? integer Window (default: current)
---@return string[]|nil lines Ready-to-display lines, or nil if there's nothing at the cursor
function M.info_at_cursor(bufnr, win)
  bufnr = bufnr or api.nvim_get_current_buf()
  win = win or api.nvim_get_current_win()

  local ok_cursor, cursor = pcall(api.nvim_win_get_cursor, win)
  if not ok_cursor then
    return nil
  end
  local row, col = cursor[1] - 1, cursor[2]

  local ok_line, line = pcall(api.nvim_buf_get_lines, bufnr, row, row + 1, false)
  if not ok_line or not line[1] then
    return nil
  end

  local char = char_at(line[1], col)
  if not char then
    return nil
  end

  local lines = {}
  local function add(s)
    lines[#lines + 1] = s
  end

  add(('Character: %q'):format(char))

  local applied = applied_hl_at(bufnr, row, col)
  if applied then
    local colors = color_summary(applied)
    add('Applied highlight: ' .. applied .. (colors and (' (' .. colors .. ')') or ''))
  else
    add('Applied highlight: none (nothing painted here right now)')
  end

  local inspect = require('color_my_ascii.debug.inspect')
  local ok_ic, ic = pcall(inspect.inspect_char, char)
  if ok_ic and ic then
    add('Config highlight: ' .. hl_label(ic.highlight) .. (ic.override and ' (override)' or ''))
    add('Char groups: ' .. (#ic.groups > 0 and table.concat(ic.groups, ', ') or 'none'))
  end

  local config = require('color_my_ascii.config')
  local word = vim.fn.expand('<cword>')
  if type(word) == 'string' and word ~= '' then
    local kw_langs = config.get_keyword_languages(word)
    if kw_langs and #kw_langs > 0 then
      add('')
      add(('Keyword %q:'):format(word))
      for _, info in ipairs(kw_langs) do
        add('  ' .. info.language .. ' -> ' .. hl_label(info.hl))
      end
    end
  end

  return lines
end

--- Show the hover float for the cursor's current position, and copy the same
--- text to the unnamed register (+ system clipboard where available) for
--- pasting elsewhere. No-op (silent) if there's nothing to show.
---@return nil
function M.show()
  local lines = M.info_at_cursor()
  if not lines then
    return
  end

  local text = table.concat(lines, '\n')
  vim.fn.setreg('"', text)
  pcall(vim.fn.setreg, '+', text)

  local ok_kit, kit = pcall(require, 'lib.nvim.ui.kit')
  if ok_kit and type(kit.note) == 'function' then
    kit.note({
      title = 'color_my_ascii',
      message = lines,
      relative = 'cursor',
    })
    return
  end

  -- Fallback: a plain scratch float, closable with q/<Esc>/<C-c>, no lib.nvim.
  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, #l)
  end
  local win = api.nvim_open_win(buf, false, {
    relative = 'cursor',
    row = 1,
    col = 0,
    width = math.max(width, 10) + 2,
    height = #lines,
    style = 'minimal',
    border = 'rounded',
  })
  for _, lhs in ipairs({ 'q', '<Esc>', '<C-c>' }) do
    vim.keymap.set('n', lhs, function()
      if api.nvim_win_is_valid(win) then
        api.nvim_win_close(win, true)
      end
    end, { buffer = buf, nowait = true, silent = true })
  end
end

return M
