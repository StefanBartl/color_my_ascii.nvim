---@module 'color_my_ascii.api.fences'
--- Public, stable fenced-code-block API for other plugins to consume.
---
--- color_my_ascii owns the most robust fenced-block detection in the ecosystem
--- (heuristic state machine + treesitter, with CommonMark-compatible fence
--- length matching). This module exposes that intelligence in a language-
--- agnostic way so consumers like markdown.nvim can treat a fenced block as its
--- own scope without reimplementing fence parsing.
---
--- Everything here returns/operates on ColorMyAscii.FenceBlock descriptors
--- (see @types.lua): 0-indexed rows, half-open content range
--- `[content_start, content_end)`, plus lang/fence metadata.
---
--- Range-only queries (the common case: scope resolution, fence highlighting)
--- are cached per (buffer, changedtick); pass `lines ~= "none"` only when you
--- actually need block content (bypasses the cache).

local M = {}

local api = vim.api
local autocmd = require('lib.nvim.autocmd')

--- Default markdown-family fence tags treated as "a markdown sub-document".
---@type table<string, boolean>
local DEFAULT_MARKDOWN_LANGS = {
  markdown = true,
  md = true,
  mdx = true,
  ['ascii-markdown'] = true,
  ['ascii-md'] = true,
}

--- Range-only block cache: bufnr -> { tick = changedtick, blocks = FenceBlock[] }.
---@type table<integer, { tick: integer, blocks: ColorMyAscii.FenceBlock[] }>
local cache = {}

local cache_augroup = autocmd.augroup.create.clear('ColorMyAsciiFenceApiCache')
autocmd.create({ 'BufDelete', 'BufWipeout' }, function(ev)
  cache[ev.buf] = nil
end, {
  group = cache_augroup,
  desc = 'Invalidate color_my_ascii fence API cache on buffer delete',
})

--- Classify a fence language tag as markdown-family (case-insensitive).
---@param lang string|nil Fence language tag
---@param extra? table<string, boolean> Extra lowercase tags to also treat as markdown
---@return boolean
function M.is_markdown_lang(lang, extra)
  if type(lang) ~= 'string' then
    return false
  end
  local key = vim.trim(lang):lower()
  if key == '' then
    return false
  end
  if DEFAULT_MARKDOWN_LANGS[key] then
    return true
  end
  if extra and extra[key] then
    return true
  end
  return false
end

--- Normalize an optional lang filter (string | string[] | nil) into a lowercase set.
---@internal
---@param lang string|string[]|nil
---@return table<string, boolean>|nil set nil = no language filtering
local function build_lang_set(lang)
  if lang == nil then
    return nil
  end
  local set = {}
  if type(lang) == 'string' then
    set[lang:lower()] = true
  elseif type(lang) == 'table' then
    for _, l in ipairs(lang) do
      if type(l) == 'string' then
        set[l:lower()] = true
      end
    end
  end
  return set
end

--- Get the cached range-only block list for a buffer, (re)scanning on a stale
--- or missing changedtick.
---@internal
---@param bufnr integer
---@return ColorMyAscii.FenceBlock[]
local function scan_cached(bufnr)
  local tick = api.nvim_buf_get_changedtick(bufnr)
  local entry = cache[bufnr]
  if entry and entry.tick == tick then
    return entry.blocks
  end
  local blocks = require('color_my_ascii.parser').find_all_blocks(bufnr, { lines = 'none' })
  cache[bufnr] = { tick = tick, blocks = blocks }
  return blocks
end

--- List fenced code blocks in a buffer.
---
--- Blocks are returned in document order. When neither `lang`/`markdown` nor
--- `filter` is given, every fenced block is returned.
---@param bufnr? integer Buffer (default: current)
---@param opts? { lines?: "none"|"ascii"|"all", lang?: string|string[], markdown?: boolean, markdown_extra?: table<string, boolean>, filter?: fun(block: ColorMyAscii.FenceBlock): boolean }
---@return ColorMyAscii.FenceBlock[] blocks
function M.list_blocks(bufnr, opts)
  bufnr = bufnr or api.nvim_get_current_buf()
  opts = opts or {}

  local lines_mode = opts.lines or 'none'
  local source
  if lines_mode == 'none' then
    source = scan_cached(bufnr)
  else
    source = require('color_my_ascii.parser').find_all_blocks(bufnr, { lines = lines_mode })
  end

  local lang_set = build_lang_set(opts.lang)
  local want_md = opts.markdown == true
  local md_extra = opts.markdown_extra
  local user_filter = opts.filter

  if not lang_set and not want_md and not user_filter then
    return source
  end

  local out = {}
  for _, b in ipairs(source) do
    local keep = true
    if lang_set and not lang_set[(b.lang or ''):lower()] then
      keep = false
    end
    if keep and want_md and not M.is_markdown_lang(b.lang, md_extra) then
      keep = false
    end
    if keep and user_filter and not user_filter(b) then
      keep = false
    end
    if keep then
      out[#out + 1] = b
    end
  end
  return out
end

--- Return the innermost fenced block containing `row`, or nil.
---
--- By default only the block *interior* counts as "containing" the row (the
--- opening/closing fence delimiter lines are considered outside); pass
--- `include_fence = true` to also match when the cursor sits on a delimiter.
--- Empty blocks (no interior rows) can only be matched with `include_fence`.
---@param bufnr? integer Buffer (default: current)
---@param row? integer 0-indexed row (default: current cursor row)
---@param opts? { lang?: string|string[], markdown?: boolean, markdown_extra?: table<string, boolean>, include_fence?: boolean, filter?: fun(block: ColorMyAscii.FenceBlock): boolean }
---@return ColorMyAscii.FenceBlock|nil block
function M.block_at(bufnr, row, opts)
  bufnr = bufnr or api.nvim_get_current_buf()
  if row == nil then
    row = api.nvim_win_get_cursor(0)[1] - 1
  end
  opts = opts or {}

  local include_fence = opts.include_fence == true
  local blocks = M.list_blocks(bufnr, {
    lines = 'none',
    lang = opts.lang,
    markdown = opts.markdown,
    markdown_extra = opts.markdown_extra,
    filter = opts.filter,
  })

  local best = nil
  for _, b in ipairs(blocks) do
    local lo, hi
    if include_fence then
      lo, hi = b.open_row, b.close_row
    else
      lo, hi = b.content_start, b.content_end - 1 -- interior rows only
    end
    if row >= lo and row <= hi then
      -- Prefer the tightest enclosing block (robust if blocks ever nest).
      if not best or (b.close_row - b.open_row) < (best.close_row - best.open_row) then
        best = b
      end
    end
  end
  return best
end

--- Drop the cached block list for a buffer (or all buffers). Mostly useful for
--- tests; normal invalidation is automatic via changedtick + BufDelete.
---@param bufnr? integer nil = clear every buffer
---@return nil
function M.invalidate(bufnr)
  if bufnr == nil then
    cache = {}
  else
    cache[bufnr] = nil
  end
end

return M
