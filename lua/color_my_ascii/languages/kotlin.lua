---@module 'color_my_ascii.languages.kotlin'
--- Kotlin language keyword definitions for ASCII art highlighting

---@type ColorMyAscii.KeywordGroup
return {
  words = {
    -- Declarations
    'fun', 'val', 'var', 'class', 'object', 'interface', 'enum',
    'private', 'public', 'protected', 'internal',
    'open', 'abstract', 'override', 'companion',
    -- Control flow
    'if', 'else', 'for', 'while', 'do',
    'when', 'break', 'continue', 'return',
    'try', 'catch', 'finally', 'throw',
    -- Objects
    'this', 'super', 'init', 'constructor',
    -- Types/operators
    'is', 'as', 'in', 'out', 'null', 'true', 'false',
    -- Coroutines
    'suspend', 'lateinit', 'lazy',
    -- Modules
    'import', 'package',
  },

  -- Keywords unique to Kotlin
  unique_words = {
    'fun', 'companion', 'lateinit', 'suspend',
  },

  hl = 'Function',
}
