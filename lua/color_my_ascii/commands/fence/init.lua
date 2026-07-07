---@module 'color_my_ascii.commands.fence'
---@brief Buffer-local `:Fence <sub> [args]` dispatcher.
---@description
--- Actions on the fenced code block under the cursor, built on the public fence
--- API (color_my_ascii.api.fences). Registered buffer-local in markdown buffers
--- so the short `:Fence` name doesn't pollute the global command namespace.
--- Extensible: add an entry to SUBCOMMANDS.

local M = {}

local api = vim.api

--- Split a raw argument string into tokens, honouring single/double quotes so
--- paths with spaces survive (`:Fence export "my dir/a.js"`).
---@param s string
---@return string[]
function M.tokenize(s)
  local tokens = {}
  local i, n = 1, #s
  while i <= n do
    local ws = s:match("^%s+", i)
    if ws then i = i + #ws end
    if i > n then break end
    local c = s:sub(i, i)
    if c == '"' or c == "'" then
      local close = s:find(c, i + 1, true)
      if close then
        tokens[#tokens + 1] = s:sub(i + 1, close - 1)
        i = close + 1
      else
        tokens[#tokens + 1] = s:sub(i + 1) -- unterminated quote: take the rest
        break
      end
    else
      local tok = s:match("^%S+", i)
      tokens[#tokens + 1] = tok
      i = i + #tok
    end
  end
  return tokens
end

--- Subcommand table: name -> fun(argv: string[]).
local SUBCOMMANDS = {
  export = function(argv) require("color_my_ascii.commands.fence.export").run(argv) end,
}

--- The subcommand names, for usage/completion.
---@return string[]
local function sub_names()
  local names = {}
  for k in pairs(SUBCOMMANDS) do names[#names + 1] = k end
  table.sort(names)
  return names
end

--- Run `:Fence {args}`.
---@param args string Raw argument string (everything after `:Fence`).
function M.execute(args)
  local tokens = M.tokenize(args or "")
  local sub = tokens[1]
  if not sub then
    vim.notify("Usage: :Fence " .. table.concat(sub_names(), "|") .. " [args]", vim.log.levels.INFO)
    return
  end
  local handler = SUBCOMMANDS[sub]
  if not handler then
    vim.notify("Unknown :Fence subcommand: " .. sub, vim.log.levels.WARN)
    return
  end
  local argv = {}
  for j = 2, #tokens do argv[#argv + 1] = tokens[j] end
  handler(argv)
end

local function starts_with(s, prefix)
  return s:sub(1, #prefix) == prefix
end

local function filter_prefix(items, arglead)
  local out = {}
  for _, it in ipairs(items) do
    if starts_with(it, arglead) then out[#out + 1] = it end
  end
  return out
end

--- Command-line completion for `:Fence`.
---@param arglead string
---@param cmdline string
---@return string[]
function M.complete(arglead, cmdline, _)
  local toks = vim.split(vim.trim(cmdline), "%s+")
  -- toks[1] == "Fence"; toks[2] == subcommand (if any)
  local on_subcommand = (#toks <= 1) or (#toks == 2 and arglead ~= "")
  if on_subcommand then
    return filter_prefix(sub_names(), arglead)
  end

  local sub = toks[2]
  if sub == "export" then
    if starts_with(arglead, "-") then
      return filter_prefix({ "--open", "--replace" }, arglead)
    end
    return vim.fn.getcompletion(arglead, "file")
  end
  return {}
end

--- Register the buffer-local `:Fence` command for `bufnr` (idempotent).
---@param bufnr integer
---@return nil
function M.register(bufnr)
  if type(bufnr) ~= "number" or not api.nvim_buf_is_valid(bufnr) then return end
  local ok, cmds = pcall(api.nvim_buf_get_commands, bufnr, {})
  if ok and cmds and cmds["Fence"] then return end

  api.nvim_buf_create_user_command(bufnr, "Fence", function(o)
    M.execute(o.args)
  end, {
    nargs = "*",
    complete = function(arglead, cmdline, cursorpos)
      return M.complete(arglead, cmdline, cursorpos)
    end,
    desc = "[color_my_ascii] Actions on the fenced block under the cursor (export, ...)",
  })
end

return M
