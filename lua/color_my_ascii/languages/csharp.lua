---@module 'color_my_ascii.languages.csharp'
--- C# language keyword definitions for ASCII art highlighting

---@type ColorMyAscii.KeywordGroup
return {
  words = {
    -- Declarations
    'using',
    'namespace',
    'class',
    'struct',
    'interface',
    'enum',
    'delegate',
    'event',
    'public',
    'private',
    'protected',
    'internal',
    'static',
    'sealed',
    'abstract',
    'virtual',
    'override',
    'readonly',
    'const',
    -- Types
    'int',
    'long',
    'double',
    'float',
    'decimal',
    'bool',
    'string',
    'char',
    'byte',
    'void',
    'var',
    -- Control flow
    'if',
    'else',
    'for',
    'foreach',
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
    'new',
    'this',
    'base',
    -- Async
    'async',
    'await',
    -- Properties
    'get',
    'set',
    -- Values
    'true',
    'false',
    'null',
    -- Common types
    'Console',
    'List',
    'Dictionary',
    'IEnumerable',
    'Task',
  },

  -- Keywords unique to C#
  unique_words = {
    'foreach',
    'delegate',
    'sealed',
    'internal',
    'Console',
  },

  hl = 'Function',
}
