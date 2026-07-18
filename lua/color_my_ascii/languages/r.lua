---@module 'color_my_ascii.languages.r'
--- R language keyword definitions for ASCII art highlighting

---@type ColorMyAscii.KeywordGroup
return {
  words = {
    -- Declarations
    'function',
    -- Control flow
    'if',
    'else',
    'for',
    'while',
    'repeat',
    'break',
    'next',
    'return',
    -- Values
    'TRUE',
    'FALSE',
    'NULL',
    'NA',
    'NaN',
    'Inf',
    -- Modules
    'library',
    'require',
    -- Output
    'print',
    'cat',
    -- Common functions
    'c',
    'list',
    'vector',
    'matrix',
    'apply',
    'sapply',
    'lapply',
    'vapply',
    'mapply',
    'environment',
    'assign',
    'ifelse',
  },

  -- Keywords unique to R
  unique_words = {
    'sapply',
    'lapply',
    'vapply',
    'mapply',
    'ifelse',
  },

  hl = 'Function',
}
