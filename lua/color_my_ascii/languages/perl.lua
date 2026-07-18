---@module 'color_my_ascii.languages.perl'
--- Perl language keyword definitions for ASCII art highlighting

---@type ColorMyAscii.KeywordGroup
return {
  words = {
    -- Declarations
    'my',
    'our',
    'local',
    'sub',
    'package',
    -- Control flow
    'if',
    'elsif',
    'unless',
    'else',
    'while',
    'until',
    'for',
    'foreach',
    'do',
    'return',
    -- Modules
    'use',
    'require',
    -- Output
    'print',
    -- Common functions
    'shift',
    'push',
    'pop',
    'splice',
    'defined',
    'undef',
    'ref',
    'bless',
    'die',
    'eval',
    'wantarray',
    'qw',
  },

  -- Keywords unique to Perl
  unique_words = {
    'bless',
    'wantarray',
    'qw',
    'die',
  },

  hl = 'Function',
}
