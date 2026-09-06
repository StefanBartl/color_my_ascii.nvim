---@module 'color_my_ascii.commands.schemes'
--- Scheme management commands

local M = {}

local notify = require('lib.nvim.notify').create('[color_my_ascii]')

--- Available scheme names, sorted. Sourced from `scheme_loader`'s registry so
--- this stays in step with `schemes/*.lua` instead of being a second list to
--- keep updated by hand.
---@type string[]
local SCHEME_NAMES = require('color_my_ascii.scheme_loader').get_available_schemes()

--- Get list of scheme names
---@return string[]
function M.get_scheme_names()
  return vim.deepcopy(SCHEME_NAMES)
end

--- List all available schemes
function M.list_schemes()
  local lines = {}
  table.insert(lines, '=== Available Color Schemes ===')
  table.insert(lines, '')

  for _, name in ipairs(SCHEME_NAMES) do
    local scheme = require('color_my_ascii.schemes.' .. name)

    table.insert(lines, string.format('• %s', name))

    -- Show enabled features
    local features = {}
    if scheme.enable_keywords then
      table.insert(features, 'keywords')
    end
    if scheme.enable_function_names then
      table.insert(features, 'functions')
    end
    if scheme.enable_bracket_highlighting then
      table.insert(features, 'brackets')
    end
    if scheme.enable_inline_code then
      table.insert(features, 'inline')
    end

    if #features > 0 then
      table.insert(lines, string.format('  Features: %s', table.concat(features, ', ')))
    end
  end

  table.insert(lines, '')
  table.insert(lines, 'Usage: :ColorMyAscii schemes switch <name>')
  table.insert(lines, '   or: :ColorMyAscii schemes pick (Telescope)')

  notify.info(table.concat(lines, '\n'))
end

--- Switch to a different scheme
---@param name string Scheme name
function M.switch_scheme(name)
  if name == '' then
    notify.error('Usage: :ColorMyAscii schemes switch <name>')
    return
  end

  -- Validate scheme exists
  local found = false
  for _, scheme_name in ipairs(SCHEME_NAMES) do
    if scheme_name == name then
      found = true
      break
    end
  end

  if not found then
    notify.error(string.format('Unknown scheme: %s', name))
    notify.info('Available: ' .. table.concat(SCHEME_NAMES, ', '))
    return
  end

  -- Load scheme
  local ok, scheme = pcall(require, 'color_my_ascii.schemes.' .. name)
  if not ok then
    notify.error(string.format('Failed to load scheme: %s', name))
    return
  end

  -- Apply scheme
  require('color_my_ascii').setup(scheme)

  -- Re-highlight all buffers
  local state = require('color_my_ascii').get_state()
  for bufnr, _ in pairs(state.buffers) do
    require('color_my_ascii').highlight_buffer(bufnr)
  end

  notify.info(string.format('Switched to scheme: %s', name))
end

--- Telescope picker for schemes
function M.telescope_picker()
  local has_telescope, _ = pcall(require, 'telescope')

  if not has_telescope then
    notify.error('Telescope not installed')
    return
  end

  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')

  -- Build entries
  local entries = {}
  for _, name in ipairs(SCHEME_NAMES) do
    local scheme = require('color_my_ascii.schemes.' .. name)

    local features = {}
    if scheme.enable_keywords then
      table.insert(features, 'kw')
    end
    if scheme.enable_function_names then
      table.insert(features, 'fn')
    end
    if scheme.enable_bracket_highlighting then
      table.insert(features, 'br')
    end
    if scheme.enable_inline_code then
      table.insert(features, 'in')
    end

    table.insert(entries, {
      value = name,
      display = string.format('%-10s  %s', name, table.concat(features, ' ')),
      ordinal = name,
      scheme = scheme,
    })
  end

  pickers
    .new({}, {
      prompt_title = 'Color Schemes',
      finder = finders.new_table({
        results = entries,
        entry_maker = function(entry)
          return entry
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, _)
        -- Preview on cursor move
        local function preview_scheme()
          local selection = action_state.get_selected_entry()
          if selection then
            require('color_my_ascii').setup(selection.scheme)

            local state = require('color_my_ascii').get_state()
            for bufnr, _ in pairs(state.buffers) do
              require('color_my_ascii').highlight_buffer(bufnr)
            end
          end
        end

        -- Preview on move. The group is cleared on every picker open: only
        -- one scheme picker exists at a time, so this keeps one record for it
        -- instead of one per open.
        local autocmd = require('lib.nvim.bindings.autocmd')
        autocmd.create('CursorMoved', preview_scheme, {
          group = autocmd.group('color_my_ascii_scheme_picker', true),
          buffer = prompt_bufnr,
          desc = '[color_my_ascii] Preview the scheme under the cursor in the picker',
        })

        -- Apply on select
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            notify.info(string.format('Applied scheme: %s', selection.value))
          end
        end)

        return true
      end,
    })
    :find()
end

return M
