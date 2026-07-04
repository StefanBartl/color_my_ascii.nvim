---@module 'color_my_ascii.languages.swift'
--- Swift language keyword definitions for ASCII art highlighting

---@type ColorMyAscii.KeywordGroup
return {
  words = {
    -- Declarations
    'func', 'var', 'let', 'class', 'struct', 'enum', 'protocol', 'extension',
    'private', 'public', 'internal', 'fileprivate', 'open',
    'static', 'lazy', 'weak', 'unowned',
    -- Control flow
    'if', 'else', 'guard', 'for', 'while', 'repeat',
    'switch', 'case', 'default', 'break', 'continue', 'return',
    'try', 'catch', 'throw', 'throws', 'do', 'defer',
    -- Objects
    'this', 'self', 'super', 'init', 'deinit', 'override',
    -- Values
    'nil', 'true', 'false',
    -- Modules
    'import',
  },

  -- Keywords unique to Swift
  unique_words = {
    'guard', 'fileprivate', 'unowned', 'deinit',
  },

  hl = 'Function',
}
