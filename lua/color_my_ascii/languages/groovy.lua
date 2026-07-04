---@module 'color_my_ascii.languages.groovy'
--- Groovy language keyword definitions for ASCII art highlighting

---@type ColorMyAscii.KeywordGroup
return {
  words = {
    -- Declarations
    'def', 'class', 'interface', 'extends', 'implements',
    'static', 'private', 'public', 'protected',
    -- Control flow
    'if', 'else', 'for', 'while', 'do',
    'switch', 'case', 'default', 'break', 'continue', 'return',
    'try', 'catch', 'finally', 'throw',
    -- Objects
    'this', 'super', 'new',
    -- Modules
    'import', 'package',
    -- Values
    'true', 'false', 'null',
    -- Common closures/collections
    'closure', 'it', 'each', 'collect', 'findAll', 'println', 'GString',
  },

  -- Keywords unique to Groovy
  unique_words = {
    'println', 'findAll', 'GString',
  },

  hl = 'Function',
}
