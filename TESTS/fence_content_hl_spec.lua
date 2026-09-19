-- docs/TESTS/fence_content_hl_spec.lua — fence interior (content) highlighting.
---@diagnostic disable: missing-fields

return function(H)
  local eq, ok = H.eq, H.ok
  local api = vim.api
  local fence_hl = require('color_my_ascii.fence_hl')

  local LINES = {
    '# Title', -- 0
    '', -- 1
    '```text', -- 2  non-ascii (unmapped lang)
    'plain text', -- 3
    '```', -- 4
    '', -- 5
    '```ascii-c', -- 6  ascii
    '+--+', -- 7
    '', -- 8  blank content row - must still be painted
    '```', -- 9
  }

  local ns = api.nvim_create_namespace('ColorMyAsciiFenceLine')
  local function rows(buf)
    local set = {}
    for _, m in ipairs(api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })) do
      set[m[2]] = m[4].line_hl_group or m[4].hl_group or set[m[2]] or true
    end
    return set
  end

  -- default config: content highlight on by default, line highlight also on by default
  do
    require('color_my_ascii.config').setup({})
    fence_hl.setup_hl(require('color_my_ascii.config').get())
    local buf = H.scratch('markdown', LINES)
    fence_hl.apply(buf, require('color_my_ascii.config').get())
    local r = rows(buf)
    ok(r[3] ~= nil, 'default: text-block content row painted')
    ok(r[7] ~= nil, 'default: ascii-block content row painted')
    ok(r[8] ~= nil, 'default: blank content row painted (whole-line bg, not just chars)')
    eq(r[3], 'ColorMyAsciiFenceContent', 'content row uses content group')
    api.nvim_buf_delete(buf, { force = true })
  end

  -- enable = false -> no content marks, line marks still present
  do
    require('color_my_ascii.config').setup({
      fence_content_highlight = { enable = false },
    })
    fence_hl.setup_hl(require('color_my_ascii.config').get())
    local buf = H.scratch('markdown', LINES)
    fence_hl.apply(buf, require('color_my_ascii.config').get())
    local r = rows(buf)
    ok(r[3] == nil and r[7] == nil, 'disabled: content rows not painted')
    ok(r[2] ~= nil, 'disabled: fence-line highlight unaffected')
    api.nvim_buf_delete(buf, { force = true })
  end

  -- apply_to = "ascii" -> only ascii block content painted
  do
    require('color_my_ascii.config').setup({
      fence_content_highlight = { enable = true, apply_to = 'ascii' },
    })
    fence_hl.setup_hl(require('color_my_ascii.config').get())
    local buf = H.scratch('markdown', LINES)
    fence_hl.apply(buf, require('color_my_ascii.config').get())
    local r = rows(buf)
    ok(r[3] == nil, 'apply_to=ascii: non-ascii content not painted')
    ok(r[7] ~= nil, 'apply_to=ascii: ascii content painted')
    api.nvim_buf_delete(buf, { force = true })
  end

  -- explicit hl override bypasses shading entirely
  do
    require('color_my_ascii.config').setup({
      fence_content_highlight = { enable = true, hl = { bg = '#123456' } },
    })
    fence_hl.setup_hl(require('color_my_ascii.config').get())
    local hl = api.nvim_get_hl(0, { name = 'ColorMyAsciiFenceContent' })
    eq(string.format('#%06x', hl.bg), '#123456', 'hl override sets exact bg')
  end

  -- shade = "none" uses the resolved base color unshaded
  do
    require('color_my_ascii.config').setup({
      fence_line_highlight = { enable = true, preset = 'catppuccin' },
      fence_content_highlight = { enable = true, shade = 'none' },
    })
    fence_hl.setup_hl(require('color_my_ascii.config').get())
    local themes = require('color_my_ascii.theme_presets')
    local hl = api.nvim_get_hl(0, { name = 'ColorMyAsciiFenceContent' })
    eq(string.format('#%06x', hl.bg), themes.presets.catppuccin.bg, 'shade=none matches base preset bg exactly')
  end

  -- shade = "darken" actually darkens relative to the resolved base color
  do
    require('color_my_ascii.config').setup({
      fence_line_highlight = { enable = true, preset = 'catppuccin' },
      fence_content_highlight = { enable = true, shade = 'darken', amount = 20 },
    })
    fence_hl.setup_hl(require('color_my_ascii.config').get())
    local themes = require('color_my_ascii.theme_presets')
    local base = themes.presets.catppuccin.bg
    local hl = api.nvim_get_hl(0, { name = 'ColorMyAsciiFenceContent' })
    local shaded = string.format('#%06x', hl.bg)
    ok(shaded ~= base, 'darken: shaded color differs from base')
    local color = require('color_my_ascii.utils.color')
    ---@cast base -nil
    local br, bg_, bb = color.hex_to_rgb(base)
    local sr, sg, sb = color.hex_to_rgb(shaded)
    ok(
      br ~= nil and sr ~= nil and sr <= br and sg <= bg_ and sb <= bb,
      'darken: shaded rgb components are not brighter than base'
    )
  end

  -- shade = "auto" (the default -- `fch.shade or 'auto'`) picks the direction
  -- from 'background': dark backgrounds shade toward black, light ones toward
  -- white. Neither direction is exercised by the explicit shade='darken' case
  -- above, which bypasses this decision entirely.
  do
    local saved_bg = vim.o.background
    local color = require('color_my_ascii.utils.color')

    vim.o.background = 'dark'
    require('color_my_ascii.config').setup({
      fence_line_highlight = { enable = true, preset = 'catppuccin' },
      fence_content_highlight = { enable = true, amount = 20 }, -- shade omitted -> 'auto'
    })
    fence_hl.setup_hl(require('color_my_ascii.config').get())
    local themes = require('color_my_ascii.theme_presets')
    local base = themes.presets.catppuccin.bg
    local dark_hl = api.nvim_get_hl(0, { name = 'ColorMyAsciiFenceContent' })
    local dark_shaded = string.format('#%06x', dark_hl.bg)
    local br, bg_, bb = color.hex_to_rgb(base)
    local dr, dg, db = color.hex_to_rgb(dark_shaded)
    ok(
      dr ~= nil and dr <= br and dg <= bg_ and db <= bb,
      "auto on a dark background darkens, same as an explicit shade = 'darken'"
    )

    vim.o.background = 'light'
    fence_hl.setup_hl(require('color_my_ascii.config').get())
    local light_hl = api.nvim_get_hl(0, { name = 'ColorMyAsciiFenceContent' })
    local light_shaded = string.format('#%06x', light_hl.bg)
    local lr, lg, lb = color.hex_to_rgb(light_shaded)
    ok(
      lr ~= nil and lr >= br and lg >= bg_ and lb >= bb,
      "auto on a light background lightens instead, same as an explicit shade = 'lighten'"
    )

    vim.o.background = saved_bg
  end

  -- An invalid (non-numeric) `amount` degrades to the default of 6 rather
  -- than raising ahead of the pcall in M.setup_hl's caller -- `color.shade`'s
  -- own `math.min(100, percent)` throws on a non-number, so the guard has to
  -- sit at the call site, before that comparison ever runs (ERR-22).
  do
    require('color_my_ascii.config').setup({
      fence_line_highlight = { enable = true, preset = 'catppuccin' },
      fence_content_highlight = { enable = true, shade = 'darken', amount = '6%' },
    })
    local setup_ok = pcall(fence_hl.setup_hl, require('color_my_ascii.config').get())
    ok(setup_ok, 'an invalid amount does not raise')

    local themes = require('color_my_ascii.theme_presets')
    local base = themes.presets.catppuccin.bg
    local hl = api.nvim_get_hl(0, { name = 'ColorMyAsciiFenceContent' })
    local shaded = string.format('#%06x', hl.bg)
    ok(shaded ~= base, 'invalid amount still shades, using the default of 6 instead of aborting')
  end

  require('color_my_ascii.config').setup({})
end
