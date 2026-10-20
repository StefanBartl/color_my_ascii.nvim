---@module 'color_my_ascii.visible_range'
---@brief Restrict painting to the rows around the visible part of a buffer.
---@description
--- Opt-in (`visible_range.enable`, default off) for very large buffers: only
--- blocks, inline code and fence backgrounds that intersect the window's
--- visible rows plus `margin` rows on either side are painted; scrolling
--- past the painted rows repaints around the new position (see
--- `needs_repaint`). Buffers shorter than `min_lines`, and buffers that are
--- not shown in any window, are always painted in full.

local M = {}

local api = vim.api

---@class ColorMyAscii.RowRange
---@field first integer First row, 0-indexed, inclusive
---@field last integer Last row, 0-indexed, inclusive

---@type table<integer, ColorMyAscii.RowRange>
local painted = {}

--- The rows to paint for `bufnr`, or nil when everything should be painted.
---@param bufnr integer
---@param cfg table Plugin config (reads `visible_range`)
---@return ColorMyAscii.RowRange|nil
function M.compute(bufnr, cfg)
  local vr = cfg.visible_range
  if type(vr) ~= 'table' or not vr.enable then
    return nil
  end
  local count = api.nvim_buf_line_count(bufnr)
  if count <= (tonumber(vr.min_lines) or 0) then
    return nil
  end

  local margin = math.max(0, tonumber(vr.margin) or 0)
  local first, last
  for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
    local info = vim.fn.getwininfo(win)[1]
    if info then
      local top, bot = info.topline - 1, info.botline - 1
      first = first and math.min(first, top) or top
      last = last and math.max(last, bot) or bot
    end
  end
  if not first then
    return nil
  end
  return { first = math.max(0, first - margin), last = math.min(count - 1, last + margin) }
end

--- Whether rows `first..last` touch `range`; a nil range accepts everything.
---@param range ColorMyAscii.RowRange|nil
---@param first integer
---@param last integer
---@return boolean
function M.hits(range, first, last)
  return range == nil or (last >= range.first and first <= range.last)
end

--- Remember which rows `bufnr` was last painted for (nil = the whole buffer).
---@param bufnr integer
---@param range ColorMyAscii.RowRange|nil
---@return nil
function M.set_painted(bufnr, range)
  painted[bufnr] = range
end

--- Whether the visible rows of `bufnr` have left the painted rows, i.e. a
--- scroll needs a repaint. False when the whole buffer is painted.
---@param bufnr integer
---@param cfg table
---@return boolean
function M.needs_repaint(bufnr, cfg)
  local was = painted[bufnr]
  if not was then
    return M.compute(bufnr, cfg) ~= nil
  end
  local vr = cfg.visible_range
  if type(vr) ~= 'table' or not vr.enable then
    return true
  end
  for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
    local info = vim.fn.getwininfo(win)[1]
    if info and (info.topline - 1 < was.first and was.first > 0 or info.botline - 1 > was.last) then
      return true
    end
  end
  return false
end

--- Forget the painted range of a buffer (buffer deleted).
---@param bufnr integer
---@return nil
function M.forget(bufnr)
  painted[bufnr] = nil
end

return M
