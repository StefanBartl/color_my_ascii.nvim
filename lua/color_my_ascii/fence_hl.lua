---@module 'color_my_ascii.fence_hl'
---@brief Full-line highlight of fenced-block delimiter lines and interior.
---@description
--- Optional feature: paints the whole opening (```lang) and closing (```) line
--- of fenced code blocks, as a visual boundary. Uses `line_hl_group` extmarks
--- in its own namespace so it can be refreshed/cleared independently of the
--- ASCII character highlighting.
---
--- Which blocks are painted is driven by `apply_to` ("all" fenced blocks or only
--- "ascii" ones); the look by `preset` plus optional per-delimiter `open`/`close`
--- overrides. Overrides accept an existing highlight-group name (string) or an
--- attribute table forwarded to nvim_set_hl.
---
--- A second, independent sub-feature (`fence_content_highlight`) paints the
--- block *interior* (every row between the delimiters) the same way, shaded
--- darker/lighter than the resolved delimiter color so the whole block reads
--- as one region while staying visually distinct from its boundary.

local M = {}

local api = vim.api

--- Dedicated namespace, kept separate from the character-highlight namespace so
--- fence lines survive/refresh on their own schedule.
local ns = api.nvim_create_namespace("ColorMyAsciiFenceLine")

--- Resolved highlight group names set up in M.setup_hl.
local OPEN_GROUP = "ColorMyAsciiFenceOpen"
local CLOSE_GROUP = "ColorMyAsciiFenceClose"
local CONTENT_GROUP = "ColorMyAsciiFenceContent"

--- Generic, theme-adaptive presets: link to widely-available built-in groups so
--- the look follows the colorscheme instead of hardcoding colors.
---@type table<string, ColorMyAscii.CustomHighlight>
local PRESETS = {
  subtle    = { link = "CursorLine" },
  accent    = { link = "Visual" },
  underline = { underline = true },
  bar       = { link = "ColorColumn" },
}

--- Resolve a preset NAME (no per-delimiter override) to a highlight definition:
---   "auto"          -> the current colorscheme's theme preset, else "subtle"
---   generic name    -> subtle | accent | underline | bar
---   theme name      -> the matching hand-tuned theme preset (see theme_presets)
---   anything else   -> "subtle"
---@param preset string
---@return ColorMyAscii.CustomHighlight
local function base_preset(preset)
  local themes = require("color_my_ascii.theme_presets")
  if preset == "auto" then
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
---@param override string|ColorMyAscii.CustomHighlight|nil
---@param preset string
---@return table hl A table suitable for nvim_set_hl
local function resolve_spec(override, preset)
  if type(override) == "string" then
    return { link = override }
  elseif type(override) == "table" then
    return override
  end
  return base_preset(preset)
end

--- Best-effort resolution of a highlight group's background to a "#rrggbb"
--- string, following one `link` hop and finally falling back to "Normal".
---@param name string
---@return string|nil hex
local function group_bg_hex(name)
  local ok, hl = pcall(api.nvim_get_hl, 0, { name = name, link = false })
  if ok and hl and hl.bg then
    return string.format("#%06x", hl.bg)
  end
  if name ~= "Normal" then
    return group_bg_hex("Normal")
  end
  return nil
end

--- Resolve a base preset/table into a "#rrggbb" bg, if one can be determined.
---@param spec table Result of resolve_spec/base_preset
---@return string|nil hex
local function spec_bg_hex(spec)
  if spec.bg then return spec.bg end
  if spec.link then return group_bg_hex(spec.link) end
  return nil
end

--- Resolve the fence_content_highlight spec: an explicit `hl` override wins
--- outright; otherwise shade the resolved fence-line base color (its own
--- `preset`, falling back to fence_line_highlight's) darker/lighter.
---@param cfg ColorMyAscii.Config
---@return table hl A table suitable for nvim_set_hl
local function resolve_content_spec(cfg)
  local flh = (cfg and cfg.fence_line_highlight) or {}
  local fch = (cfg and cfg.fence_content_highlight) or {}

  local hl_override = fch.hl
  if type(hl_override) == "string" then
    return { link = hl_override }
  elseif type(hl_override) == "table" then
    return hl_override
  end

  local preset = fch.preset or flh.preset or "auto"
  local base = base_preset(preset)

  local shade_mode = fch.shade or "auto"
  if shade_mode == "none" then
    return base
  end

  local bg = spec_bg_hex(base)
  if not bg then
    return base -- no resolvable bg (e.g. cterm-only setup) - best effort, unshaded
  end

  ---@type "darken"|"lighten"
  local direction = "darken"
  if shade_mode == "lighten" then
    direction = "lighten"
  elseif shade_mode == "auto" then
    direction = (vim.o.background == "light") and "lighten" or "darken"
  end

  local color = require("color_my_ascii.utils.color")
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
  local preset = flh.preset or "auto"
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

local function set_line(bufnr, row, group, priority)
  pcall(api.nvim_buf_set_extmark, bufnr, ns, row, 0, {
    line_hl_group = group,
    priority = priority,
  })
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
  if not line_on and not content_on then return end

  local ok, blocks = pcall(function()
    return require("color_my_ascii.api.fences").list_blocks(bufnr, { lines = "none" })
  end)
  if not ok or type(blocks) ~= "table" then return end

  local line_apply_to = (flh and flh.apply_to) or "all"
  local content_apply_to = (fch and fch.apply_to) or "all"

  for _, b in ipairs(blocks) do
    if line_on and (line_apply_to == "all" or (line_apply_to == "ascii" and b.is_ascii)) then
      -- below the character highlights (100+) so tokens stay visible
      set_line(bufnr, b.open_row, OPEN_GROUP, 90)
      if b.close_row ~= b.open_row then
        set_line(bufnr, b.close_row, CLOSE_GROUP, 90)
      end
    end
    if content_on and (content_apply_to == "all" or (content_apply_to == "ascii" and b.is_ascii)) then
      for row = b.content_start, b.content_end - 1 do
        set_line(bufnr, row, CONTENT_GROUP, 80) -- below the delimiter-line highlight (90)
      end
    end
  end
end

return M
