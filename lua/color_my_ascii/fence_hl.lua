---@module 'color_my_ascii.fence_hl'
---@brief Full-line highlight of fenced-block delimiter lines.
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

local M = {}

local api = vim.api

--- Dedicated namespace, kept separate from the character-highlight namespace so
--- fence lines survive/refresh on their own schedule.
local ns = api.nvim_create_namespace("ColorMyAsciiFenceLine")

--- Resolved highlight group names set up in M.setup_hl.
local OPEN_GROUP = "ColorMyAsciiFenceOpen"
local CLOSE_GROUP = "ColorMyAsciiFenceClose"

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

--- (Re)create the ColorMyAsciiFenceOpen/Close highlight groups from config.
--- Safe to call repeatedly (e.g. on ColorScheme — which is exactly how the
--- "auto" preset re-matches the newly active theme).
---@param cfg ColorMyAscii.Config
---@return nil
function M.setup_hl(cfg)
  local flh = (cfg and cfg.fence_line_highlight) or {}
  local preset = flh.preset or "auto"
  pcall(api.nvim_set_hl, 0, OPEN_GROUP, resolve_spec(flh.open, preset))
  pcall(api.nvim_set_hl, 0, CLOSE_GROUP, resolve_spec(flh.close, preset))
end

--- Clear all fence-line highlights in a buffer.
---@param bufnr integer
---@return nil
function M.clear(bufnr)
  pcall(api.nvim_buf_clear_namespace, bufnr, ns, 0, -1)
end

local function set_line(bufnr, row, group)
  pcall(api.nvim_buf_set_extmark, bufnr, ns, row, 0, {
    line_hl_group = group,
    priority = 90, -- below the character highlights (100+) so tokens stay visible
  })
end

--- Refresh fence-line highlights for a buffer according to config. No-op (and
--- clears any stale marks) when the feature is disabled.
---@param bufnr integer
---@param cfg ColorMyAscii.Config
---@return nil
function M.apply(bufnr, cfg)
  local flh = cfg and cfg.fence_line_highlight
  M.clear(bufnr)
  if not flh or not flh.enable then return end

  local apply_to = flh.apply_to or "all"
  local ok, blocks = pcall(function()
    return require("color_my_ascii.api.fences").list_blocks(bufnr, { lines = "none" })
  end)
  if not ok or type(blocks) ~= "table" then return end

  for _, b in ipairs(blocks) do
    if apply_to == "all" or (apply_to == "ascii" and b.is_ascii) then
      set_line(bufnr, b.open_row, OPEN_GROUP)
      if b.close_row ~= b.open_row then
        set_line(bufnr, b.close_row, CLOSE_GROUP)
      end
    end
  end
end

return M
