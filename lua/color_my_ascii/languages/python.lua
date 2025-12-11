---@module 'color_my_ascii.languages.python'
--- Python language keyword definitions for ASCII art highlighting

---@type ColorMyAscii.KeywordGroup
return {
  -- All Python keywords
  words = {
    -- Control flow
    'if', 'elif', 'else',
    'for', 'while', 'break', 'continue',
    'pass', 'return',
    -- Functions and classes
    'def', 'class', 'lambda',
    'self', 'cls',
    -- Imports
    'import', 'from', 'as',
    -- Exception handling
    'try', 'except', 'finally', 'raise',
    -- Context managers
    'with',
    -- Logical operators
    'and', 'or', 'not', 'in', 'is',
    -- Values
    'True', 'False', 'None',
    -- Scope
    'global', 'nonlocal',
    -- Async
    'async', 'await',
    -- Special
    'del', 'yield', 'assert',
    -- Common built-ins (often in diagrams)
    'int', 'float', 'str', 'bool', 'list', 'dict', 'tuple', 'set',
    'range', 'len', 'print', 'input',
    'open', 'file', 'iter', 'next',
    'enumerate', 'zip', 'map', 'filter',
    'type', 'isinstance', 'issubclass',
    'property', 'staticmethod', 'classmethod',
    '__init__', '__str__', '__repr__',
  },

  -- Keywords unique to Python
  unique_words = {
    'def', 'elif', 'pass',
    'lambda', 'self', 'cls',
    'nonlocal', 'yield',
    '__init__', '__str__', '__repr__',
    'enumerate',
  },

  hl = 'Function',
}
