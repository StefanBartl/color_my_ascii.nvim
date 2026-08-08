---@module 'color_my_ascii.box_align'
---@brief Straighten misaligned box-drawing edges in a block of text.
---@description
--- Detects simple rectangular boxes (a top border, one or more interior rows
--- bounded by a left/right vertical edge, a bottom border) and widens each
--- row so its right edge lands on one common column - the box's own widest
--- row decides that column, so content is only ever padded, never cut.
---
--- Deliberately narrow scope (v1): only the box's own width is touched.
--- Directory-tree connectors (├──/└──/│ indentation) are left alone; only
--- genuine 4-sided boxes (┌─┐ / │.../ └─┘, ╔═╗/║.../╚═╝, ╭─╮/│.../╰─╯, or
--- the ASCII +-|  style) are recognized. Column math counts UTF-8 codepoints
--- (all box-drawing glyphs are single-width), not full display width, so a
--- genuinely double-width character (CJK, emoji) inside a box can still
--- throw off visual alignment - a documented limitation, not a bug.

local M = {}

local utf8_char_len = require('lib.lua.strings.utf8').char_len

local CORNERS = {
  ['┌'] = true,
  ['┐'] = true,
  ['└'] = true,
  ['┘'] = true,
  ['╔'] = true,
  ['╗'] = true,
  ['╚'] = true,
  ['╝'] = true,
  ['╭'] = true,
  ['╮'] = true,
  ['╰'] = true,
  ['╯'] = true,
  ['+'] = true,
}
local HORIZ = { ['─'] = true, ['═'] = true, ['-'] = true }
local VERT = { ['│'] = true, ['║'] = true, ['|'] = true }

---@internal
---@param line string
---@return string[] chars One entry per UTF-8 codepoint
local function to_chars(line)
  local chars = {}
  local i, n = 1, #line
  while i <= n do
    local len = utf8_char_len(line:byte(i))
    if len < 1 then
      len = 1
    end
    chars[#chars + 1] = line:sub(i, i + len - 1)
    i = i + len
  end
  return chars
end

---@internal
---@param chars string[]
---@return integer|nil idx 1-indexed position of the first non-blank char, or nil
local function first_nonblank(chars)
  for i, c in ipairs(chars) do
    if c ~= ' ' and c ~= '\t' then
      return i
    end
  end
  return nil
end

--- Whether `chars[from..]` is a valid top/bottom border: a corner, one or
--- more horizontal glyphs, a corner, then only blanks (if anything) to EOL.
---@internal
---@param chars string[]
---@param from integer
---@return integer|nil right_idx Index of the closing corner, or nil
local function border_span(chars, from)
  if not CORNERS[chars[from]] then
    return nil
  end
  local i = from + 1
  while chars[i] and HORIZ[chars[i]] do
    i = i + 1
  end
  if chars[i] and CORNERS[chars[i]] and i > from + 1 then
    for j = i + 1, #chars do
      if chars[j] ~= ' ' and chars[j] ~= '\t' then
        return nil
      end
    end
    return i
  end
  return nil
end

---@internal
---@param chars string[]
---@param from integer
---@return integer|nil idx Rightmost vertical-edge char at or after `from`, or nil
local function last_vert_from(chars, from)
  local found = nil
  for k = from, #chars do
    if VERT[chars[k]] then
      found = k
    end
  end
  return found
end

---@class ColorMyAscii.BoxSpan
---@field top integer 1-indexed row index (into the `lines_chars` array) of the top border
---@field bottom integer Row index of the bottom border
---@field left integer Char column (1-indexed) of the left edge
---@field interior integer[] Row indices strictly between top and bottom

--- Find every simple box in a block of lines (already split into char arrays).
---@internal
---@param lines_chars string[][]
---@return ColorMyAscii.BoxSpan[]
local function find_boxes(lines_chars)
  local boxes = {}
  local n = #lines_chars
  local i = 1
  while i <= n do
    local chars = lines_chars[i]
    local left = first_nonblank(chars)
    if left and border_span(chars, left) then
      local interior = {}
      local j = i + 1
      while j <= n do
        local lchars = lines_chars[j]
        if lchars[left] and VERT[lchars[left]] then
          interior[#interior + 1] = j
          j = j + 1
        else
          break
        end
      end
      if #interior > 0 and j <= n then
        local bchars = lines_chars[j]
        if first_nonblank(bchars) == left and border_span(bchars, left) then
          boxes[#boxes + 1] = { top = i, bottom = j, left = left, interior = interior }
          i = j -- continue scanning right after this box (its bottom border
          -- could double as another box's top border, e.g. stacked boxes)
        end
      end
    end
    i = i + 1
  end
  return boxes
end

--- The right-edge column this box should be widened/narrowed... only ever
--- widened... to: the widest row's own right-edge requirement.
---@internal
---@param lines_chars string[][]
---@param box ColorMyAscii.BoxSpan
---@return integer
local function box_target(lines_chars, box)
  local left = box.left
  local target = border_span(lines_chars[box.top], left) --[[@as integer]]

  local bottom_right = border_span(lines_chars[box.bottom], left)
  if bottom_right and bottom_right > target then
    target = bottom_right
  end

  for _, li in ipairs(box.interior) do
    local chars = lines_chars[li]
    local right = last_vert_from(chars, left + 1)
    local need
    if right then
      need = right
    else
      local last_nonblank = left
      for k = #chars, left + 1, -1 do
        if chars[k] ~= ' ' and chars[k] ~= '\t' then
          last_nonblank = k
          break
        end
      end
      need = last_nonblank + 2 -- +1 pad space, +1 for the new right edge
    end
    if need > target then
      target = need
    end
  end

  return target
end

---@internal
---@param chars string[]
---@param left integer
---@param right integer Current (possibly-too-narrow) right-corner index
---@param target integer
---@return string
local function rewrite_border(chars, left, right, target)
  local left_corner = chars[left]
  local right_corner = chars[right]
  local horiz = nil
  for k = left + 1, right - 1 do
    if chars[k] and HORIZ[chars[k]] then
      horiz = chars[k]
      break
    end
  end
  if not horiz then
    horiz = (left_corner == '+') and '-' or '─'
  end

  local out = {}
  for k = 1, left - 1 do
    out[#out + 1] = chars[k]
  end
  out[#out + 1] = left_corner
  for _ = left + 1, target - 1 do
    out[#out + 1] = horiz
  end
  out[#out + 1] = right_corner
  return table.concat(out)
end

---@internal
---@param chars string[]
---@param left integer
---@param target integer
---@return string
local function rewrite_interior(chars, left, target)
  local right = last_vert_from(chars, left + 1)
  local left_edge = chars[left]
  local right_edge = right and chars[right] or left_edge

  local inner = {}
  local stop = (right or (#chars + 1)) - 1
  for k = left + 1, stop do
    inner[#inner + 1] = chars[k]
  end
  while #inner > 0 and (inner[#inner] == ' ' or inner[#inner] == '\t') do
    inner[#inner] = nil
  end

  local out = {}
  for k = 1, left do
    out[#out + 1] = chars[k]
  end
  for _, c in ipairs(inner) do
    out[#out + 1] = c
  end
  local pad = target - left - 1 - #inner
  for _ = 1, pad do
    out[#out + 1] = ' '
  end
  out[#out + 1] = right_edge
  if right then
    for k = right + 1, #chars do
      out[#out + 1] = chars[k]
    end
  end
  return table.concat(out)
end

--- Straighten every simple box found in `lines`, widening rows so each box's
--- right edge lands on one common column. Rows outside a detected box (and
--- boxes with a consistent width already) are returned unchanged.
---@param lines string[]
---@return string[] result
---@return integer boxes_changed Number of boxes whose width actually changed
function M.align(lines)
  local lines_chars = {}
  for i, line in ipairs(lines) do
    lines_chars[i] = to_chars(line)
  end

  local boxes = find_boxes(lines_chars)
  local out = vim.deepcopy(lines)
  local changed = 0

  for _, box in ipairs(boxes) do
    local target = box_target(lines_chars, box)
    local top_right = border_span(lines_chars[box.top], box.left) --[[@as integer]]
    local box_changed = target ~= top_right

    if not box_changed then
      local bottom_right = border_span(lines_chars[box.bottom], box.left)
      box_changed = bottom_right ~= target
    end
    if not box_changed then
      for _, li in ipairs(box.interior) do
        local right = last_vert_from(lines_chars[li], box.left + 1)
        if right ~= target then
          box_changed = true
          break
        end
      end
    end

    if box_changed then
      changed = changed + 1
      out[box.top] = rewrite_border(lines_chars[box.top], box.left, top_right, target)
      for _, li in ipairs(box.interior) do
        out[li] = rewrite_interior(lines_chars[li], box.left, target)
      end
      local bottom_right = border_span(lines_chars[box.bottom], box.left) --[[@as integer]]
      out[box.bottom] = rewrite_border(lines_chars[box.bottom], box.left, bottom_right, target)
    end
  end

  return out, changed
end

return M
