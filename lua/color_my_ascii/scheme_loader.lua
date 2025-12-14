---@module 'color_my_ascii.scheme_loader'
---@brief Scheme loading and management for color_my_ascii.nvim
---@description
--- This module handles loading of predefined color schemes by name.
--- Schemes can be loaded either by passing a scheme name string or
--- by passing a complete scheme table directly.

local M = {}

--- Available built-in schemes
---@type table<string, string>
local AVAILABLE_SCHEMES = {
  default = 'color_my_ascii.schemes.default',
  matrix = 'color_my_ascii.schemes.matrix',
  nord = 'color_my_ascii.schemes.nord',
  gruvbox = 'color_my_ascii.schemes.gruvbox',
  dracula = 'color_my_ascii.schemes.dracula',
  catppuccin = 'color_my_ascii.schemes.catppuccin',
  tokyonight = 'color_my_ascii.schemes.tokyonight',
  solarized = 'color_my_ascii.schemes.solarized',
  onedark = 'color_my_ascii.schemes.onedark',
  monokai = 'color_my_ascii.schemes.monokai',
}

--- Load a scheme by name or return the scheme table if already resolved
---@param scheme_name_or_table string|ColorMyAscii.Config Scheme name or complete config table
---@return ColorMyAscii.Config|nil config Loaded scheme configuration or nil on error
---@return string|nil error Error message if loading failed
function M.load_scheme(scheme_name_or_table)
  -- If already a table, return it directly
  if type(scheme_name_or_table) == 'table' then
    return scheme_name_or_table, nil
  end

  -- Must be a string scheme name
  if type(scheme_name_or_table) ~= 'string' then
    return nil, 'scheme must be a string or table, got: ' .. type(scheme_name_or_table)
  end

  local scheme_name = scheme_name_or_table:lower()

  -- Check if scheme exists
  local scheme_path = AVAILABLE_SCHEMES[scheme_name]
  if not scheme_path then
    local available = vim.tbl_keys(AVAILABLE_SCHEMES)
    table.sort(available)
    return nil, string.format(
      'Unknown scheme "%s". Available schemes: %s',
      scheme_name,
      table.concat(available, ', ')
    )
  end

  -- Try to load the scheme module
  local ok, scheme_module = pcall(require, scheme_path)
  if not ok then
    return nil, string.format('Failed to load scheme "%s": %s', scheme_name, tostring(scheme_module))
  end

  -- Validate that the module returned a table
  if type(scheme_module) ~= 'table' then
    return nil, string.format('Scheme "%s" did not return a configuration table', scheme_name)
  end

  return scheme_module, nil
end

--- Get list of available scheme names
---@return string[] schemes List of available scheme names
function M.get_available_schemes()
  local schemes = vim.tbl_keys(AVAILABLE_SCHEMES)
  table.sort(schemes)
  return schemes
end

--- Check if a scheme name exists
---@param scheme_name string Scheme name to check
---@return boolean exists True if scheme exists
function M.scheme_exists(scheme_name)
  return AVAILABLE_SCHEMES[scheme_name:lower()] ~= nil
end

return M
