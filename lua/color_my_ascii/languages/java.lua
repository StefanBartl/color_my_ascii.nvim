---@module 'color_my_ascii.languages.java'
--- Java language keyword definitions for ASCII art highlighting

---@type ColorMyAscii.KeywordGroup
return {
  words = {
    -- Types
    'int',
    'long',
    'double',
    'float',
    'boolean',
    'char',
    'byte',
    'short',
    'void',
    -- Declarations
    'class',
    'interface',
    'enum',
    'extends',
    'implements',
    'public',
    'private',
    'protected',
    'static',
    'final',
    'abstract',
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
    'throws',
    -- Objects
    'new',
    'this',
    'super',
    'instanceof',
    -- Modules
    'import',
    'package',
    -- Concurrency
    'synchronized',
    'volatile',
    'transient',
    -- Values
    'true',
    'false',
    'null',
    -- Common types
    'String',
    'Integer',
    'Long',
    'Double',
    'Boolean',
    'System',
    'List',
    'ArrayList',
    'Map',
    'HashMap',
    'Override',
  },

  -- Keywords unique to Java
  unique_words = {
    'implements',
    'throws',
    'synchronized',
    'volatile',
    'transient',
    'ArrayList',
  },

  hl = 'Function',
}
