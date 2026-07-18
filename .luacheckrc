-- Luacheck configuration for color_my_ascii.nvim
-- Neovim plugin: runs inside Neovim's LuaJIT runtime with the `vim` global.

std = 'luajit'
cache = true

-- `vim` is writable: plugins legitimately set vim.g.*, vim.bo[b].*, etc.
globals = {
  'vim',
}

-- Line width is owned by stylua (.stylua.toml, column_width = 120). Disabling the
-- redundant luacheck length check keeps it from flagging the long doc annotations
-- and user-facing strings stylua intentionally leaves unwrapped.
max_line_length = false

ignore = {
  '212', -- unused argument (callbacks keep their documented signature)
}
