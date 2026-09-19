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

--- Apply `scheme_tbl` on top of the user's *current* configuration, not a
--- bare defaults + scheme merge: `config.setup()` always rebuilds
--- current_config from scratch, so calling it with just the scheme table
--- would silently reset every option the user passed to their own setup()
--- that the scheme doesn't mention -- fence_line_highlight, comment_ascii,
--- custom languages, treesitter, menu, keymaps, and so on (LUA-87).
---@internal
---@param scheme_tbl table
---@param name? string Scheme name to record on the merged config
local function apply_scheme(scheme_tbl, name)
  local current = require('color_my_ascii.config').get()
  local merged = vim.tbl_deep_extend('force', vim.deepcopy(current), scheme_tbl)
  if name then
    merged.scheme = name
  end
  require('color_my_ascii').setup(merged)
end

--- List all available schemes
function M.list_schemes()
  local lines = {}
  lines[#lines + 1] = '=== Available Color Schemes ==='
  lines[#lines + 1] = ''

  for _, name in ipairs(SCHEME_NAMES) do
    local scheme = require('color_my_ascii.schemes.' .. name)

    lines[#lines + 1] = string.format('• %s', name)

    -- Show enabled features
    local features = {}
    if scheme.enable_keywords then
      features[#features + 1] = 'keywords'
    end
    if scheme.enable_function_names then
      features[#features + 1] = 'functions'
    end
    if scheme.enable_bracket_highlighting then
      features[#features + 1] = 'brackets'
    end
    if scheme.enable_inline_code then
      features[#features + 1] = 'inline'
    end

    if #features > 0 then
      lines[#lines + 1] = string.format('  Features: %s', table.concat(features, ', '))
    end
  end

  lines[#lines + 1] = ''
  lines[#lines + 1] = 'Usage: :ColorMyAscii schemes switch <name>'
  lines[#lines + 1] = '   or: :ColorMyAscii schemes pick (Telescope)'

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
  apply_scheme(scheme, name)

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
      features[#features + 1] = 'kw'
    end
    if scheme.enable_function_names then
      features[#features + 1] = 'fn'
    end
    if scheme.enable_bracket_highlighting then
      features[#features + 1] = 'br'
    end
    if scheme.enable_inline_code then
      features[#features + 1] = 'in'
    end

    entries[#entries + 1] = {
      value = name,
      display = string.format('%-10s  %s', name, table.concat(features, ' ')),
      ordinal = name,
      scheme = scheme,
    }
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
        -- Preview on cursor move, guarded by "same selection as last time"
        -- (PERF-93): every j/k inside the picker fires CursorMoved, but the
        -- handler's body is the plugin's most expensive operation end to end
        -- (full config merge, all lookup tables rebuilt, every managed
        -- buffer re-parsed and re-extmarked) -- cheap to skip when the
        -- highlighted entry hasn't actually changed.
        local last_previewed = nil
        local function preview_scheme()
          local selection = action_state.get_selected_entry()
          if not selection or selection.value == last_previewed then
            return
          end
          last_previewed = selection.value

          apply_scheme(selection.scheme, selection.value)

          local state = require('color_my_ascii').get_state()
          for bufnr, _ in pairs(state.buffers) do
            require('color_my_ascii').highlight_buffer(bufnr)
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
