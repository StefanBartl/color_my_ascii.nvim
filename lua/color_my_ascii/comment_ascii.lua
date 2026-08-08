---@module 'color_my_ascii.comment_ascii'
---@brief Detect explicitly-marked ASCII blocks inside code comments.
---@description
--- Outside markdown there's no ``` fence syntax to anchor an ASCII block to,
--- so this uses an explicit marker instead: a comment line whose trimmed,
--- comment-prefix-stripped text is exactly "ascii" (optionally
--- "ascii-<lang>"/"ascii:<lang>"/"ascii <lang>", same as a markdown fence
--- tag), up to a matching "/ascii" line - the same open/close symmetry as a
--- markdown fence, just spelled with the buffer's own line-comment prefix
--- (`vim.bo.commentstring`) instead of backticks:
---
---   -- ascii
---   -- ┌────┐
---   -- │ hi │
---   -- └────┘
---   -- /ascii
---
--- Returns blocks in the same shape parser.lua's markdown scanner does
--- (start_line/end_line/lines/fence_line), so the existing highlighter
--- highlights them unchanged - see `parser.find_ascii_blocks`, which
--- dispatches here for buffers whose filetype is in
--- `config.comment_ascii.filetypes`.
---
--- Deliberately narrow v1 scope: only single-line comment syntax (the
--- `commentstring` prefix before "%s"), not block comments (`/* ... */`).
--- Detection is a plain per-line prefix scan, not a treesitter comment-node
--- query - simpler, and works even without a treesitter parser installed for
--- the target language (only the highlighting pass, not the block
--- detection, benefits from treesitter being available).

local M = {}

--- The buffer's line-comment prefix (e.g. "--", "#", "//"), derived from
--- 'commentstring'. nil if the buffer's commentstring isn't a simple
--- "prefix %s" shape (covers the vast majority of languages; block-comment-
--- only commentstrings, e.g. "/*%s*/", aren't supported).
---@param bufnr integer
---@return string|nil prefix
local function comment_prefix(bufnr)
  local cs = vim.bo[bufnr].commentstring
  if type(cs) ~= 'string' or cs == '' then
    return nil
  end
  local prefix = cs:match('^(.-)%%s')
  if not prefix then
    return nil
  end
  prefix = vim.trim(prefix)
  if prefix == '' then
    return nil
  end
  return prefix
end

--- Strip a line's leading indentation and comment prefix.
---@internal
---@param line string
---@param prefix string
---@return string|nil rest nil if `line` isn't a comment line with this prefix
local function strip_comment(line, prefix)
  local indent, rest = line:match('^(%s*)(.*)$')
  if not indent then
    return nil
  end
  if rest:sub(1, #prefix) ~= prefix then
    return nil
  end
  rest = rest:sub(#prefix + 1)
  -- drop exactly one conventional space after the comment prefix ("-- text")
  if rest:sub(1, 1) == ' ' then
    rest = rest:sub(2)
  end
  return rest
end

--- Whether a stripped comment line is an opening "ascii" marker.
---@internal
---@param stripped string
---@return boolean
local function is_open_marker(stripped)
  return vim.trim(stripped):match('^ascii') ~= nil
end

--- Whether a stripped comment line is the closing "/ascii" marker.
---@internal
---@param stripped string
---@return boolean
local function is_close_marker(stripped)
  return vim.trim(stripped) == '/ascii'
end

--- Find every `-- ascii` … `-- /ascii` block in the buffer.
---@param bufnr integer
---@return ColorMyAscii.Block[]
function M.find_blocks(bufnr)
  local prefix = comment_prefix(bufnr)
  if not prefix then
    return {}
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local n = #lines
  local blocks = {}
  local i = 1

  while i <= n do
    local stripped = strip_comment(lines[i], prefix)
    if stripped and is_open_marker(stripped) then
      local content = {}
      local j = i + 1
      local closed = false
      while j <= n do
        local s = strip_comment(lines[j], prefix)
        if not s then
          break -- a non-comment line ends the block unclosed
        end
        if is_close_marker(s) then
          closed = true
          break
        end
        content[#content + 1] = s
        j = j + 1
      end

      if closed then
        blocks[#blocks + 1] = {
          start_line = i - 1, -- 0-indexed, matches ColorMyAscii.Block
          end_line = j - 1,
          lines = content,
          fence_line = stripped, -- e.g. "ascii-lua", for language_detector's explicit-marker pass
        }
        i = j + 1
      else
        i = i + 1
      end
    else
      i = i + 1
    end
  end

  return blocks
end

return M
