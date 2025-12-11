---@module 'color_my_ascii.languages.zig'
--- Zig language keyword definitions for ASCII art highlighting

---@type ColorMyAscii.KeywordGroup
return {
  -- All Zig keywords
  words = {
    -- Types
    'i8', 'i16', 'i32', 'i64', 'i128',
    'u8', 'u16', 'u32', 'u64', 'u128',
    'f16', 'f32', 'f64', 'f80', 'f128',
    'bool', 'void', 'noreturn', 'type', 'anyerror',
    'comptime_int', 'comptime_float',
    'c_short', 'c_ushort', 'c_int', 'c_uint', 'c_long', 'c_ulong',
    'c_longlong', 'c_ulonglong', 'c_longdouble',
    'isize', 'usize',
    -- Type keywords
    'struct', 'enum', 'union', 'error', 'opaque',
    -- Control flow
    'if', 'else', 'switch', 'while', 'for',
    'break', 'continue', 'return',
    'defer', 'errdefer',
    -- Functions and variables
    'fn', 'var', 'const',
    'pub', 'export', 'extern',
    -- Memory and pointers
    'align', 'allowzero', 'packed',
    'volatile', 'linksection',
    'callconv', 'noalias',
    -- Compile-time
    'comptime', 'inline', 'noinline',
    'asm', 'volatile',
    -- Testing
    'test', 'unreachable',
    -- Values
    'true', 'false', 'null', 'undefined',
    -- Special
    'try', 'catch', 'orelse', 'and', 'or',
    'anytype', 'anyframe',
    'suspend', 'resume', 'await', 'async', 'nosuspend',
    'threadlocal',
  },

  -- Keywords unique to Zig
  unique_words = {
    'comptime', 'errdefer', 'orelse',
    'anytype', 'anyerror', 'anyframe',
    'noreturn', 'unreachable',
    'linksection', 'callconv',
    'allowzero', 'nosuspend',
    'usize', 'isize',
  },

  hl = 'Function',
}
