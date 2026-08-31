---@module 'color_my_ascii.api.highlight'
--- Public, stable API for reading back the highlighting color_my_ascii applied.
---
--- color_my_ascii's coloring lives entirely in extmarks, which means it exists
--- only inside the buffer: copy a block out, render it somewhere else, and the
--- colors are gone. This module hands the same information out as data, so
--- another plugin can reproduce the buffer's look in its own medium.
---
--- Its first consumer is `mdview.nvim`, which paints fenced code blocks in its
--- browser preview with exactly what the buffer next to it shows, instead of
--- guessing the language again with a JavaScript highlighter.
---
--- Both functions are read-only and side-effect free; neither triggers a
--- highlight pass. A block color_my_ascii has not painted yields runs whose
--- `group` is nil throughout — the honest answer, and the caller's cue to fall
--- back to whatever it would otherwise have done.
---
--- Pair with `color_my_ascii.api.fences` to obtain the blocks themselves:
---
--- ```lua
--- local fences = require('color_my_ascii').fences
--- local hl = require('color_my_ascii').highlight
--- for _, block in ipairs(fences.list_blocks(bufnr)) do
---   for _, runs in ipairs(hl.runs_for_block(bufnr, block)) do
---     for _, run in ipairs(runs) do
---       if run.group then
---         local attrs = hl.attrs_for_group(run.group) -- { fg = "#rrggbb", … }
---       end
---     end
---   end
--- end
--- ```

local M = {}

local export = require('color_my_ascii.highlight_export')

--- The applied highlighting of one fenced block, as one array of runs per
--- content row. A run is a stretch of text sharing the same highlight group;
--- `group = nil` means color_my_ascii painted nothing there.
---
--- Rows correspond to the block's content rows in order, so row `i` of the
--- result is buffer row `block.content_start + i - 1`. Runs within a row are
--- contiguous and in column order; concatenating their `text` reproduces the
--- row exactly, byte for byte (multi-byte characters are never split).
---@param bufnr integer
---@param block ColorMyAscii.FenceBlock
---@return ColorMyAscii.HlRun[][] runs_per_row
function M.runs_for_block(bufnr, block)
  return export.runs_for_block(bufnr, block)
end

--- Resolve a highlight group to concrete, renderable attributes: colors as
--- `"#rrggbb"` strings and the boolean styles, with `link=` chains followed.
--- Absent attributes are nil rather than a default, so a consumer can tell
--- "this group sets no background" from "this group sets a black one".
---@param group string
---@return ColorMyAscii.HlAttrs
function M.attrs_for_group(group)
  return export.attrs_for_group(group)
end

return M
