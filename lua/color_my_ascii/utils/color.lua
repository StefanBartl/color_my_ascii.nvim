---@module 'color_my_ascii.utils.color'
---@brief Minimal hex-color math: parse, format, and shade toward black/white.
---@description
--- Used to derive the fence-content background from a resolved fence-line
--- color (or any other hex bg) without hand-tuning a second palette per theme.

local M = {}

--- Parse "#rrggbb" (case-insensitive) into 0-255 components.
---@param hex string
---@return integer|nil r
---@return integer|nil g
---@return integer|nil b
function M.hex_to_rgb(hex)
  if type(hex) ~= "string" then return nil end
  local h = hex:match("^#(%x%x%x%x%x%x)$")
  if not h then return nil end
  return tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16)
end

---@param r integer
---@param g integer
---@param b integer
---@return string hex "#rrggbb"
function M.rgb_to_hex(r, g, b)
  local function clamp(n) return math.max(0, math.min(255, math.floor(n + 0.5))) end
  return string.format("#%02x%02x%02x", clamp(r), clamp(g), clamp(b))
end

--- Blend a hex color toward black ("darken") or white ("lighten") by `percent`.
---@param hex string "#rrggbb"
---@param percent number 0-100 blend strength
---@param direction "darken"|"lighten"
---@return string|nil hex Shaded color, or nil if `hex` isn't a valid "#rrggbb" string
function M.shade(hex, percent, direction)
  local r, g, b = M.hex_to_rgb(hex)
  if not r then return nil end
  local t = math.max(0, math.min(100, percent or 0)) / 100
  local target = direction == "lighten" and 255 or 0
  return M.rgb_to_hex(
    r + (target - r) * t,
    g + (target - g) * t,
    b + (target - b) * t
  )
end

return M
