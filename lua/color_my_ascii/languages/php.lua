---@module 'color_my_ascii.languages.php'
--- PHP language keyword definitions for ASCII art highlighting

---@type ColorMyAscii.KeywordGroup
return {
  words = {
    -- Declarations
    'function',
    'class',
    'interface',
    'trait',
    'extends',
    'implements',
    'public',
    'private',
    'protected',
    'static',
    'abstract',
    'final',
    'const',
    'var',
    -- Control flow
    'if',
    'else',
    'elseif',
    'for',
    'foreach',
    'as',
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
    'self',
    'parent',
    -- Modules
    'namespace',
    'use',
    'require',
    'require_once',
    'include',
    'include_once',
    -- Output
    'echo',
    'print',
    -- Values
    'true',
    'false',
    'null',
    'array',
    -- Common functions
    'isset',
    'unset',
    'empty',
    'global',
    'and',
    'or',
    'xor',
    'not',
  },

  -- Keywords unique to PHP
  unique_words = {
    'echo',
    'require_once',
    'include_once',
    'self',
    'parent',
    'isset',
  },

  hl = 'Function',
}
