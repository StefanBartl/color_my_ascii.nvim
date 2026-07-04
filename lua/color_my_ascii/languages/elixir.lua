---@module 'color_my_ascii.languages.elixir'
--- Elixir language keyword definitions for ASCII art highlighting

---@type ColorMyAscii.KeywordGroup
return {
  words = {
    -- Declarations
    'def', 'defmodule', 'defp', 'defmacro', 'defstruct', 'defprotocol',
    -- Control flow
    'do', 'end', 'if', 'unless', 'else', 'case', 'cond', 'when',
    -- Functions
    'fn', 'receive', 'spawn', 'send',
    -- Modules
    'import', 'alias', 'require', 'use', 'module',
    -- Values
    'true', 'false', 'nil',
    -- Logical operators
    'and', 'or', 'not', 'in',
    -- Macros
    'quote', 'unquote',
  },

  -- Keywords unique to Elixir
  unique_words = {
    'defmodule', 'defp', 'defmacro', 'defstruct', 'spawn',
  },

  hl = 'Function',
}
