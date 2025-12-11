---@module 'color_my_ascii.languages.c'
--- C language keyword definitions for ASCII art highlighting

---@type ColorMyAscii.KeywordGroup
return {
  -- All C keywords
  words = {
    -- Types
    'int', 'void', 'char', 'float', 'double', 'long', 'short',
    'unsigned', 'signed', 'struct', 'union', 'enum', 'typedef',
    -- Control flow
    'if', 'else', 'for', 'while', 'do', 'switch', 'case', 'default',
    'return', 'break', 'continue', 'goto',
    -- Other keywords
    'sizeof', 'const', 'static', 'extern', 'auto', 'register', 'volatile',
    'inline', 'restrict',
    -- C11 keywords
    '_Alignas', '_Alignof', '_Atomic', '_Bool', '_Complex', '_Generic',
    '_Imaginary', '_Noreturn', '_Static_assert', '_Thread_local',
    -- Preprocessor (commonly used in diagrams)
    'include', 'define', 'ifdef', 'ifndef', 'endif', 'pragma',
    -- Common standard library (often shown in diagrams)
    'NULL', 'true', 'false', 'size_t', 'FILE', 'EOF',
  },

  -- Keywords unique to C (not in C++ or other languages)
  -- These are used for heuristic language detection
  unique_words = {
    'restrict', '_Bool', '_Complex', '_Atomic',
  },

  -- Highlight group to use for these keywords
  hl = 'Function',
}
