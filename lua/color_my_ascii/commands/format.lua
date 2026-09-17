---@module 'color_my_ascii.commands.format'
--- Formatting commands for markdown code blocks

local M = {}

local api = vim.api
---@type fun(msg: string, level?: integer, opts?: table)
local notify = vim.notify
local levels = vim.log.levels

--- Ensure blank lines before and after all fenced code blocks
function M.ensure_blank_lines()
  local bufnr = api.nvim_get_current_buf()
  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local line_count = #lines

  if line_count == 0 then
    notify('Empty buffer', levels.WARN)
    return
  end

  local changes = 0
  local new_lines = {}

  -- Which side a blank line belongs on depends on whether a fence opens or
  -- closes a block, so the walk has to track that. It used to treat every
  -- fence alike and, for each one, consume the *following* line before adding
  -- a blank after it -- for an opening fence that following line is the first
  -- line of content, so the blank was inserted INSIDE the block and the
  -- command mangled the very ASCII art this plugin exists to highlight.
  local in_block = false

  for i = 1, line_count do
    local line = lines[i]
    local is_fence = line:match('^%s*```') or line:match('^%s*~~~')

    if is_fence and not in_block then
      -- Opening fence: the blank line belongs before it. Looking at what was
      -- already emitted (rather than at `lines[i - 1]`) keeps this idempotent
      -- when a blank was just inserted.
      if i > 1 and new_lines[#new_lines] ~= '' then
        table.insert(new_lines, '')
        changes = changes + 1
      end
      table.insert(new_lines, line)
      in_block = true
    elseif is_fence then
      -- Closing fence: the blank line belongs after it.
      table.insert(new_lines, line)
      if i < line_count and lines[i + 1] ~= '' then
        table.insert(new_lines, '')
        changes = changes + 1
      end
      in_block = false
    else
      table.insert(new_lines, line)
    end
  end

  if changes > 0 then
    -- Apply changes
    api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
    notify(string.format('Added %d blank line(s)', changes), levels.INFO)
  else
    notify('No changes needed', levels.INFO)
  end
end

return M
