---@module 'color_my_ascii.highlight_export'
---@brief Serialize a fenced block's *applied* highlighting to HTML or ANSI.
---@description
--- color_my_ascii's own coloring lives entirely in extmarks (the "ColorMyAscii"
--- namespace) and disappears the moment a block is copied out of the buffer.
--- This module re-reads those extmarks over a block's content rows and
--- reconstructs the same colors as either:
---   - HTML: `<span class="cma-<Group>">` runs + a companion stylesheet, or
---   - ANSI: 24-bit truecolor escape codes, for pasting into a terminal or
---     a chat that renders ANSI.
--- Consumed by `:Fence export --html` and `:Fence yank --ansi`.

local M = {}

local api = vim.api
local namespace = api.nvim_create_namespace('ColorMyAscii')

--- Per-line, per-column effective hl_group for [start_row, end_row). Extmarks
--- are iterated in the order the API returns them (insertion/id order, which
--- matches paint order since every color_my_ascii extmark uses the same
--- fixed priority); a later write at the same column overrides an earlier
--- one, mirroring how overlapping same-priority extmarks render on screen.
---@param bufnr integer
---@param start_row integer 0-indexed inclusive
---@param end_row integer 0-indexed exclusive
---@return table<integer, table<integer, string>> row -> col -> hl_group
local function collect_hl_map(bufnr, start_row, end_row)
  local ok, marks = pcall(
    api.nvim_buf_get_extmarks,
    bufnr,
    namespace,
    { start_row, 0 },
    { end_row, -1 },
    { details = true }
  )
  local map = {}
  if not ok then
    return map
  end
  for _, m in ipairs(marks) do
    local row, col, details = m[2], m[3], m[4]
    local hl_group = details and details.hl_group
    if hl_group and row >= start_row and row < end_row then
      local end_col = details.end_col or (col + 1)
      map[row] = map[row] or {}
      for c = col, end_col - 1 do
        map[row][c] = hl_group
      end
    end
  end
  return map
end

---@class ColorMyAscii.HlRun
---@field text string
---@field group string|nil nil = no color_my_ascii highlight on this run

--- Build per-content-row runs of contiguous text sharing the same effective
--- hl_group (nil = unhighlighted), byte-column aligned so multi-byte UTF-8
--- characters are never split (extmark ranges are always char-aligned).
---@param bufnr integer
---@param block ColorMyAscii.FenceBlock
---@return ColorMyAscii.HlRun[][] one runs-array per content row
function M.runs_for_block(bufnr, block)
  local lines = api.nvim_buf_get_lines(bufnr, block.content_start, block.content_end, false)
  local hl_map = collect_hl_map(bufnr, block.content_start, block.content_end)

  local out = {}
  for i, line in ipairs(lines) do
    local row = block.content_start + i - 1
    local row_map = hl_map[row] or {}
    local n = #line
    local runs = {}
    if n == 0 then
      runs[1] = { text = '', group = nil }
    else
      local col = 0
      while col < n do
        local group = row_map[col]
        local run_start = col
        col = col + 1
        while col < n and row_map[col] == group do
          col = col + 1
        end
        runs[#runs + 1] = { text = line:sub(run_start + 1, col), group = group }
      end
    end
    out[#out + 1] = runs
  end
  return out
end

--- Resolve a highlight group to its effective attributes, following links.
---@param name string
---@return table attrs fg?/bg? (0xRRGGBB integers), bold?/italic?/underline?/strikethrough? (booleans)
local function resolve_attrs(name)
  local ok, hl = pcall(api.nvim_get_hl, 0, { name = name, link = false })
  return (ok and hl) or {}
end

---@param n integer 0xRRGGBB
---@return string "#rrggbb"
local function int_to_hex(n)
  return string.format('#%06x', n)
end

---@param n integer 0xRRGGBB
---@return integer r
---@return integer g
---@return integer b
local function int_to_rgb(n)
  return math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256
end

--- Sanitize a highlight-group name into a CSS class-name-safe token.
---@param group string
---@return string
local function css_token(group)
  return (group:gsub('[^%w_-]', '_'))
end

local HTML_ESCAPE = { ['&'] = '&amp;', ['<'] = '&lt;', ['>'] = '&gt;' }

---@param text string
---@return string
local function html_escape(text)
  return (text:gsub('[&<>]', HTML_ESCAPE))
end

--- Render a block's applied highlighting as a standalone HTML fragment: a
--- `<pre>` block using `<span class="cma-<Group>">` runs, plus the `<style>`
--- block defining every class actually used (only the groups the block uses,
--- not the whole plugin palette).
---@param bufnr integer
---@param block ColorMyAscii.FenceBlock
---@return string html
function M.to_html(bufnr, block)
  local runs_per_line = M.runs_for_block(bufnr, block)

  local seen = {}
  local css_rules = {}
  local body_lines = {}

  for _, runs in ipairs(runs_per_line) do
    local parts = {}
    for _, run in ipairs(runs) do
      local text = html_escape(run.text)
      if run.group then
        local token = css_token(run.group)
        if not seen[run.group] then
          seen[run.group] = true
          local attrs = resolve_attrs(run.group)
          local decls = {}
          if attrs.fg then
            decls[#decls + 1] = 'color:' .. int_to_hex(attrs.fg)
          end
          if attrs.bg then
            decls[#decls + 1] = 'background-color:' .. int_to_hex(attrs.bg)
          end
          if attrs.bold then
            decls[#decls + 1] = 'font-weight:bold'
          end
          if attrs.italic then
            decls[#decls + 1] = 'font-style:italic'
          end
          if attrs.underline then
            decls[#decls + 1] = 'text-decoration:underline'
          end
          if attrs.strikethrough then
            decls[#decls + 1] = 'text-decoration:line-through'
          end
          if #decls > 0 then
            css_rules[#css_rules + 1] = string.format('.cma-%s{%s}', token, table.concat(decls, ';'))
          end
        end
        parts[#parts + 1] = string.format('<span class="cma-%s">%s</span>', token, text)
      else
        parts[#parts + 1] = text
      end
    end
    body_lines[#body_lines + 1] = table.concat(parts)
  end

  return table.concat({
    '<!DOCTYPE html>',
    '<html>',
    '<head>',
    '<meta charset="UTF-8">',
    '<style>',
    'pre.cma-fence{background:#1e1e1e;color:#d4d4d4;padding:1em;font-family:monospace;white-space:pre;}',
    table.concat(css_rules, '\n'),
    '</style>',
    '</head>',
    '<body>',
    '<pre class="cma-fence">' .. table.concat(body_lines, '\n') .. '</pre>',
    '</body>',
    '</html>',
  }, '\n')
end

--- Render a block's applied highlighting as 24-bit-truecolor ANSI escape
--- codes - paste-ready for a terminal or a chat that renders ANSI.
---@param bufnr integer
---@param block ColorMyAscii.FenceBlock
---@return string ansi_text
function M.to_ansi(bufnr, block)
  local runs_per_line = M.runs_for_block(bufnr, block)
  local ESC = string.char(27)
  local RESET = ESC .. '[0m'

  local out_lines = {}
  for _, runs in ipairs(runs_per_line) do
    local parts = {}
    for _, run in ipairs(runs) do
      if run.group then
        local attrs = resolve_attrs(run.group)
        local codes = {}
        if attrs.bold then
          codes[#codes + 1] = '1'
        end
        if attrs.italic then
          codes[#codes + 1] = '3'
        end
        if attrs.underline then
          codes[#codes + 1] = '4'
        end
        if attrs.fg then
          local r, g, b = int_to_rgb(attrs.fg)
          codes[#codes + 1] = string.format('38;2;%d;%d;%d', r, g, b)
        end
        if attrs.bg then
          local r, g, b = int_to_rgb(attrs.bg)
          codes[#codes + 1] = string.format('48;2;%d;%d;%d', r, g, b)
        end
        if #codes > 0 then
          parts[#parts + 1] = ESC .. '[' .. table.concat(codes, ';') .. 'm' .. run.text .. RESET
        else
          parts[#parts + 1] = run.text
        end
      else
        parts[#parts + 1] = run.text
      end
    end
    out_lines[#out_lines + 1] = table.concat(parts)
  end

  return table.concat(out_lines, '\n')
end

return M
