-- docs/TESTS/fence_hl_spec.lua — fence delimiter line highlighting.
---@diagnostic disable: missing-fields

return function(H)
  local eq, ok = H.eq, H.ok
  local api = vim.api
  local fence_hl = require("color_my_ascii.fence_hl")

  local LINES = {
    "# Title",     -- 0
    "",            -- 1
    "```text",     -- 2  non-ascii (unmapped lang)
    "plain text",  -- 3
    "```",         -- 4
    "",            -- 5
    "```ascii-c",  -- 6  ascii
    "+--+",        -- 7
    "```",         -- 8
  }

  local ns = api.nvim_create_namespace("ColorMyAsciiFenceLine")
  local function rows(buf)
    local set = {}
    for _, m in ipairs(api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })) do
      set[m[2]] = m[4].line_hl_group or true
    end
    return set
  end

  -- apply_to = "all"
  require("color_my_ascii.config").setup({
    fence_line_highlight = { enable = true, preset = "accent", apply_to = "all" },
  })
  fence_hl.setup_hl(require("color_my_ascii.config").get())
  do
    local buf = H.scratch("markdown", LINES)
    fence_hl.apply(buf, require("color_my_ascii.config").get())
    local r = rows(buf)
    ok(r[2] ~= nil and r[4] ~= nil, "all: text fence open+close highlighted")
    ok(r[6] ~= nil and r[8] ~= nil, "all: ascii fence open+close highlighted")
    ok(r[3] == nil, "all: content line not highlighted")
    eq(r[2], "ColorMyAsciiFenceOpen", "all: open uses open group")
    eq(r[4], "ColorMyAsciiFenceClose", "all: close uses close group")
    api.nvim_buf_delete(buf, { force = true })
  end

  -- apply_to = "ascii"
  require("color_my_ascii.config").setup({
    fence_line_highlight = { enable = true, preset = "subtle", apply_to = "ascii" },
  })
  fence_hl.setup_hl(require("color_my_ascii.config").get())
  do
    local buf = H.scratch("markdown", LINES)
    fence_hl.apply(buf, require("color_my_ascii.config").get())
    local r = rows(buf)
    ok(r[2] == nil, "ascii: non-ascii text fence not highlighted")
    ok(r[6] ~= nil and r[8] ~= nil, "ascii: ascii fence highlighted")
    api.nvim_buf_delete(buf, { force = true })
  end

  -- disabled -> clears
  do
    local buf = H.scratch("markdown", LINES)
    fence_hl.apply(buf, { fence_line_highlight = { enable = true, apply_to = "all" } })
    ok(next(rows(buf)) ~= nil, "marks present before disable")
    fence_hl.apply(buf, { fence_line_highlight = { enable = false } })
    ok(next(rows(buf)) == nil, "marks cleared when disabled")
    api.nvim_buf_delete(buf, { force = true })
  end

  -- overrides: string group + attr table
  require("color_my_ascii.config").setup({
    fence_line_highlight = { enable = true, open = "Comment", close = { bg = "#331111" }, apply_to = "all" },
  })
  fence_hl.setup_hl(require("color_my_ascii.config").get())
  do
    local close_hl = api.nvim_get_hl(0, { name = "ColorMyAsciiFenceClose" })
    ok(close_hl.bg ~= nil, "override: close group has custom bg")
  end

  -- preset = a theme name -> uses that theme's hand-tuned palette
  require("color_my_ascii.config").setup({
    fence_line_highlight = { enable = true, preset = "catppuccin", apply_to = "all" },
  })
  fence_hl.setup_hl(require("color_my_ascii.config").get())
  do
    local themes = require("color_my_ascii.theme_presets")
    local open_hl = api.nvim_get_hl(0, { name = "ColorMyAsciiFenceOpen" })
    eq(string.format("#%06x", open_hl.bg), themes.presets.catppuccin.bg, "theme preset applies catppuccin bg")
  end

  -- preset = "auto" -> matches the current colorscheme name by substring
  do
    local themes = require("color_my_ascii.theme_presets")
    local saved_name, saved_bg = vim.g.colors_name, vim.o.background
    vim.g.colors_name = "tokyonight-storm"
    vim.o.background = "dark"
    require("color_my_ascii.config").setup({
      fence_line_highlight = { enable = true, preset = "auto", apply_to = "all" },
    })
    fence_hl.setup_hl(require("color_my_ascii.config").get())
    local open_hl = api.nvim_get_hl(0, { name = "ColorMyAsciiFenceOpen" })
    eq(string.format("#%06x", open_hl.bg), themes.presets.tokyonight.bg, "auto matches tokyonight variant")

    -- auto with an unknown theme -> falls back to the generic 'subtle' link
    vim.g.colors_name = "some-unknown-theme-xyz"
    fence_hl.setup_hl(require("color_my_ascii.config").get())
    local fallback = api.nvim_get_hl(0, { name = "ColorMyAsciiFenceOpen", link = true })
    ok(fallback.link == "CursorLine", "auto falls back to subtle (CursorLine) on no match")

    vim.g.colors_name = saved_name
    vim.o.background = saved_bg
  end

  require("color_my_ascii.config").setup({})
end
