---@module 'color_my_ascii.languages.bash'
--- Bash/Shell script keyword definitions for ASCII art highlighting

---@type ColorMyAscii.KeywordGroup
return {
  -- Bash keywords and common commands
  words = {
    -- Control structures
    'if', 'then', 'else', 'elif', 'fi',
    'case', 'esac', 'in',
    'for', 'while', 'until', 'do', 'done',
    'select',
    -- Functions
    'function', 'return',
    -- Special keywords
    'local', 'declare', 'readonly', 'export',
    'unset', 'shift', 'eval', 'exec', 'source',
    'alias', 'unalias',
    -- Test operators
    'test', 'true', 'false',
    -- Common built-ins
    'echo', 'printf', 'read', 'cd', 'pwd',
    'exit', 'break', 'continue',
    'set', 'unset', 'trap',
    -- Common commands (often in diagrams)
    'ls', 'cp', 'mv', 'rm', 'mkdir', 'rmdir',
    'cat', 'grep', 'sed', 'awk', 'cut', 'sort',
    'find', 'which', 'whereis',
    'chmod', 'chown', 'chgrp',
    'ps', 'kill', 'top', 'jobs', 'bg', 'fg',
    'tar', 'gzip', 'gunzip', 'zip', 'unzip',
    'curl', 'wget', 'ssh', 'scp', 'rsync',
    'git', 'docker', 'make',
    -- Variables
    'PATH', 'HOME', 'USER', 'SHELL', 'PWD',
  },

  -- Keywords unique to Bash
  unique_words = {
    'fi', 'esac', 'done',
    'elif', 'bash', 'sh',
    'declare', 'readonly',
  },

  hl = 'Function',
}
