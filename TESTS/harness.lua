-- TESTS/harness.lua — tiny assertion helper shared by the spec files.
-- Returned to each spec by TESTS/run.lua.

local H = {}

--- Assert equality; raises a descriptive error on mismatch (caught by the runner).
---@param a any # actual
---@param b any # expected
---@param msg string|nil
function H.eq(a, b, msg)
  if a ~= b then
    error(('FAIL %s: expected %q, got %q'):format(msg or '', tostring(b), tostring(a)), 2)
  end
end

--- Assert a truthy value.
---@param v any
---@param msg string|nil
function H.ok(v, msg)
  if not v then
    error(('FAIL %s: expected truthy, got %q'):format(msg or '', tostring(v)), 2)
  end
end

--- Fresh scratch buffer, made current, with an optional filetype and lines.
---@param ft string|nil
---@param lines string[]|nil
---@return integer bufnr
function H.scratch(ft, lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  if ft then
    vim.bo[buf].filetype = ft
  end
  if lines then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end
  return buf
end

--- Every extmark of a named namespace in `bufnr`, as
--- `{ row, col, end_col, hl }` records sorted by (row, col, end_col).
---
--- Highlighting here *is* extmark positions, and a position is a **byte**
--- offset -- so the specs assert the marks themselves rather than "the call
--- returned true". Sorted because `nvim_buf_get_extmarks` orders by mark id
--- within a row, which is creation order (the order of the highlighter's
--- passes), not column order.
---@param bufnr integer
---@param ns_name string Namespace name, e.g. "ColorMyAscii"
---@return { row: integer, col: integer, end_col: integer|nil, hl: string|nil }[]
function H.marks(bufnr, ns_name)
  local ns = vim.api.nvim_get_namespaces()[ns_name]
  if not ns then
    return {}
  end
  local out = {}
  for _, m in ipairs(vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, { details = true })) do
    out[#out + 1] = { row = m[2], col = m[3], end_col = m[4] and m[4].end_col, hl = m[4] and m[4].hl_group }
  end
  table.sort(out, function(a, b)
    if a.row ~= b.row then
      return a.row < b.row
    end
    if a.col ~= b.col then
      return a.col < b.col
    end
    return (a.end_col or -1) < (b.end_col or -1)
  end)
  return out
end

--- Whether `marks` holds a mark with exactly this row/col/end_col/hl.
---@param marks { row: integer, col: integer, end_col: integer|nil, hl: string|nil }[]
---@param row integer
---@param col integer
---@param end_col integer
---@param hl string
---@return boolean
function H.has_mark(marks, row, col, end_col, hl)
  for _, m in ipairs(marks) do
    if m.row == row and m.col == col and m.end_col == end_col and m.hl == hl then
      return true
    end
  end
  return false
end

--- Replace entries in `package.loaded` for the duration of `fn`.
---
--- Modules bind their dependencies to upvalues at load time, so patching a
--- field on an already-required module is too late: the seam has to sit in
--- `package.loaded` *before* the module under test is required. A key mapped to
--- `false` is unloaded rather than replaced, which is how a module gets
--- re-required against the stubs -- and, together with a `package.preload`
--- entry that raises, how an optional dependency is made to look "not
--- installed".
---@param modules table<string, table|false>
---@param fn fun()
---@return nil
function H.with_modules(modules, fn)
  local saved = {}
  for name, replacement in pairs(modules) do
    saved[name] = { value = package.loaded[name], had = package.loaded[name] ~= nil }
    package.loaded[name] = replacement or nil
  end

  local ok, err = pcall(fn)

  for name, entry in pairs(saved) do
    package.loaded[name] = entry.had and entry.value or nil
  end

  if not ok then
    error(err, 0)
  end
end

--- Run `fn` with `vim.notify` captured; returns the collected messages.
--- lib.nvim's notifier goes through `vim.notify` too, so this catches both.
---@param fn fun()
---@return { msg: string, level: integer|nil }[]
function H.capture_notify(fn)
  local seen = {}
  local original = vim.notify
  vim.notify = function(msg, level)
    seen[#seen + 1] = { msg = tostring(msg), level = level }
  end
  local ok, err = pcall(fn)
  vim.notify = original
  if not ok then
    error(err, 0)
  end
  return seen
end

--- Capture the notifications of a module that binds `vim.notify` to an upvalue.
---
--- Several modules here do `local notify = vim.notify` at load time, so
--- swapping `vim.notify` afterwards is never seen by them. The capture has to
--- be installed *before* the module is loaded -- so this unloads the named
--- modules, installs the capture, hands `fn` the freshly required ones, and
--- restores both afterwards.
---@param modnames string[]
---@param fn fun(mods: table<string, table>)
---@return { msg: string, level: integer|nil }[]
function H.reload_notify(modnames, fn)
  local seen = {}
  local original = vim.notify
  vim.notify = function(msg, level)
    seen[#seen + 1] = { msg = tostring(msg), level = level }
  end

  local unload = {}
  for _, name in ipairs(modnames) do
    unload[name] = false
  end

  local ok, err = pcall(function()
    H.with_modules(unload, function()
      local mods = {}
      for _, name in ipairs(modnames) do
        mods[name] = require(name)
      end
      fn(mods)
    end)
  end)

  vim.notify = original
  if not ok then
    error(err, 0)
  end
  return seen
end

--- Whether any captured notification contains `needle` (plain substring).
---@param seen { msg: string, level: integer|nil }[]
---@param needle string
---@return boolean
function H.notified(seen, needle)
  for _, entry in ipairs(seen) do
    if entry.msg:find(needle, 1, true) then
      return true
    end
  end
  return false
end

return H
