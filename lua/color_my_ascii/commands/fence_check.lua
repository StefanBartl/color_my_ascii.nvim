---@module 'color_my_ascii.commands.fence_check'
--- Provides a user command to detect unmatched fenced code blocks in the current buffer.
---
--- Fence matching rules:
---   - A fence with language (```lang) is always an opening fence
---   - An empty fence (```) is:
---       * Opening if we're NOT in a block
---       * Closing if we ARE in a block
---   - Fences must alternate: open -> close -> open -> close
---
--- This implements a simple state machine: outside block / inside block.

local api = vim.api
local notify = vim.notify
local levels = vim.log.levels

local M = {}

--- Pattern that matches a fenced code line.
--- Captures fence sequence and optional language specifier.
---@type string
local FENCE_PATTERN = "^%s*(```+)%s*(.*)$"
local TILDE_FENCE_PATTERN = "^%s*(~~~+)%s*(.*)$"

--- Information about an open fence.
---@class OpenFence
---@field line integer Line number (1-indexed)
---@field lang string Language specifier
---@field fence string Fence sequence

--- Checks the current buffer for unmatched fenced code blocks.
--- Reports line numbers and fence types.
function M.check_current_buffer()
  local bufnr = api.nvim_get_current_buf()
  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)

  --- State: are we currently inside a code block?
  local in_block = false

  --- Information about the currently open fence (nil if not in block).
  ---@type OpenFence?
  local open_fence = nil

  --- Collected problems.
  ---@type string[]
  local problems = {}

  for i = 1, #lines do
    local line = lines[i]

    -- Try backtick fence
    local fence, lang = line:match(FENCE_PATTERN)

    -- Try tilde fence
    if not fence then
      fence, lang = line:match(TILDE_FENCE_PATTERN)
    end

    if fence then
      -- Normalize language (trim whitespace)
      lang = vim.trim(lang or "")

      if not in_block then
        -- We're OUTSIDE a block: this fence MUST be opening
        in_block = true
        open_fence = {
          line = i,
          lang = lang == "" and "(empty)" or lang,
          fence = fence,
        }

      else
        -- We're INSIDE a block: this fence MUST be closing
        -- Check if fence length matches (closing must be >= opening)
        if open_fence and #fence >= #open_fence.fence then
          -- Valid closing fence
          in_block = false
          open_fence = nil
        else
          -- Fence too short to close the block
          if open_fence then
            problems[#problems + 1] = string.format(
              "Line %d: fence %s too short to close block opened at line %d with %s",
              i,
              fence,
              open_fence.line,
              open_fence.fence
            )
          end
        end
      end
    end
  end

  -- Check if block is still open at EOF
  if in_block and open_fence then
    problems[#problems + 1] = string.format(
      "Line %d: opening fence ```%s without matching closing fence (EOF reached)",
      open_fence.line,
      open_fence.lang ~= "(empty)" and open_fence.lang or ""
    )
  end

  -- Report results
  if #problems == 0 then
    notify("No unmatched fenced code blocks found", levels.INFO)
    return
  end

  notify("Unmatched fenced code blocks detected:", levels.WARN)
  for _, msg in ipairs(problems) do
    notify(msg, levels.WARN)
  end
end

return M
