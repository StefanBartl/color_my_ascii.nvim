-- TESTS/fence_export_spec.lua — :Fence export + dispatcher tokenizer.
---@diagnostic disable: missing-fields

return function(H)
  local eq, ok = H.eq, H.ok
  local api = vim.api

  require("color_my_ascii.config").setup({})
  local fence = require("color_my_ascii.commands.fence")
  local export = require("color_my_ascii.commands.fence.export")

  -- ---- tokenizer (quotes) --------------------------------------------------
  do
    local t = fence.tokenize([[export "my dir/a.js" --open]])
    eq(t[1], "export", "tok: subcommand")
    eq(t[2], "my dir/a.js", "tok: double-quoted path with space")
    eq(t[3], "--open", "tok: flag")

    local t2 = fence.tokenize([[export 'x y.py']])
    eq(t2[2], "x y.py", "tok: single-quoted path")

    local t3 = fence.tokenize([[export bare/path.lua]])
    eq(t3[2], "bare/path.lua", "tok: bare path")
  end

  -- ---- completion ----------------------------------------------------------
  do
    local subs = fence.complete("", "Fence ", 6)
    ok(vim.tbl_contains(subs, "export"), "complete: subcommand list")
    local flags = fence.complete("--", "Fence export --", 15)
    ok(vim.tbl_contains(flags, "--open") and vim.tbl_contains(flags, "--replace"), "complete: flags")
  end

  -- ---- export writes the block content to a file ---------------------------
  local tmp = vim.fn.tempname() .. "_cma_fence_export"
  vim.fn.mkdir(tmp, "p")

  local buf = H.scratch("markdown", {
    "# Doc",                 -- 1
    "",                      -- 2
    "```javascript",         -- 3
    "let a = 0;",            -- 4
    "console.log(a);",       -- 5
    "```",                   -- 6
    "",                      -- 7
    "after",                 -- 8
  })
  api.nvim_win_set_cursor(0, { 4, 0 }) -- inside the JS block

  local out = tmp .. "/snippet.js"
  export.run({ out })
  ok(vim.fn.filereadable(out) == 1, "export: file written")
  local written = vim.fn.readfile(out)
  eq(written[1], "let a = 0;", "export: first content line")
  eq(written[2], "console.log(a);", "export: second content line")
  eq(#written, 2, "export: only fence interior (no markers)")

  -- ---- --replace swaps the block for a link reference ----------------------
  api.nvim_win_set_cursor(0, { 4, 0 })
  export.run({ tmp .. "/snip2.js", "--replace" })
  local L = api.nvim_buf_get_lines(buf, 0, -1, false)
  local joined = table.concat(L, "\n")
  ok(not joined:find("```javascript", 1, true), "replace: fence removed")
  ok(joined:find("[snip2.js]", 1, true) ~= nil, "replace: link reference inserted")
  ok(joined:find("after", 1, true) ~= nil, "replace: surrounding text preserved")

  -- ---- no fence under cursor is a no-op (no error) -------------------------
  api.nvim_win_set_cursor(0, { 1, 0 }) -- on "# Doc"
  local okrun = pcall(export.run, { tmp .. "/never.js" })
  ok(okrun, "no-fence: does not error")
  ok(vim.fn.filereadable(tmp .. "/never.js") == 0, "no-fence: nothing written")

  api.nvim_buf_delete(buf, { force = true })
  vim.fn.delete(tmp, "rf")
  require("color_my_ascii.config").setup({})
end
