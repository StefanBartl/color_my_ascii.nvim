---@module 'color_my_ascii.debug.commands'
--- Route definitions for the debug subcommands of :ColorMyAscii.
--- Pure route factory (no side effects, no self-registration) — the
--- composer verb in bindings/usrcmds.lua includes M.routes() only when debug
--- mode is enabled, and rebuilds the whole verb whenever that flag changes
--- (see debug/init.lua). All under `:ColorMyAscii inspect …` / `:ColorMyAscii
--- stats`, matching the old flat ColorMyAsciiInspect*/ColorMyAsciiStats
--- commands' behavior exactly.

local notify = require('lib.nvim.notify').create('[color_my_ascii]')
local viewer = require('lib.nvim.output.viewer')

local M = {}

--- Debug subcommand routes: inspect {char,group,inline,highlight}, stats.
---@return Lib.UserCmd.Composer.Route[]
function M.routes()
  local inspect = require('color_my_ascii.debug.inspect')
  local group_names = vim.tbl_keys(require('color_my_ascii.config').get().groups)

  return {
    {
      path = { 'inspect', 'char' },
      args = { { name = 'char', type = 'STRING' } },
      desc = 'Inspect which groups and highlights a character belongs to',
      run = function(ctx)
        local char = ctx.args.char
        local result = inspect.inspect_char(char)

        viewer.show_lines(('Character Inspection: "%s"'):format(char), {
          'Highlight: ' .. (result.highlight or 'none'),
          'Override: ' .. tostring(result.override),
          'Groups: ' .. (#result.groups > 0 and table.concat(result.groups, ', ') or 'none'),
        })
      end,
    },

    {
      path = { 'inspect', 'group' },
      args = { { name = 'group', type = 'STRING', values = group_names } },
      desc = 'Inspect all characters in a specific group',
      run = function(ctx)
        local group_name = ctx.args.group
        local result = inspect.inspect_group(group_name)
        if not result then
          notify.warn('Group not found: ' .. group_name)
          return
        end

        viewer.show_lines(('Group Inspection: %s'):format(group_name), {
          'Highlight: ' .. result.highlight,
          'Character count: ' .. result.count,
          'Characters: ' .. table.concat(result.chars, ' '),
        })
      end,
    },

    {
      path = { 'inspect', 'inline' },
      desc = 'Inspect inline code in current line',
      run = function()
        local line = vim.api.nvim_get_current_line()
        local results = inspect.inspect_inline_code(line)

        local lines = {
          'Line: ' .. line,
          'Found ' .. #results .. ' inline code segment(s)',
        }

        for idx, result in ipairs(results) do
          lines[#lines + 1] = ''
          lines[#lines + 1] = ('[%d] "%s" [%d-%d]'):format(idx, result.content, result.start_col, result.end_col)

          if #result.chars > 0 then
            lines[#lines + 1] = '  Characters:'
            for _, char_info in ipairs(result.chars) do
              lines[#lines + 1] = ('    "%s" -> %s'):format(char_info.char, char_info.highlight)
            end
          end

          if #result.keywords > 0 then
            lines[#lines + 1] = '  Keywords:'
            for _, kw_info in ipairs(result.keywords) do
              lines[#lines + 1] = ('    "%s" -> %s'):format(kw_info.token, kw_info.languages[1].highlight)
            end
          end
        end

        viewer.show_lines('Inline Code Inspection', lines)
      end,
    },

    {
      path = { 'inspect', 'highlight' },
      args = { { name = 'hl_group', type = 'STRING' } },
      desc = 'Show all groups using a specific highlight',
      run = function(ctx)
        local highlight = ctx.args.hl_group
        local groups = inspect.groups_by_highlight(highlight)

        local lines = { 'Used by ' .. #groups .. ' group(s):' }
        for _, group_name in ipairs(groups) do
          lines[#lines + 1] = '  - ' .. group_name
        end

        viewer.show_lines(('Highlight Group Inspection: %s'):format(highlight), lines)
      end,
    },

    {
      path = { 'stats' },
      desc = 'Show comprehensive plugin statistics',
      run = function()
        local stats = inspect.get_statistics()

        local lines = {
          'Groups:',
          '  Total: ' .. stats.groups.count,
          '  By highlight:',
        }
        for hl, groups in pairs(stats.groups.by_highlight) do
          lines[#lines + 1] = '    ' .. hl .. ': ' .. table.concat(groups, ', ')
        end

        lines[#lines + 1] = ''
        lines[#lines + 1] = 'Languages:'
        lines[#lines + 1] = '  Total: ' .. stats.languages.count
        lines[#lines + 1] = '  Keywords per language:'
        for lang, count in pairs(stats.languages.by_keywords) do
          lines[#lines + 1] = '    ' .. lang .. ': ' .. count
        end

        lines[#lines + 1] = ''
        lines[#lines + 1] = 'Lookups:'
        lines[#lines + 1] = '  Character mappings: ' .. stats.lookups.char_count
        lines[#lines + 1] = '  Keyword mappings: ' .. stats.lookups.keyword_count
        lines[#lines + 1] = '  Unique keywords: ' .. stats.lookups.unique_keyword_count
        lines[#lines + 1] = '  Overrides: ' .. stats.overrides

        viewer.show_lines('color_my_ascii.nvim Statistics', lines)
      end,
    },
  }
end

return M
