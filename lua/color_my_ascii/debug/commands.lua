---@module 'color_my_ascii.debug.commands'
---@brief User command registration for debug module

local M = {}

---Register all debug user commands
---@return nil
function M.register()
  local inspect = require('color_my_ascii.debug.inspect')

  -- :ColorMyAsciiInspectChar <char>
  vim.api.nvim_create_user_command('ColorMyAsciiInspectChar', function(opts)
    local char = opts.args
    if #char == 0 then
      print('Usage: :ColorMyAsciiInspectChar <character>')
      return
    end

    local result = inspect.inspect_char(char)

    print('=== Character Inspection: "' .. char .. '" ===')
    print('Highlight: ' .. (result.highlight or 'none'))
    print('Override: ' .. tostring(result.override))
    print('Groups: ' .. (#result.groups > 0 and table.concat(result.groups, ', ') or 'none'))
  end, {
    nargs = 1,
    desc = 'Inspect which groups and highlights a character belongs to',
  })

  -- :ColorMyAsciiInspectGroup <group>
  vim.api.nvim_create_user_command('ColorMyAsciiInspectGroup', function(opts)
    local group_name = opts.args
    if #group_name == 0 then
      print('Usage: :ColorMyAsciiInspectGroup <group_name>')
      return
    end

    local result = inspect.inspect_group(group_name)
    if not result then
      print('Group not found: ' .. group_name)
      return
    end

    print('=== Group Inspection: ' .. group_name .. ' ===')
    print('Highlight: ' .. result.highlight)
    print('Character count: ' .. result.count)
    print('Characters: ' .. table.concat(result.chars, ' '))
  end, {
    nargs = 1,
    complete = function()
      local cfg = require('color_my_ascii.config').get()
      return vim.tbl_keys(cfg.groups)
    end,
    desc = 'Inspect all characters in a specific group',
  })

  -- :ColorMyAsciiInspectInline
  vim.api.nvim_create_user_command('ColorMyAsciiInspectInline', function()
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
  end, {
    desc = 'Inspect inline code in current line',
  })

  -- :ColorMyAsciiInspectHighlight <hl_group>
  vim.api.nvim_create_user_command('ColorMyAsciiInspectHighlight', function(opts)
    local highlight = opts.args
    if #highlight == 0 then
      print('Usage: :ColorMyAsciiInspectHighlight <highlight_group>')
      return
    end

    local groups = inspect.groups_by_highlight(highlight)

    print('=== Highlight Group Inspection: ' .. highlight .. ' ===')
    print('Used by ' .. #groups .. ' group(s):')
    for _, group_name in ipairs(groups) do
      print('  - ' .. group_name)
    end
  end, {
    nargs = 1,
    desc = 'Show all groups using a specific highlight',
  })

  -- :ColorMyAsciiStats
  vim.api.nvim_create_user_command('ColorMyAsciiStats', function()
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
  end, {
    desc = 'Show comprehensive plugin statistics',
  })
end

return M
