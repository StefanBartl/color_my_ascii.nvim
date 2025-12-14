-- Test-Konfiguration für color_my_ascii.nvim
-- Diese Konfiguration aktiviert ALLE Features zum Testen

require('color_my_ascii').setup({
  -- Alle Features aktivieren
  enable_keywords = true,
  enable_language_detection = true,
  enable_function_names = true,
  enable_bracket_highlighting = true,
  enable_inline_code = true,
  treat_empty_fence_as_ascii = true,

  -- Optional: Gedämpfter Text für besseren Kontrast
  default_text_hl = 'Comment',

  -- Debug: Zeige an, welche Groups geladen wurden
  -- Nach Setup ausführen:
  -- :lua print(vim.inspect(require('color_my_ascii.config').char_lookup))
})

-- Debug-Funktion zum Testen
local function debug_inline_code()
  local line = "Man verwendet `func`, `→`, und `:=` in Go."
  local parser = require('color_my_ascii.parser')
  local config = require('color_my_ascii.config')

  print("=== DEBUG: Inline Code ===")
  print("Line:", line)

  -- Parse inline codes
  local inline_codes = {}
  local i = 1
  while i <= #line do
    local start_pos = line:find("`", i, true)
    if not start_pos then break end

    local end_pos = line:find("`", start_pos + 1, true)
    if not end_pos then break end

    local content = line:sub(start_pos + 1, end_pos - 1)
    table.insert(inline_codes, {
      content = content,
      start_col = start_pos - 1,
      end_col = end_pos,
    })

    i = end_pos + 1
  end

  print("\nFound inline codes:", #inline_codes)
  for _, ic in ipairs(inline_codes) do
    print(string.format("  '%s' [%d-%d]", ic.content, ic.start_col, ic.end_col))

    -- Check each character
    local chars = vim.fn.split(ic.content, '\\zs')
    for _, char in ipairs(chars) do
      local hl = config.get_char_highlight(char)
      if hl then
        print(string.format("    Char '%s' -> %s", char, hl))
      end
    end

    -- Check keywords
    local tokens = parser.tokenize_line(ic.content)
    for _, token in ipairs(tokens) do
      local kw = config.get_keyword_languages(token)
      if kw then
        print(string.format("    Keyword '%s' -> %s", token, kw[1].hl))
      end
    end
  end
end

-- Debug-Funktion für Brackets
local function debug_brackets()
  local config = require('color_my_ascii.config')

  print("=== DEBUG: Brackets ===")
  print("enable_bracket_highlighting:", config.get().enable_bracket_highlighting)

  local brackets = { '(', ')', '[', ']', '{', '}', '=' }
  for _, bracket in ipairs(brackets) do
    local hl = config.get_char_highlight(bracket)
    print(string.format("  '%s' -> %s", bracket, hl or "nil"))
  end
end

-- Befehle zum Testen
vim.api.nvim_create_user_command('DebugInlineCode', debug_inline_code, {})
vim.api.nvim_create_user_command('DebugBrackets', debug_brackets, {})

print([[
Test-Konfiguration geladen!

Debug-Befehle:
  :DebugInlineCode  - Zeigt Inline-Code-Parsing
  :DebugBrackets    - Zeigt Bracket-Highlighting
  :ColorMyAsciiDebug - Zeigt Plugin-Status
]])
