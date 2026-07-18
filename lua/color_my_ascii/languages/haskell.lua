---@module 'color_my_ascii.languages.haskell'
--- Haskell language keyword definitions for ASCII art highlighting

---@type ColorMyAscii.KeywordGroup
return {
  words = {
    -- Declarations
    'module',
    'import',
    'where',
    'data',
    'type',
    'newtype',
    'class',
    'instance',
    'deriving',
    -- Control flow
    'if',
    'then',
    'else',
    'case',
    'of',
    'let',
    'in',
    'do',
    -- Values
    'True',
    'False',
    'Nothing',
    'Just',
    -- Common types
    'IO',
    'Maybe',
    'Either',
    'Int',
    'Integer',
    'Char',
    'String',
    'Bool',
    -- Common functions
    'map',
    'filter',
    'foldr',
    'foldl',
    'return',
  },

  -- Keywords unique to Haskell
  unique_words = {
    'newtype',
    'deriving',
    'Nothing',
    'Maybe',
    'foldr',
    'foldl',
  },

  hl = 'Function',
}
