---@module 'color_my_ascii.languages.dart'
--- Dart language keyword definitions for ASCII art highlighting

---@type ColorMyAscii.KeywordGroup
return {
  words = {
    -- Declarations
    'void',
    'var',
    'final',
    'const',
    'class',
    'extends',
    'implements',
    'mixin',
    'with',
    'static',
    'get',
    'set',
    'factory',
    'required',
    'covariant',
    'late',
    -- Control flow
    'if',
    'else',
    'for',
    'while',
    'do',
    'switch',
    'case',
    'default',
    'break',
    'continue',
    'return',
    'try',
    'catch',
    'finally',
    'throw',
    -- Objects
    'this',
    'super',
    'new',
    -- Async
    'async',
    'await',
    'Future',
    'Stream',
    -- Modules
    'import',
    'library',
    'part',
    -- Values
    'null',
    'true',
    'false',
  },

  -- Keywords unique to Dart
  unique_words = {
    'mixin',
    'covariant',
    'late',
    'Future',
  },

  hl = 'Function',
}
