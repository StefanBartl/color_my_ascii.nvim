---@module 'color_my_ascii.languages.rust'
--- Rust language keyword definitions for ASCII art highlighting

---@type ColorMyAscii.KeywordGroup
return {
  -- All Rust keywords
  words = {
    -- Types
    'i8', 'i16', 'i32', 'i64', 'i128', 'isize',
    'u8', 'u16', 'u32', 'u64', 'u128', 'usize',
    'f32', 'f64', 'bool', 'char', 'str',
    -- Type keywords
    'type', 'struct', 'enum', 'union', 'trait', 'impl',
    -- Control flow
    'if', 'else', 'match', 'loop', 'while', 'for', 'in',
    'return', 'break', 'continue',
    -- Functions and modules
    'fn', 'mod', 'pub', 'use', 'crate', 'extern',
    -- Variables and ownership
    'let', 'mut', 'const', 'static',
    'ref', 'move', 'as',
    -- Async
    'async', 'await',
    -- Memory safety
    'unsafe', 'dyn',
    -- Attributes and macros
    'where', 'Self', 'self', 'super',
    -- Values
    'true', 'false', 'None', 'Some', 'Ok', 'Err',
    -- Common types from std
    'Vec', 'String', 'Box', 'Rc', 'Arc', 'Option', 'Result',
    -- Traits
    'Copy', 'Clone', 'Send', 'Sync', 'Drop',
  },

  -- Keywords unique to Rust
  unique_words = {
    'fn', 'mut', 'impl', 'trait',
    'match', 'loop', 'crate',
    'i8', 'i16', 'i32', 'i64', 'i128', 'isize',
    'u8', 'u16', 'u32', 'u64', 'u128', 'usize',
    'dyn', 'unsafe',
  },

  hl = 'Function',
}
