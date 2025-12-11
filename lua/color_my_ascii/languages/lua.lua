---@module 'color_my_ascii.languages.lua'
--- Lua language keyword definitions for ASCII art highlighting

---@type ColorMyAscii.KeywordGroup
return {
  -- All Lua keywords
  words = {
    -- Control structures
    'if', 'then', 'else', 'elseif', 'end',
    'for', 'while', 'do', 'repeat', 'until',
    'break', 'return', 'goto',
    -- Functions and scope
    'function', 'local', 'in',
    -- Logical operators
    'and', 'or', 'not',
    -- Values
    'true', 'false', 'nil',
    -- Common standard library
    'require', 'module', 'print', 'pairs', 'ipairs',
    'type', 'tonumber', 'tostring', 'next',
    'setmetatable', 'getmetatable',
    'table', 'string', 'math', 'io', 'os', 'debug',
    -- Lua 5.2+
    'goto',
  },

  -- Keywords unique to Lua
  unique_words = {
    'then', 'elseif', 'end',
    'repeat', 'until',
    'local', 'nil',
    'ipairs', 'pairs',
  },

  hl = 'Function',
}
