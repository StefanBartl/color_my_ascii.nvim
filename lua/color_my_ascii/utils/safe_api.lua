---@module 'color_my_ascii.utils.safe_api'
---@brief Safe wrappers around Neovim API calls

local M = {}

---Safely get buffer lines with validation
---@param bufnr integer
---@param start integer
---@param end_ integer
---@param strict_indexing boolean
---@return string[]|nil, string|nil
function M.buf_get_lines(bufnr, start, end_, strict_indexing)
  if type(bufnr) ~= 'number' or not vim.api.nvim_buf_is_valid(bufnr) then
    return nil, 'Invalid buffer'
  end

  local ok, result = pcall(vim.api.nvim_buf_get_lines, bufnr, start, end_, strict_indexing)
  if not ok then
    return nil, result
  end

  return result, nil
end

---Safely set extmark with validation
---@param bufnr integer
---@param ns_id integer
---@param line integer
---@param col integer
---@param opts table
---@return integer|nil, string|nil
function M.buf_set_extmark(bufnr, ns_id, line, col, opts)
  if type(bufnr) ~= 'number' or not vim.api.nvim_buf_is_valid(bufnr) then
    return nil, 'Invalid buffer'
  end

  if type(line) ~= 'number' or line < 0 then
    return nil, 'Invalid line number'
  end

  if type(col) ~= 'number' or col < 0 then
    return nil, 'Invalid column'
  end

  local ok, result = pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_id, line, col, opts)
  if not ok then
    return nil, result
  end

  return result, nil
end

---Safely clear namespace with validation
---@param bufnr integer
---@param ns_id integer
---@param line_start integer
---@param line_end integer
---@return boolean, string|nil
function M.buf_clear_namespace(bufnr, ns_id, line_start, line_end)
  if type(bufnr) ~= 'number' or not vim.api.nvim_buf_is_valid(bufnr) then
    return false, 'Invalid buffer'
  end

  local ok, err = pcall(vim.api.nvim_buf_clear_namespace, bufnr, ns_id, line_start, line_end)
  if not ok then
    return false, err
  end

  return true, nil
end

return M
