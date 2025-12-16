---@module 'color_my_ascii.commands.format'
--- Formatting commands for markdown code blocks

local M = {}

local api = vim.api
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
  local i = 1

  while i <= line_count do
    local line = lines[i]
    local is_fence = line:match('^%s*```') or line:match('^%s*~~~')

    if is_fence then
      -- Check if this is an opening or closing fence
      local prev_line = i > 1 and lines[i - 1] or nil
      local next_line = i < line_count and lines[i + 1] or nil

      -- Add blank line before fence if missing
      if i > 1 and prev_line and prev_line ~= '' then
        table.insert(new_lines, '')
        changes = changes + 1
      end

      -- Add current fence line
      table.insert(new_lines, line)

      -- Add blank line after fence if missing
      if i < line_count and next_line and next_line ~= '' then
        i = i + 1
        table.insert(new_lines, lines[i])
        table.insert(new_lines, '')
        changes = changes + 1
      end
    else
      table.insert(new_lines, line)
    end

    i = i + 1
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
