---@module 'color_my_ascii.theme_presets'
---@brief Theme-matched fence-line-highlight presets + current-theme detection.
---@description
--- Hand-tuned fence-line looks for the most common Neovim colorschemes. Each
--- entry is a ColorMyAscii.CustomHighlight applied to both the opening and
--- closing fence line: `bg` is a subtle surface tint from the theme's palette,
--- `fg` an accent so the ``` marker + language tag stand out.
---
--- `preset = "auto"` (the default) reads `vim.g.colors_name`, substring-matches
--- it against these presets (so variants like "catppuccin-mocha" or
--- "tokyonight-storm" match their base), and falls back to the theme-adaptive
--- generic "subtle" preset when there's no match or the background is light.
---
--- The detection helper (M.current / M.resolve_auto) is deliberately dependency
--- free and self-contained, so it can be lifted into lib.nvim later for other
--- plugins to share.

local M = {}

--- Fence-line looks per colorscheme. Keys are matched as substrings of a
--- lowercased `vim.g.colors_name` (longest key first), so a plugin that sets
--- e.g. "gruvbox-material" matches that entry before plain "gruvbox".
---@type table<string, ColorMyAscii.CustomHighlight>
M.presets = {
  catppuccin = { bg = '#313244', fg = '#89b4fa' }, -- mocha surface0 / blue
  tokyonight = { bg = '#292e42', fg = '#7aa2f7' }, -- night bg_highlight / blue
  ['gruvbox-material'] = { bg = '#3c3836', fg = '#a9b665' }, -- bg1 / green
  gruvbox = { bg = '#3c3836', fg = '#fabd2f' }, -- bg1 / yellow
  nord = { bg = '#3b4252', fg = '#88c0d0' }, -- nord1 / nord8
  onedark = { bg = '#2c313c', fg = '#61afef' }, -- black2 / blue
  dracula = { bg = '#44475a', fg = '#bd93f9' }, -- current line / purple
  kanagawa = { bg = '#2a2a37', fg = '#7e9cd8' }, -- sumiInk3 / crystalBlue
  ['rose-pine'] = { bg = '#26233a', fg = '#c4a7e7' }, -- overlay / iris
  everforest = { bg = '#374145', fg = '#a7c080' }, -- bg2 / green
  nightfox = { bg = '#2b3b51', fg = '#719cd6' }, -- bg3 / blue
  material = { bg = '#37474f', fg = '#82aaff' }, -- surface / blue
  sonokai = { bg = '#2c2e34', fg = '#9ed072' }, -- bg1 / green
  monokai = { bg = '#423f3e', fg = '#a9dc76' }, -- pro bg2 / green
  solarized = { bg = '#073642', fg = '#268bd2' }, -- base02 / blue
  github = { bg = '#21262d', fg = '#58a6ff' }, -- dark surface / blue
  oxocarbon = { bg = '#262626', fg = '#33b1ff' }, -- gray90 / cyan
}

-- Aliases: colorschemes whose `colors_name` doesn't already contain a key above.
M.presets['rosepine'] = M.presets['rose-pine']
M.presets['onedarkpro'] = M.presets.onedark

--- The normalized (lowercased) current colorscheme name, or nil if unset.
---@return string|nil
function M.current()
  local name = vim.g.colors_name
  if type(name) ~= 'string' or name == '' then
    return nil
  end
  return name:lower()
end

--- Resolve the theme-matched preset for the current colorscheme.
--- Substring-matches `vim.g.colors_name` against M.presets (longest key first).
--- Returns nil when there's no match or the background is light (the caller then
--- falls back to a generic, theme-adaptive preset).
---@return ColorMyAscii.CustomHighlight|nil preset
---@return string|nil matched_key
function M.resolve_auto()
  local name = M.current()
  if not name then
    return nil, nil
  end
  if vim.o.background == 'light' then
    return nil, nil
  end

  local keys = {}
  for k in pairs(M.presets) do
    keys[#keys + 1] = k
  end
  table.sort(keys, function(a, b)
    return #a > #b
  end)

  for _, k in ipairs(keys) do
    if name:find(k, 1, true) then
      return M.presets[k], k
    end
  end
  return nil, nil
end

--- Whether a preset name refers to a theme preset (vs. a generic look).
---@param name string
---@return boolean
function M.is_theme(name)
  return M.presets[name] ~= nil
end

return M
