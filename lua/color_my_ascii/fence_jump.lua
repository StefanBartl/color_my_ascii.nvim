---@module 'color_my_ascii.fence_jump'
---@brief `%`-style jump between a fenced block's opening and closing delimiter.
---@description
--- Optional motion: when the cursor sits on a fence delimiter line (the
--- ```lang opening line or its closing ``` line), jump to the matching
--- delimiter - the same mental model `%` already applies to ()/{}/[] pairs
--- (and, with matchit/vim-matchup, keyword pairs like if/end), extended to
--- fenced blocks. Built on the same `color_my_ascii.api.fences` block ranges
--- used by fence_hl.lua, so it works with any fence color_my_ascii detects
--- (heuristic scanner or treesitter), not just ```ascii-* ones.

local M = {}

--- Jump from a fence delimiter line to its counterpart, if the cursor is on one.
---@param bufnr? integer Buffer (default: current)
---@return boolean handled True if the cursor sat on a delimiter and was moved
function M.jump(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1 -- 0-indexed

  local ok, blocks = pcall(function()
    return require('color_my_ascii.api.fences').list_blocks(bufnr, { lines = 'none' })
  end)
  if not ok or type(blocks) ~= 'table' then
    return false
  end

  for _, b in ipairs(blocks) do
    if b.close_row ~= b.open_row then
      if row == b.open_row then
        vim.api.nvim_win_set_cursor(0, { b.close_row + 1, 0 })
        return true
      elseif row == b.close_row then
        vim.api.nvim_win_set_cursor(0, { b.open_row + 1, 0 })
        return true
      end
    end
  end
  return false
end

--- `%`-keymap RHS: jump if on a fence delimiter, else fall back to Neovim's
--- built-in `%` (bracket-pair matching; bypasses any other plugin's own `%`
--- mapping, e.g. matchit/vim-matchup, same as any other custom `%` override).
---@return nil
function M.percent()
  if not M.jump() then
    vim.cmd('normal! %')
  end
end

return M
