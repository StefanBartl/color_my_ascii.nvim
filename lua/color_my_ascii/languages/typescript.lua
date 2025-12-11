---@module 'color_my_ascii.languages.typescript'
--- TypeScript/JavaScript language keyword definitions for ASCII art highlighting

---@type ColorMyAscii.KeywordGroup
return {
  -- All TypeScript/JavaScript keywords
  words = {
    -- Types (TS specific)
    'number', 'string', 'boolean', 'symbol', 'bigint', 'object',
    'any', 'unknown', 'never', 'void',
    'type', 'interface', 'enum', 'namespace',
    -- Type modifiers
    'readonly', 'public', 'private', 'protected',
    'abstract', 'static',
    -- Control flow
    'if', 'else', 'switch', 'case', 'default',
    'for', 'while', 'do',
    'break', 'continue', 'return',
    'try', 'catch', 'finally', 'throw',
    -- Functions and classes
    'function', 'class', 'constructor',
    'extends', 'implements',
    'super', 'this', 'new',
    -- Variables
    'var', 'let', 'const',
    -- Async
    'async', 'await', 'Promise',
    -- Modules
    'import', 'export', 'default', 'from', 'as',
    'require', 'module',
    -- Operators
    'typeof', 'instanceof', 'in', 'of', 'delete',
    -- Values
    'true', 'false', 'null', 'undefined',
    -- Special
    'debugger', 'with', 'yield',
    -- Common types
    'Array', 'Map', 'Set', 'WeakMap', 'WeakSet',
    'Date', 'RegExp', 'Error',
  },

  -- Keywords unique to TypeScript/JavaScript
  unique_words = {
    'interface', 'namespace', 'readonly',
    'typeof', 'instanceof',
    'undefined', 'debugger',
    'const', 'let',
    'async', 'await',
    'Promise',
  },

  hl = 'Function',
}
