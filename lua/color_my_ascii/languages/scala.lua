---@module 'color_my_ascii.languages.scala'
--- Scala language keyword definitions for ASCII art highlighting

---@type ColorMyAscii.KeywordGroup
return {
  words = {
    -- Declarations
    'def', 'val', 'var', 'class', 'object', 'trait', 'extends', 'with',
    'private', 'protected', 'override', 'abstract', 'final', 'implicit', 'lazy',
    -- Control flow
    'if', 'else', 'for', 'while', 'do',
    'match', 'case', 'return',
    'try', 'catch', 'finally', 'throw',
    -- Objects
    'this', 'super', 'new',
    -- Functional
    'yield',
    -- Values
    'null', 'true', 'false',
    -- Modules
    'import', 'package',
  },

  -- Keywords unique to Scala
  unique_words = {
    'trait', 'implicit', 'object',
  },

  hl = 'Function',
}
