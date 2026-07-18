---@module 'color_my_ascii.languages.ruby'
--- Ruby language keyword definitions for ASCII art highlighting

---@type ColorMyAscii.KeywordGroup
return {
  words = {
    -- Declarations
    'def',
    'end',
    'class',
    'module',
    -- Control flow
    'if',
    'elsif',
    'else',
    'unless',
    'while',
    'until',
    'for',
    'in',
    'do',
    'begin',
    'rescue',
    'ensure',
    'raise',
    'retry',
    'redo',
    'case',
    'when',
    'then',
    'break',
    'next',
    'return',
    -- Objects
    'self',
    'super',
    'yield',
    -- Modules
    'require',
    'require_relative',
    -- Attributes
    'attr_accessor',
    'attr_reader',
    'attr_writer',
    -- Output
    'puts',
    'print',
    'p',
    -- Values
    'nil',
    'true',
    'false',
    -- Logical operators
    'and',
    'or',
    'not',
    -- Blocks
    'lambda',
    'proc',
  },

  -- Keywords unique to Ruby
  unique_words = {
    'elsif',
    'unless',
    'attr_accessor',
    'attr_reader',
    'retry',
    'redo',
  },

  hl = 'Function',
}
