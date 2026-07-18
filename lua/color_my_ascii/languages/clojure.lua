---@module 'color_my_ascii.languages.clojure'
--- Clojure language keyword definitions for ASCII art highlighting

---@type ColorMyAscii.KeywordGroup
return {
  words = {
    -- Declarations
    'defn',
    'def',
    'defmacro',
    'ns',
    -- Control flow
    'let',
    'if',
    'when',
    'cond',
    'case',
    'do',
    'loop',
    'recur',
    -- Functions
    'fn',
    -- Modules
    'require',
    'import',
    -- Values
    'true',
    'false',
    'nil',
    -- Logical operators
    'and',
    'or',
    'not',
    -- State (tokenizer strips trailing ! from swap!/reset!, so listed without it)
    'atom',
    'swap',
    'reset',
    'deref',
    -- Common functions
    'map',
    'filter',
    'reduce',
    'conj',
    'cons',
    'first',
    'rest',
    'quote',
  },

  -- Keywords unique to Clojure
  unique_words = {
    'defn',
    'recur',
    'deref',
    'conj',
  },

  hl = 'Function',
}
