---@module 'color_my_ascii.highlighter_ts'
--- Treesitter-backed syntax highlighting for ASCII blocks, used as an addition to
--- the heuristic character/keyword highlighting in highlighter.lua when
--- config.treesitter.{enabled,syntax_highlight} are both true.
---
--- This is deliberately best-effort: ASCII art (box-drawing, arrows) is usually not
--- valid syntax in the block's language, so parsing will often fail or produce a
--- tree full of ERROR nodes. There is no gate on that - treesitter's error recovery
--- still yields correct captures for the parts that ARE valid syntax, and invalid
--- regions simply produce no captures (harmless). If parsing fails outright (no
--- parser installed, API error), M.highlight_block returns false and the caller's
--- heuristic highlighting (already applied earlier in the same pass) remains as-is.

local M = {}

local safe_api = require('color_my_ascii.utils.safe_api')

--- Extmark priority for treesitter captures - higher than the heuristic passes'
--- priority of 100, so real syntax wins visually where both apply to the same range.
local PRIORITY = 150

--- Map of plugin language name (lua/color_my_ascii/languages/*.lua) to treesitter
--- parser name. Only languages with a commonly available grammar are listed; a
--- missing entry silently means "no treesitter syntax highlighting for this
--- language" (heuristic highlighting is unaffected).
---@type table<string, string>
local LANGUAGE_MAP = {
  bash = 'bash',
  c = 'c',
  cpp = 'cpp',
  go = 'go',
  lua = 'lua',
  python = 'python',
  rust = 'rust',
  typescript = 'typescript',
  vim = 'vim',
  zig = 'zig',
  javascript = 'javascript',
  json = 'json',
  java = 'java',
  html = 'html',
  css = 'css',
  csharp = 'c_sharp', -- treesitter's grammar is registered as "c_sharp", not "csharp"
  php = 'php',
  ruby = 'ruby',
  kotlin = 'kotlin',
  swift = 'swift',
  scala = 'scala',
  dart = 'dart',
  elixir = 'elixir',
  haskell = 'haskell',
  perl = 'perl',
  r = 'r',
  clojure = 'clojure',
  groovy = 'groovy',
  powershell = 'powershell',
  sql = 'sql',
  -- llvm intentionally omitted: no common treesitter grammar for LLVM IR.
}

--- Check whether a treesitter parser is available for the given plugin language.
---@param language string|nil Plugin language name (e.g. "lua", "cpp")
---@return string|nil ts_lang The mapped treesitter language name, if available
local function resolve_ts_language(language)
  if not language then
    return nil
  end

  local ts_lang = LANGUAGE_MAP[language]
  if not ts_lang then
    return nil
  end

  local ok = pcall(vim.treesitter.language.add, ts_lang)
  if not ok then
    return nil
  end

  return ts_lang
end

--- Highlight a block's content using the target language's real treesitter grammar.
---@param bufnr integer Buffer number
---@param block ColorMyAscii.Block Block to highlight
---@param detected_language string|nil Plugin language name detected for this block
---@param namespace integer Extmark namespace to use - callers must pass the same
---namespace they clear on re-highlight (highlighter.lua's M.clear_buffer), otherwise
---these extmarks would never get cleaned up on re-highlight.
---@return boolean success True if a parser ran (even if it produced zero captures)
function M.highlight_block(bufnr, block, detected_language, namespace)
  local ts_lang = resolve_ts_language(detected_language)
  if not ts_lang then
    return false
  end

  local text = table.concat(block.lines, '\n')
  if text == '' then
    return false
  end

  local ok_parser, str_parser = pcall(vim.treesitter.get_string_parser, text, ts_lang)
  if not ok_parser then
    return false
  end

  local ok_parse, trees = pcall(function() return str_parser:parse() end)
  if not ok_parse or not trees or not trees[1] then
    return false
  end

  local root = trees[1]:root()

  local ok_query, query = pcall(vim.treesitter.query.get, ts_lang, 'highlights')
  if not ok_query or not query then
    return false
  end

  -- Content lines start right after the opening fence line (block.start_line).
  local content_start_line = block.start_line + 1

  local ok_iter = pcall(function()
    for id, node in query:iter_captures(root, text, 0, -1) do
      local capture_name = query.captures[id]
      local srow, scol, erow, ecol = node:range()

      -- v1 limitation: multi-line captures are clipped to their first line, to
      -- keep extmark handling identical to the single-line-per-call heuristic path.
      if erow > srow then
        ecol = #(block.lines[srow + 1] or '')
      end

      local abs_line = content_start_line + srow
      local line_content = block.lines[srow + 1]

      if line_content then
        safe_api.set_extmark(bufnr, namespace, abs_line, scol, ecol, '@' .. capture_name, line_content, PRIORITY)
      end
    end
  end)

  return ok_iter
end

return M
