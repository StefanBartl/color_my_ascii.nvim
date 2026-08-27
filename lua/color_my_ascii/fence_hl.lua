---@module 'color_my_ascii.fence_hl'
--- Full-line highlight of fenced-block delimiter lines and interior.
---
--- Optional feature: paints the opening (```lang) and closing (```) line
--- of fenced code blocks, as a visual boundary. Extmarks live in their own
--- namespace so they can be refreshed/cleared independently of the ASCII
--- character highlighting. By default (`respect_indent`) the paint is a bounded
--- column range - kept out of an indented block's own indentation and stopped
--- at the block's widest line, with virtual padding completing the rectangle;
--- `respect_indent = false` falls back to a full-line `line_hl_group` extmark.
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

--- Paint a single row as part of a fenced-block rectangle bounded on the left by
--- `left` (byte column, so the block's own indentation stays unpainted) and on
--- the right by `right_dw` (display columns, so every row ends flush at the
--- block's widest line and Neovim's natural right-edge gap is preserved instead
--- of flooding to the window border).
---
--- Real text gets a bounded `hl_group` range; the remaining stretch out to
--- `right_dw` is filled with virtual padding pinned to a fixed window column
--- (`virt_text_win_col`, NOT `eol`) so a markdown renderer's own end-of-line
--- virtual text can't shove the padding out of alignment.
---@internal
local function paint_range(bufnr, row, line, group, priority, left, right_dw)
  local llen = #line
  local dw = vim.fn.strdisplaywidth(line)
  local lb = math.min(left, llen)

  if llen > lb then
    pcall(api.nvim_buf_set_extmark, bufnr, ns, row, lb, {
      end_row = row,
      end_col = llen,
      hl_group = group,
      priority = priority,
    })
  end

  -- Fill from the end of the real text (or the left edge, for a blank/near-blank
  -- row) out to the block's widest column. The left indentation stays untouched.
  local fill_from = math.max(dw, left)
  if right_dw > fill_from then
    pcall(api.nvim_buf_set_extmark, bufnr, ns, row, lb, {
      virt_text = { { string.rep(' ', right_dw - fill_from), group } },
      virt_text_win_col = fill_from,
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
  -- Opt-out: keep the highlight inside the block's indentation and stop it at
  -- the widest line instead of flooding the whole screen line.
  local line_respect = not (flh and flh.respect_indent == false)
  local content_respect = not (fch and fch.respect_indent == false)

  for _, b in ipairs(blocks) do
    local want_line = line_on and (line_apply_to == 'all' or (line_apply_to == 'ascii' and b.is_ascii))
    local want_content = content_on and (content_apply_to == 'all' or (content_apply_to == 'ascii' and b.is_ascii))

    if want_line or want_content then
      local need_geom = (want_line and line_respect) or (want_content and content_respect)
      local blk_lines, base_left, right_dw
      if need_geom then
        blk_lines = api.nvim_buf_get_lines(bufnr, b.open_row, b.close_row + 1, false)
        base_left = indent_bytes(blk_lines[1] or '')
        right_dw = 0
        for _, l in ipairs(blk_lines) do
          right_dw = math.max(right_dw, vim.fn.strdisplaywidth(l))
        end
      end

      if want_line then
        -- below the character highlights (100+) so tokens stay visible
        if line_respect then
          paint_range(bufnr, b.open_row, blk_lines[1] or '', OPEN_GROUP, 90, base_left, right_dw)
          if b.close_row ~= b.open_row then
            local last = blk_lines[#blk_lines] or ''
            paint_range(bufnr, b.close_row, last, CLOSE_GROUP, 90, base_left, right_dw)
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
            local l = blk_lines[row - b.open_row + 1] or ''
            local left = math.min(base_left, indent_bytes(l))
            paint_range(bufnr, row, l, CONTENT_GROUP, 80, left, right_dw)
          else
            set_line(bufnr, row, CONTENT_GROUP, 80) -- below the delimiter-line highlight (90)
          end
        end
      end
    end
  end
end

return M
