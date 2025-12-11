---@module 'color_my_ascii'
--- Main entry point for color_my_ascii.nvim plugin.
--- This module provides the public API for highlighting ASCII art in markdown files.
local M = {}
---@type ColorMyAscii.State
local state = {
  enabled = true,
  buffers = {},
}
local config = require('color_my_ascii.config')
local parser = require('color_my_ascii.parser')
local highlighter = require('color_my_ascii.highlighter')
--- Initialize the plugin with user configuration
---@param opts? ColorMyAscii.Config User configuration options
function M.setup(opts)
  config.setup(opts)
end
--- Setup highlighting for a specific buffer
---@param bufnr integer Buffer number to setup
function M.setup_buffer(bufnr)
  if not state.enabled then
    return
  end
  -- Mark buffer as managed
  state.buffers[bufnr] = true
  -- Initial highlight
  M.highlight_buffer(bufnr)
  -- Setup autocommands for this buffer
  local group = vim.api.nvim_create_augroup('ColorMyAsciiBuffer_' .. bufnr, { clear = true })
  -- Re-highlight on text change
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    group = group,
    buffer = bufnr,
    callback = function()
      -- Debounce: clear existing timer
      if M._timer then
        M._timer:stop()
        M._timer:close()
      end
      -- Create new timer for delayed highlighting
      M._timer = vim.defer_fn(function()
        M.highlight_buffer(bufnr)
      end, 100)
    end,
    desc = 'Re-highlight ASCII art on text change',
  })
  -- Cleanup on buffer delete
  vim.api.nvim_create_autocmd('BufDelete', {
    group = group,
    buffer = bufnr,
    callback = function()
      state.buffers[bufnr] = nil
      highlighter.clear_buffer(bufnr)
    end,
    desc = 'Cleanup ASCII art highlighting on buffer delete',
  })
end
--- Highlight all ASCII blocks in the specified buffer
---@param bufnr? integer Buffer number (defaults to current buffer)
function M.highlight_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not state.enabled or not state.buffers[bufnr] then
    return
  end
  -- Clear existing highlights
  highlighter.clear_buffer(bufnr)
  -- Find all ASCII code blocks
  local blocks = parser.find_ascii_blocks(bufnr)
  -- Highlight each block
  for _, block in ipairs(blocks) do
    highlighter.highlight_block(bufnr, block)
  end
  -- Highlight inline code if enabled
  highlighter.highlight_inline_codes(bufnr)
end
--- Toggle the plugin on/off
---@return boolean enabled New state (true = enabled, false = disabled)
function M.toggle()
  state.enabled = not state.enabled
  if state.enabled then
    -- Re-enable: highlight all managed buffers
    for bufnr, _ in pairs(state.buffers) do
      M.highlight_buffer(bufnr)
    end
    vim.notify('color_my_ascii.nvim enabled', vim.log.levels.INFO)
  else
    -- Disable: clear all highlights
    for bufnr, _ in pairs(state.buffers) do
      highlighter.clear_buffer(bufnr)
    end
    vim.notify('color_my_ascii.nvim disabled', vim.log.levels.INFO)
  end
  return state.enabled
end
--- Get current plugin state
---@return ColorMyAscii.State
function M.get_state()
  return vim.deepcopy(state)
end
return M
