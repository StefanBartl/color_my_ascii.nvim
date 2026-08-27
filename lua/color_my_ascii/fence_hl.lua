---@module 'color_my_ascii.fence_hl'
--- Full-line highlight of fenced-block delimiter lines and interior.
---
--- Optional feature: paints the opening (```lang) and closing (```) line
--- of fenced code blocks, as a visual boundary. Extmarks live in their own
--- namespace so they can be refreshed/cleared independently of the ASCII
--- character highlighting. The fill is a `line_hl_group` extmark (covers every
--- character cell and blank rows alike); by default (`respect_indent`) the
--- block's own indentation on the left and `right_pad` columns off the window's
--- right edge are then carved back to `Normal` so the paint reads as a rectangle
--- from the opening fence's first backtick. `respect_indent = false` keeps the
--- bare full-line `line_hl_group`.
---
--- Which blocks are painted is driven by `apply_to` ("all" fenced blocks or only
--- "ascii" ones); the look by `preset` plus optional per-delimiter `open`/`close`
--- overrides. Overrides accept an existing highlight-group name (string) or an
--- attribute table forwarded to nvim_set_hl.
---
--- A second, independent sub-feature (`fence_content_highlight`) paints the
--- block *interior* (every row between the delimiters) the same way (its own
--- `respect_indent`), shaded
--- darker/lighter than the resolved delimiter color so the whole block reads
--- as one region while staying visually distinct from its boundary.

local M = {}

local api = vim.api

--- Dedicated namespace, kept separate from the character-highlight namespace so
--- fence lines survive/refresh on their own schedule.
local ns = api.nvim_create_namespace('ColorMyAsciiFenceLine')

--- Resolved highlight group names set up in M.setup_hl.
local OPEN_GROUP = 'ColorMyAsciiFenceOpen'
local CLOSE_GROUP = 'ColorMyAsciiFenceClose'
local CONTENT_GROUP = 'ColorMyAsciiFenceContent'

--- Generic, theme-adaptive presets: link to widely-available built-in groups so
--- the look follows the colorscheme instead of hardcoding colors.
---@type table<string, ColorMyAscii.CustomHighlight>
local PRESETS = {
  subtle = { link = 'CursorLine' },
  accent = { link = 'Visual' },
  underline = { underline = true },
  bar = { link = 'ColorColumn' },
}

--- Resolve a preset NAME (no per-delimiter override) to a highlight definition:
---   "auto"          -> the current colorscheme's theme preset, else "subtle"
---   generic name    -> subtle | accent | underline | bar
---   theme name      -> the matching hand-tuned theme preset (see theme_presets)
---   anything else   -> "subtle"
---@internal
---@param preset string
---@return ColorMyAscii.CustomHighlight
local function base_preset(preset)
  local themes = require('color_my_ascii.theme_presets')
  if preset == 'auto' then
    return themes.resolve_auto() or PRESETS.subtle
  end
  if PRESETS[preset] then
    return PRESETS[preset]
  end
  if themes.is_theme(preset) then
    return themes.presets[preset]
  end
  return PRESETS.subtle
end

--- Resolve a per-delimiter spec into a highlight definition.
--- string override -> link to that existing group; table override -> attrs;
--- nil -> fall back to the resolved preset.
---@internal
---@param override string|ColorMyAscii.CustomHighlight|nil
---@param preset string
---@return table hl A table suitable for nvim_set_hl
local function resolve_spec(override, preset)
  if type(override) == 'string' then
    return { link = override }
  elseif type(override) == 'table' then
    return override
  end
  return base_preset(preset)
end

--- Best-effort resolution of a highlight group's background to a "#rrggbb"
--- string, following one `link` hop and finally falling back to "Normal".
---@internal
---@param name string
---@return string|nil hex
local function group_bg_hex(name)
  local ok, hl = pcall(api.nvim_get_hl, 0, { name = name, link = false })
  if ok and hl and hl.bg then
    return string.format('#%06x', hl.bg)
  end
  if name ~= 'Normal' then
    return group_bg_hex('Normal')
  end
  return nil
end

--- Resolve a base preset/table into a "#rrggbb" bg, if one can be determined.
---@internal
---@param spec table Result of resolve_spec/base_preset
---@return string|nil hex
local function spec_bg_hex(spec)
  if spec.bg then
    return spec.bg
  end
  if spec.link then
    return group_bg_hex(spec.link)
  end
  return nil
end

--- Resolve the fence_content_highlight spec: an explicit `hl` override wins
--- outright; otherwise shade the resolved fence-line base color (its own
--- `preset`, falling back to fence_line_highlight's) darker/lighter.
---@internal
---@param cfg ColorMyAscii.Config
---@return table hl A table suitable for nvim_set_hl
local function resolve_content_spec(cfg)
  local flh = (cfg and cfg.fence_line_highlight) or {}
  local fch = (cfg and cfg.fence_content_highlight) or {}

  local hl_override = fch.hl
  if type(hl_override) == 'string' then
    return { link = hl_override }
  elseif type(hl_override) == 'table' then
    return hl_override
  end

  local preset = fch.preset or flh.preset or 'auto'
  local base = base_preset(preset)

  local shade_mode = fch.shade or 'auto'
  if shade_mode == 'none' then
    return base
  end

  local bg = spec_bg_hex(base)
  if not bg then
    return base -- no resolvable bg (e.g. cterm-only setup) - best effort, unshaded
  end

  ---@type "darken"|"lighten"
  local direction = 'darken'
  if shade_mode == 'lighten' then
    direction = 'lighten'
  elseif shade_mode == 'auto' then
    direction = (vim.o.background == 'light') and 'lighten' or 'darken'
  end

  local color = require('color_my_ascii.utils.color')
  local shaded = color.shade(bg, fch.amount or 6, direction)
  return { bg = shaded or bg }
end

--- (Re)create the ColorMyAsciiFenceOpen/Close/Content highlight groups from
--- config. Safe to call repeatedly (e.g. on ColorScheme — which is exactly how
--- the "auto" preset re-matches the newly active theme).
---@param cfg ColorMyAscii.Config
---@return nil
function M.setup_hl(cfg)
  local flh = (cfg and cfg.fence_line_highlight) or {}
  local preset = flh.preset or 'auto'
  pcall(api.nvim_set_hl, 0, OPEN_GROUP, resolve_spec(flh.open, preset))
  pcall(api.nvim_set_hl, 0, CLOSE_GROUP, resolve_spec(flh.close, preset))
  pcall(api.nvim_set_hl, 0, CONTENT_GROUP, resolve_content_spec(cfg))
end

--- Clear all fence-line highlights in a buffer.
---@param bufnr integer
---@return nil
function M.clear(bufnr)
  pcall(api.nvim_buf_clear_namespace, bufnr, ns, 0, -1)
end

---@internal
local function set_line(bufnr, row, group, priority)
  pcall(api.nvim_buf_set_extmark, bufnr, ns, row, 0, {
    line_hl_group = group,
    priority = priority,
  })
end

--- Byte length of a line's leading whitespace (indent).
---@internal
---@param line string
---@return integer
local function indent_bytes(line)
  local ws = line:match('^[ \t]*') or ''
  return #ws
end

--- Screen columns available for buffer text in a window currently showing
--- `bufnr` (width minus the number/sign/fold gutter). Prefers the current
--- window; nil when the buffer is not displayed anywhere.
---@internal
---@param bufnr integer
---@return integer|nil
local function win_text_width(bufnr)
  local wins = vim.fn.win_findbuf(bufnr)
  if #wins == 0 then
    return nil
  end
  local cur = api.nvim_get_current_win()
  local win = vim.tbl_contains(wins, cur) and cur or wins[1]
  local ok, info = pcall(vim.fn.getwininfo, win)
  info = ok and info and info[1] or nil
  if not info then
    return nil
  end
  local w = (info.width or 0) - (info.textoff or 0)
  return w > 0 and w or nil
end

--- Paint one row of a fenced block: `line_hl_group` fills the whole screen line
--- (so every character cell - backticks, letters, digits, blank rows - shares
--- the fence background, exactly like the non-indented case), then the block's
--- own indentation on the left and `right_pad` columns off the window's right
--- edge are carved back out so the paint reads as a rectangle from the opening
--- fence's first backtick.
---
--- Left cut-out: over real indent characters a plain `hl_group` range wins over
--- `line_hl_group` outright (Neovim layers `line_hl_group` below everything);
--- a `virt_text` overlay handles the same span on a fully-blank row where there
--- are no cells to re-highlight. Right cut-out: past the text there are no cells
--- either, so it is always the overlay.
---
--- The left cut-out is never wider than the row's own indentation, so a content
--- line that happens to be less indented than the fence keeps its text painted.
---@internal
---@param bufnr integer
---@param row integer
---@param line string the row's text
---@param group string
---@param priority integer
---@param left integer byte/screen column of the opening fence's first backtick
---@param right_col integer|nil screen column where the right-edge cut-out starts
---@param right_pad integer width of the right-edge cut-out
local function paint_row(bufnr, row, line, group, priority, left, right_col, right_pad)
  left = left or 0
  pcall(api.nvim_buf_set_extmark, bufnr, ns, row, 0, {
    line_hl_group = group,
    priority = priority,
  })

  local blank = line == '' or line:match('^%s*$') ~= nil
  local mask = blank and left or math.min(left, indent_bytes(line))
  if mask > 0 then
    local real = math.min(mask, #line)
    if real > 0 then
      pcall(api.nvim_buf_set_extmark, bufnr, ns, row, 0, {
        end_row = row,
        end_col = real,
        hl_group = 'Normal',
        priority = priority + 5,
      })
    end
    pcall(api.nvim_buf_set_extmark, bufnr, ns, row, 0, {
      virt_text = { { string.rep(' ', mask), 'Normal' } },
      virt_text_win_col = 0,
      hl_mode = 'replace',
      priority = priority,
    })
  end

  if right_col and right_pad > 0 then
    pcall(api.nvim_buf_set_extmark, bufnr, ns, row, 0, {
      virt_text = { { string.rep(' ', right_pad), 'Normal' } },
      virt_text_win_col = right_col,
      hl_mode = 'replace',
      priority = priority,
    })
  end
end

--- Refresh fence-line and fence-content highlights for a buffer according to
--- config. Both sub-features are independently opt-out; each clears its own
--- stale marks when disabled. No-op entirely if neither is enabled.
---@param bufnr integer
---@param cfg ColorMyAscii.Config
---@return nil
function M.apply(bufnr, cfg)
  local flh = cfg and cfg.fence_line_highlight
  local fch = cfg and cfg.fence_content_highlight
  M.clear(bufnr)

  local line_on = flh and flh.enable
  local content_on = fch and fch.enable
  if not line_on and not content_on then
    return
  end

  local ok, blocks = pcall(function()
    return require('color_my_ascii.api.fences').list_blocks(bufnr, { lines = 'none' })
  end)
  if not ok or type(blocks) ~= 'table' then
    return
  end

  local line_apply_to = (flh and flh.apply_to) or 'all'
  local content_apply_to = (fch and fch.apply_to) or 'all'
  -- Opt-out: start the highlight at the block's own indent column (the opening
  -- fence's first backtick) instead of flooding the whole screen line from
  -- column 0, and hold a small gap off the window's right edge.
  local line_respect = not (flh and flh.respect_indent == false)
  local content_respect = not (fch and fch.respect_indent == false)
  local line_pad = math.max(0, math.min(tonumber(flh and flh.right_pad) or 0, 20))
  local content_pad = math.max(0, math.min(tonumber(fch and fch.right_pad) or 0, 20))

  -- Right-edge masks are measured from the window's text width; resolve it once.
  local text_w = ((line_respect and line_pad > 0) or (content_respect and content_pad > 0)) and win_text_width(bufnr)
    or nil
  local function right_col(pad)
    if not text_w or pad <= 0 then
      return nil
    end
    return math.max(0, text_w - pad)
  end
  local line_right, content_right = right_col(line_pad), right_col(content_pad)

  for _, b in ipairs(blocks) do
    local want_line = line_on and (line_apply_to == 'all' or (line_apply_to == 'ascii' and b.is_ascii))
    local want_content = content_on and (content_apply_to == 'all' or (content_apply_to == 'ascii' and b.is_ascii))

    if want_line or want_content then
      local need_geom = (want_line and line_respect) or (want_content and content_respect)
      local blk_lines, base_left
      if need_geom then
        blk_lines = api.nvim_buf_get_lines(bufnr, b.open_row, b.close_row + 1, false)
        base_left = indent_bytes(blk_lines[1] or '')
      end
      local function row_text(row)
        return (blk_lines and blk_lines[row - b.open_row + 1]) or ''
      end

      if want_line then
        -- below the character highlights (100+) so tokens stay visible
        if line_respect then
          paint_row(bufnr, b.open_row, row_text(b.open_row), OPEN_GROUP, 90, base_left, line_right, line_pad)
          if b.close_row ~= b.open_row then
            paint_row(bufnr, b.close_row, row_text(b.close_row), CLOSE_GROUP, 90, base_left, line_right, line_pad)
          end
        else
          set_line(bufnr, b.open_row, OPEN_GROUP, 90)
          if b.close_row ~= b.open_row then
            set_line(bufnr, b.close_row, CLOSE_GROUP, 90)
          end
        end
      end

      if want_content then
        for row = b.content_start, b.content_end - 1 do
          if content_respect then
            paint_row(bufnr, row, row_text(row), CONTENT_GROUP, 80, base_left, content_right, content_pad)
          else
            set_line(bufnr, row, CONTENT_GROUP, 80) -- below the delimiter-line highlight (90)
          end
        end
      end
    end
  end
end

return M
