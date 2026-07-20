---@module 'color_my_ascii.debug.commands'
---@brief Route definitions for the debug subcommands of :ColorMyAscii.
---@description
--- Pure route factory (no side effects, no self-registration) — the
--- composer verb in bindings/usrcmds.lua includes M.routes() only when debug
--- mode is enabled, and rebuilds the whole verb whenever that flag changes
--- (see debug/init.lua). All under `:ColorMyAscii inspect …` / `:ColorMyAscii
--- stats`, matching the old flat ColorMyAsciiInspect*/ColorMyAsciiStats
--- commands' behavior exactly.

local M = {}

--- Debug subcommand routes: inspect {char,group,inline,highlight}, stats.
---@return Lib.UserCmd.Composer.Route[]
function M.routes()
  local inspect = require('color_my_ascii.debug.inspect')
  local group_names = vim.tbl_keys(require('color_my_ascii.config').get().groups)

  return {
    { path = { 'inspect', 'char' },
      args = { { name = 'char', type = 'STRING' } },
      desc = 'Inspect which groups and highlights a character belongs to',
      run = function(ctx)
        local char = ctx.args.char
        local result = inspect.inspect_char(char)

        print('=== Character Inspection: "' .. char .. '" ===')
        print('Highlight: ' .. (result.highlight or 'none'))
        print('Override: ' .. tostring(result.override))
        print('Groups: ' .. (#result.groups > 0 and table.concat(result.groups, ', ') or 'none'))
      end },

    { path = { 'inspect', 'group' },
      args = { { name = 'group', type = 'STRING', values = group_names } },
      desc = 'Inspect all characters in a specific group',
      run = function(ctx)
        local group_name = ctx.args.group
        local result = inspect.inspect_group(group_name)
        if not result then
          print('Group not found: ' .. group_name)
          return
        end

        print('=== Group Inspection: ' .. group_name .. ' ===')
        print('Highlight: ' .. result.highlight)
        print('Character count: ' .. result.count)
        print('Characters: ' .. table.concat(result.chars, ' '))
      end },

    { path = { 'inspect', 'inline' },
      desc = 'Inspect inline code in current line',
      run = function()
        local line = vim.api.nvim_get_current_line()
        local results = inspect.inspect_inline_code(line)

        print('=== Inline Code Inspection ===')
        print('Line: ' .. line)
        print('Found ' .. #results .. ' inline code segment(s)')

        for idx, result in ipairs(results) do
          print('\n[' .. idx .. '] "' .. result.content .. '" [' .. result.start_col .. '-' .. result.end_col .. ']')

          if #result.chars > 0 then
            print('  Characters:')
            for _, char_info in ipairs(result.chars) do
              print('    "' .. char_info.char .. '" -> ' .. char_info.highlight)
            end
          end

          if #result.keywords > 0 then
            print('  Keywords:')
            for _, kw_info in ipairs(result.keywords) do
              print('    "' .. kw_info.token .. '" -> ' .. kw_info.languages[1].highlight)
            end
          end
        end
      end },

    { path = { 'inspect', 'highlight' },
      args = { { name = 'hl_group', type = 'STRING' } },
      desc = 'Show all groups using a specific highlight',
      run = function(ctx)
        local highlight = ctx.args.hl_group
        local groups = inspect.groups_by_highlight(highlight)

        print('=== Highlight Group Inspection: ' .. highlight .. ' ===')
        print('Used by ' .. #groups .. ' group(s):')
        for _, group_name in ipairs(groups) do
          print('  - ' .. group_name)
        end
      end },

    { path = { 'stats' },
      desc = 'Show comprehensive plugin statistics',
      run = function()
        local stats = inspect.get_statistics()

        print('=== color_my_ascii.nvim Statistics ===')
        print('\nGroups:')
        print('  Total: ' .. stats.groups.count)
        print('  By highlight:')
        for hl, groups in pairs(stats.groups.by_highlight) do
          print('    ' .. hl .. ': ' .. table.concat(groups, ', '))
        end

        print('\nLanguages:')
        print('  Total: ' .. stats.languages.count)
        print('  Keywords per language:')
        for lang, count in pairs(stats.languages.by_keywords) do
          print('    ' .. lang .. ': ' .. count)
        end

        print('\nLookups:')
        print('  Character mappings: ' .. stats.lookups.char_count)
        print('  Keyword mappings: ' .. stats.lookups.keyword_count)
        print('  Unique keywords: ' .. stats.lookups.unique_keyword_count)
        print('  Overrides: ' .. stats.overrides)
      end },
  }
end

return M
