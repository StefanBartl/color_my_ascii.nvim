-- docs/TESTS/fence_content_hl_spec.lua — fence interior (content) highlighting.
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
    "",            -- 8  blank content row - must still be painted
    "```",         -- 9
  }

  local ns = api.nvim_create_namespace("ColorMyAsciiFenceLine")
  local function rows(buf)
    local set = {}
    for _, m in ipairs(api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })) do
      set[m[2]] = m[4].line_hl_group or true
    end
    return set
  end

  -- default config: content highlight on by default, line highlight also on by default
  do
    require("color_my_ascii.config").setup({})
    fence_hl.setup_hl(require("color_my_ascii.config").get())
    local buf = H.scratch("markdown", LINES)
    fence_hl.apply(buf, require("color_my_ascii.config").get())
    local r = rows(buf)
    ok(r[3] ~= nil, "default: text-block content row painted")
    ok(r[7] ~= nil, "default: ascii-block content row painted")
    ok(r[8] ~= nil, "default: blank content row painted (whole-line bg, not just chars)")
    eq(r[3], "ColorMyAsciiFenceContent", "content row uses content group")
    api.nvim_buf_delete(buf, { force = true })
  end

  -- enable = false -> no content marks, line marks still present
  do
    require("color_my_ascii.config").setup({
      fence_content_highlight = { enable = false },
    })
    fence_hl.setup_hl(require("color_my_ascii.config").get())
    local buf = H.scratch("markdown", LINES)
    fence_hl.apply(buf, require("color_my_ascii.config").get())
    local r = rows(buf)
    ok(r[3] == nil and r[7] == nil, "disabled: content rows not painted")
    ok(r[2] ~= nil, "disabled: fence-line highlight unaffected")
    api.nvim_buf_delete(buf, { force = true })
  end

  -- apply_to = "ascii" -> only ascii block content painted
  do
    require("color_my_ascii.config").setup({
      fence_content_highlight = { enable = true, apply_to = "ascii" },
    })
    fence_hl.setup_hl(require("color_my_ascii.config").get())
    local buf = H.scratch("markdown", LINES)
    fence_hl.apply(buf, require("color_my_ascii.config").get())
    local r = rows(buf)
    ok(r[3] == nil, "apply_to=ascii: non-ascii content not painted")
    ok(r[7] ~= nil, "apply_to=ascii: ascii content painted")
    api.nvim_buf_delete(buf, { force = true })
  end

  -- explicit hl override bypasses shading entirely
  do
    require("color_my_ascii.config").setup({
      fence_content_highlight = { enable = true, hl = { bg = "#123456" } },
    })
    fence_hl.setup_hl(require("color_my_ascii.config").get())
    local hl = api.nvim_get_hl(0, { name = "ColorMyAsciiFenceContent" })
    eq(string.format("#%06x", hl.bg), "#123456", "hl override sets exact bg")
  end

  -- shade = "none" uses the resolved base color unshaded
  do
    require("color_my_ascii.config").setup({
      fence_line_highlight = { enable = true, preset = "catppuccin" },
      fence_content_highlight = { enable = true, shade = "none" },
    })
    fence_hl.setup_hl(require("color_my_ascii.config").get())
    local themes = require("color_my_ascii.theme_presets")
    local hl = api.nvim_get_hl(0, { name = "ColorMyAsciiFenceContent" })
    eq(string.format("#%06x", hl.bg), themes.presets.catppuccin.bg, "shade=none matches base preset bg exactly")
  end

  -- shade = "darken" actually darkens relative to the resolved base color
  do
    require("color_my_ascii.config").setup({
      fence_line_highlight = { enable = true, preset = "catppuccin" },
      fence_content_highlight = { enable = true, shade = "darken", amount = 20 },
    })
    fence_hl.setup_hl(require("color_my_ascii.config").get())
    local themes = require("color_my_ascii.theme_presets")
    local base = themes.presets.catppuccin.bg
    local hl = api.nvim_get_hl(0, { name = "ColorMyAsciiFenceContent" })
    local shaded = string.format("#%06x", hl.bg)
    ok(shaded ~= base, "darken: shaded color differs from base")
    local color = require("color_my_ascii.utils.color")
    local br, bg_, bb = color.hex_to_rgb(base)
    local sr, sg, sb = color.hex_to_rgb(shaded)
    ok(br ~= nil and sr ~= nil and sr <= br and sg <= bg_ and sb <= bb,
      "darken: shaded rgb components are not brighter than base")
  end

  require("color_my_ascii.config").setup({})
end
