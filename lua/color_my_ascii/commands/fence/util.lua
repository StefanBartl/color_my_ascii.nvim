---@module 'color_my_ascii.commands.fence.util'
---@brief Shared helpers for the `:Fence` subcommands.

local M = {}

local api = vim.api

--- The fenced block under the cursor (interior + fence lines count as "under").
---@param opts? table Extra opts forwarded to fences.block_at
---@return integer bufnr
---@return table|nil block
function M.current_block(opts)
  local buf = api.nvim_get_current_buf()
  local row = api.nvim_win_get_cursor(0)[1] - 1
  local o = vim.tbl_extend('keep', opts or {}, { include_fence = true })
  local block = require('color_my_ascii.api.fences').block_at(buf, row, o)
  return buf, block
end

--- Interior content lines of a block.
---@param bufnr integer
---@param block table
---@return string[]
function M.content(bufnr, block)
  return api.nvim_buf_get_lines(bufnr, block.content_start, block.content_end, false)
end

--- Prefixed notify.
---@param msg string
---@param level? integer
function M.notify(msg, level)
  vim.notify('Fence: ' .. msg, level or vim.log.levels.INFO)
end

--- Fence-language tag -> file extension. Shared by export/open/run.
---@type table<string, string>
local EXT = {
  javascript = 'js',
  js = 'js',
  jsx = 'jsx',
  node = 'js',
  typescript = 'ts',
  ts = 'ts',
  tsx = 'tsx',
  python = 'py',
  py = 'py',
  lua = 'lua',
  c = 'c',
  cpp = 'cpp',
  ['c++'] = 'cpp',
  cxx = 'cpp',
  cc = 'cpp',
  csharp = 'cs',
  cs = 'cs',
  ['c#'] = 'cs',
  java = 'java',
  kotlin = 'kt',
  kt = 'kt',
  scala = 'scala',
  groovy = 'groovy',
  go = 'go',
  golang = 'go',
  rust = 'rs',
  rs = 'rs',
  zig = 'zig',
  ruby = 'rb',
  rb = 'rb',
  php = 'php',
  perl = 'pl',
  pl = 'pl',
  bash = 'sh',
  sh = 'sh',
  shell = 'sh',
  zsh = 'sh',
  fish = 'fish',
  powershell = 'ps1',
  ps1 = 'ps1',
  html = 'html',
  css = 'css',
  scss = 'scss',
  sass = 'sass',
  less = 'less',
  json = 'json',
  jsonc = 'jsonc',
  yaml = 'yaml',
  yml = 'yaml',
  toml = 'toml',
  xml = 'xml',
  sql = 'sql',
  graphql = 'graphql',
  proto = 'proto',
  markdown = 'md',
  md = 'md',
  mdx = 'mdx',
  tex = 'tex',
  rst = 'rst',
  vim = 'vim',
  viml = 'vim',
  vimscript = 'vim',
  haskell = 'hs',
  hs = 'hs',
  elixir = 'ex',
  ex = 'ex',
  erlang = 'erl',
  clojure = 'clj',
  clj = 'clj',
  elm = 'elm',
  ocaml = 'ml',
  fsharp = 'fs',
  swift = 'swift',
  dart = 'dart',
  r = 'r',
  julia = 'jl',
  jl = 'jl',
  dockerfile = 'dockerfile',
  docker = 'dockerfile',
  make = 'mk',
  makefile = 'mk',
  cmake = 'cmake',
  mermaid = 'mmd',
  dot = 'dot',
  graphviz = 'dot',
  nix = 'nix',
}

--- File extension for a fence language tag (honours fence_export.ext_map).
---@param lang string|nil
---@return string
function M.ext_for(lang)
  local key = type(lang) == 'string' and vim.trim(lang):lower() or ''
  local user = (require('color_my_ascii.config').get().fence_export or {}).ext_map or {}
  return user[key] or EXT[key] or 'txt'
end

--- Fence-language tag -> Vim filetype (for open/run window filetype). Falls back
--- to the tag itself, which already matches many filetypes.
---@type table<string, string>
local FT = {
  js = 'javascript',
  node = 'javascript',
  jsx = 'javascriptreact',
  ts = 'typescript',
  tsx = 'typescriptreact',
  py = 'python',
  rb = 'ruby',
  sh = 'sh',
  bash = 'sh',
  shell = 'sh',
  zsh = 'sh',
  ['c++'] = 'cpp',
  cxx = 'cpp',
  cc = 'cpp',
  cs = 'cs',
  csharp = 'cs',
  kt = 'kotlin',
  golang = 'go',
  rs = 'rust',
  pl = 'perl',
  viml = 'vim',
  vimscript = 'vim',
  hs = 'haskell',
  ex = 'elixir',
  clj = 'clojure',
  ps1 = 'ps1',
  powershell = 'ps1',
  md = 'markdown',
  yml = 'yaml',
  golang_ = 'go',
}
--- @param lang string|nil
--- @return string
function M.filetype_for(lang)
  local key = type(lang) == 'string' and vim.trim(lang):lower() or ''
  return FT[key] or key
end

--- Known fence language tags (for `lang`/`wrap` completion).
---@return string[]
function M.lang_tags()
  local set = {}
  local map = require('color_my_ascii.config').get().fence_language_map or {}
  for k in pairs(map) do
    set[k] = true
  end
  for k in pairs(EXT) do
    set[k] = true
  end
  local out = {}
  for k in pairs(set) do
    out[#out + 1] = k
  end
  table.sort(out)
  return out
end

return M
