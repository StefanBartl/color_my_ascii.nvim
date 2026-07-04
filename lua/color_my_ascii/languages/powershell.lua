---@module 'color_my_ascii.languages.powershell'
--- PowerShell language keyword definitions for ASCII art highlighting
--- Note: PowerShell's Verb-Noun cmdlet names (e.g. Write-Host) use a hyphen,
--- which the plugin's tokenizer treats as a word boundary, so they can't be
--- registered as single keyword tokens - only genuine single-word keywords
--- and language constructs are listed here.

---@type ColorMyAscii.KeywordGroup
return {
  words = {
    -- Declarations
    'function', 'param', 'class', 'enum', 'begin', 'process', 'end',
    -- Control flow
    'if', 'elseif', 'else', 'foreach', 'while', 'do',
    'switch', 'default', 'break', 'continue', 'return',
    'try', 'catch', 'finally', 'throw', 'trap',
    -- Values (tokenizer strips the leading $ from $true/$false/$null)
    'true', 'false', 'null',
  },

  -- Keywords unique to PowerShell
  unique_words = {
    'param', 'trap',
  },

  hl = 'Function',
}
