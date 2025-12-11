---@module 'color_my_ascii.languages.cpp'
--- C++ language keyword definitions for ASCII art highlighting

---@type ColorMyAscii.KeywordGroup
return {
  -- All C++ keywords (including C keywords)
  words = {
    -- C++ specific keywords
    'class', 'namespace', 'template', 'typename', 'using',
    'public', 'private', 'protected', 'friend',
    'virtual', 'override', 'final', 'abstract',
    'operator', 'new', 'delete', 'this',
    'try', 'catch', 'throw', 'noexcept',
    'explicit', 'mutable', 'constexpr', 'decltype',
    'static_cast', 'dynamic_cast', 'const_cast', 'reinterpret_cast',
    -- C++11 and later
    'nullptr', 'auto', 'decltype', 'constexpr', 'static_assert',
    'thread_local', 'alignas', 'alignof',
    -- C++20
    'concept', 'requires', 'co_await', 'co_return', 'co_yield',
    -- C types (also valid in C++)
    'int', 'void', 'char', 'float', 'double', 'long', 'short',
    'unsigned', 'signed', 'struct', 'union', 'enum', 'typedef',
    'bool', 'true', 'false',
    -- Control flow
    'if', 'else', 'for', 'while', 'do', 'switch', 'case', 'default',
    'return', 'break', 'continue', 'goto',
    -- Storage
    'const', 'static', 'extern', 'register', 'volatile', 'inline',
    'sizeof',
    -- Common STL (often in diagrams)
    'std', 'vector', 'string', 'map', 'set', 'list', 'deque',
    'shared_ptr', 'unique_ptr', 'weak_ptr',
  },

  -- Keywords unique to C++ (not in C)
  unique_words = {
    'class', 'namespace', 'template', 'typename',
    'public', 'private', 'protected',
    'virtual', 'override', 'nullptr',
    'operator', 'new', 'delete', 'this',
    'try', 'catch', 'throw',
    'constexpr', 'decltype',
    'concept', 'requires',
  },

  hl = 'Function',
}
