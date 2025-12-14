---@module 'color_my_ascii.groups.operators'
--- Operator and punctuation character group definitions

---@type ColorMyAscii.CharGroup
local group = {
  chars = '',
  hl = 'Operator',
}

-- Build character string (each character only ONCE)
local chars = {
  -- Arithmetic operators
  '+', '-', '*', '/', '%', '=',
  -- Comparison operators
  '<', '>',
  -- Logical operators
  '!', '&', '|', '^', '~',
  -- Brackets and braces (optional, can be controlled by enable_bracket_highlighting)
  '(', ')', '[', ']', '{', '}',
  -- Other punctuation
  ':', ';', ',', '.', '?',
  -- Quotes
  '"', "'", '`',
  -- Special
  '@', '#',
  -- Backslash
  '\\',
}

group.chars = table.concat(chars, '')

return group
