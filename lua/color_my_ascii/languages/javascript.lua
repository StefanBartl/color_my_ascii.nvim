---@module 'color_my_ascii.languages.javascript'
--- JavaScript language keyword definitions for ASCII art highlighting

---@type ColorMyAscii.KeywordGroup
return {
  words = {
    -- Declarations
    'var',
    'let',
    'const',
    'function',
    'class',
    -- Control flow
    'if',
    'else',
    'for',
    'while',
    'do',
    'break',
    'continue',
    'return',
    'switch',
    'case',
    'default',
    'try',
    'catch',
    'finally',
    'throw',
    -- Objects and classes
    'new',
    'this',
    'super',
    'extends',
    'static',
    'get',
    'set',
    'constructor',
    -- Operators
    'typeof',
    'instanceof',
    'delete',
    'in',
    'of',
    'void',
    -- Async
    'async',
    'await',
    'yield',
    'Promise',
    -- Modules
    'import',
    'export',
    'from',
    'as',
    'require',
    'module',
    'exports',
    -- Values
    'true',
    'false',
    'null',
    'undefined',
    'NaN',
    'Infinity',
    -- Common globals/built-ins
    'console',
    'document',
    'window',
    'globalThis',
    'JSON',
    'Object',
    'Array',
    'Math',
    'Date',
    'RegExp',
    'Error',
    'Map',
    'Set',
  },

  -- Keywords unique to JavaScript
  unique_words = {
    'console',
    'document',
    'window',
    'NaN',
    'Infinity',
    'globalThis',
  },

  hl = 'Function',
}
