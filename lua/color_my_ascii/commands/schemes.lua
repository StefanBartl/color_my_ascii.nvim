---@module 'color_my_ascii.commands.schemes'
--- Scheme management commands

local M = {}

local notify = vim.notify
local levels = vim.log.levels

--- Available schemes
---@type string[]
local SCHEME_NAMES = {
  'default',
  'matrix',
  'nord',
  'gruvbox',
  'dracula',
}

--- Get list of scheme names
---@return string[]
function M.get_scheme_names()
  return vim.deepcopy(SCHEME_NAMES)
end

--- List all available schemes
function M.list_schemes()
  print('=== Available Color Schemes ===')
  print('')

  for _, name in ipairs(SCHEME_NAMES) do
    local scheme = require('color_my_ascii.schemes.' .. name)

    print(string.format('• %s', name))

    -- Show enabled features
    local features = {}
    if scheme.enable_keywords then table.insert(features, 'keywords') end
    if scheme.enable_function_names then table.insert(features, 'functions') end
    if scheme.enable_bracket_highlighting then table.insert(features, 'brackets') end
    if scheme.enable_inline_code then table.insert(features, 'inline') end

    if #features > 0 then
      print(string.format('  Features: %s', table.concat(features, ', ')))
    end
  end

  print('')
  print('Usage: :ColorMyAsciiSwitchScheme <name>')
  print('   or: :ColorMyAsciiSchemes (Telescope)')
end

--- Switch to a different scheme
---@param name string Scheme name
function M.switch_scheme(name)
  if name == '' then
    notify('Usage: :ColorMyAsciiSwitchScheme <name>', levels.ERROR)
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
    notify(string.format('Unknown scheme: %s', name), levels.ERROR)
    notify('Available: ' .. table.concat(SCHEME_NAMES, ', '), levels.INFO)
    return
  end

  -- Load scheme
  local ok, scheme = pcall(require, 'color_my_ascii.schemes.' .. name)
  if not ok then
    notify(string.format('Failed to load scheme: %s', name), levels.ERROR)
    return
  end

  -- Apply scheme
  require('color_my_ascii').setup(scheme)

  -- Re-highlight all buffers
  local state = require('color_my_ascii').get_state()
  for bufnr, _ in pairs(state.buffers) do
    require('color_my_ascii').highlight_buffer(bufnr)
  end

  notify(string.format('Switched to scheme: %s', name), levels.INFO)
end

--- Telescope picker for schemes
function M.telescope_picker()
  local has_telescope, _ = pcall(require, 'telescope')

  if not has_telescope then
    notify('Telescope not installed', levels.ERROR)
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
    if scheme.enable_keywords then table.insert(features, 'kw') end
    if scheme.enable_function_names then table.insert(features, 'fn') end
    if scheme.enable_bracket_highlighting then table.insert(features, 'br') end
    if scheme.enable_inline_code then table.insert(features, 'in') end

    table.insert(entries, {
      value = name,
      display = string.format('%-10s  %s', name, table.concat(features, ' ')),
      ordinal = name,
      scheme = scheme,
    })
  end

  pickers.new({}, {
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

      -- Preview on move
      vim.api.nvim_create_autocmd('CursorMoved', {
        buffer = prompt_bufnr,
        callback = preview_scheme,
      })

      -- Apply on select
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          notify(string.format('Applied scheme: %s', selection.value), levels.INFO)
        end
      end)

      return true
    end,
  }):find()
end

return M
