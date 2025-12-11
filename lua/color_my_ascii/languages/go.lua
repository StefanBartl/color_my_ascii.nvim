---@module 'color_my_ascii.languages.go'
--- Go language keyword definitions for ASCII art highlighting

---@type ColorMyAscii.KeywordGroup
return {
  -- All Go keywords
  words = {
    -- Types
    'int', 'int8', 'int16', 'int32', 'int64',
    'uint', 'uint8', 'uint16', 'uint32', 'uint64', 'uintptr',
    'float32', 'float64', 'complex64', 'complex128',
    'bool', 'byte', 'rune', 'string', 'error',
    -- Type definitions
    'type', 'struct', 'interface',
    -- Control flow
    'if', 'else', 'for', 'range', 'switch', 'case', 'default',
    'return', 'break', 'continue', 'goto', 'fallthrough',
    'select',
    -- Functions and variables
    'func', 'var', 'const',
    -- Goroutines and channels
    'go', 'defer', 'chan',
    -- Package and imports
    'package', 'import',
    -- Built-in functions
    'make', 'new', 'len', 'cap', 'append', 'copy', 'delete',
    'panic', 'recover', 'close',
    -- Values
    'true', 'false', 'nil', 'iota',
    -- Maps and slices
    'map', 'slice',
    -- Operators (as words for pattern matching)
    ':=', '...', '<-', '->', '==', '!=', '<=', '>=',
    '++', '--', '&&', '||',
  },

  -- Keywords unique to Go
  unique_words = {
    'func', 'chan', 'defer', 'go',
    'range', 'fallthrough', 'select',
    'package', 'iota', 'rune',
    ':=', '<-',
  },

  hl = 'Function',
}
