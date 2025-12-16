---@module 'color_my_ascii'
--- Main entry point for color_my_ascii.nvim plugin.
--- This module provides the public API for highlighting ASCII art in markdown files.
--- Implements safe error handling, caching, and adaptive debouncing.

local M = {}

local api = vim.api
local notify = vim.notify
local levels = vim.log.levels

---@type ColorMyAscii.State
local state = {
	enabled = true,
	buffers = {},
}

local config = require("color_my_ascii.config")
local parser = require("color_my_ascii.parser")
local highlighter = require("color_my_ascii.highlighter")
local cache_manager = require("color_my_ascii.cache_manager")
local debounce_manager = require("color_my_ascii.debounce_manager")
local safe_api = require("color_my_ascii.utils.safe_api")

--- Initialize the plugin with user configuration
---@param opts? ColorMyAscii.Config User configuration options
---@return boolean success True if initialization succeeded
---@return string|nil error Error message if initialization failed
function M.setup(opts)
	-- Safe config setup with error recovery
	local ok, err = pcall(config.setup, opts)
	local cfg = require("color_my_ascii.config").get()

	if not ok and cfg.debug_enabled then
		notify(string.format("color_my_ascii: Failed to initialize configuration: %s", err), levels.ERROR)
		return false, tostring(err)
	end

	-- Setup cache with default config
	cache_manager.configure({
		timeout = 5000,
		max_size = 50,
		enable_stats = false,
	})

	-- Setup debouncing with default config
	debounce_manager.configure({
		small_file_threshold = 500,
		medium_file_threshold = 2000,
		small_delay = 100,
		medium_delay = 200,
		large_delay = 500,
	})

	-- Setup automatic cleanup
	debounce_manager.setup_auto_cleanup()

	-- Start cache cleanup timer (every 30 seconds)
	cache_manager.setup_auto_cleanup(30000)

	return true, nil
end

--- Setup highlighting for a specific buffer
---@param bufnr integer Buffer number to setup
---@return boolean success True if setup succeeded
---@return string|nil error Error message if setup failed
function M.setup_buffer(bufnr)
	if not state.enabled then
		return false, "Plugin is disabled"
	end

	local cfg = require("color_my_ascii.config").get()

	-- Validate buffer
	if not safe_api.is_valid_buffer(bufnr) then
		return false, string.format("Invalid buffer: %d", bufnr)
	end

	-- Mark buffer as managed
	state.buffers[bufnr] = true

	-- Initial highlight
	local success, err = M.highlight_buffer(bufnr)
	if not success and cfg.debug_enabled then
		notify(string.format("color_my_ascii: Initial highlighting failed: %s", err), levels.WARN)
	end

	-- Setup autocommands for this buffer
	local group = api.nvim_create_augroup("ColorMyAsciiBuffer_" .. bufnr, { clear = true })

	-- Re-highlight on text change with adaptive debouncing
	api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		group = group,
		buffer = bufnr,
		callback = function()
			debounce_manager.debounce(bufnr, function()
				M.highlight_buffer(bufnr)
			end)
		end,
		desc = "Re-highlight ASCII art on text change with debouncing",
	})

	-- Cleanup on buffer delete
	api.nvim_create_autocmd("BufDelete", {
		group = group,
		buffer = bufnr,
		callback = function()
			state.buffers[bufnr] = nil
			highlighter.clear_buffer(bufnr)
			cache_manager.invalidate(bufnr)
			debounce_manager.cancel(bufnr)
		end,
		desc = "Cleanup ASCII art highlighting on buffer delete",
	})

	return true, nil
end

--- Highlight all ASCII blocks in the specified buffer with caching
---@param bufnr? integer Buffer number (defaults to current buffer)
---@return boolean success True if highlighting succeeded
---@return string|nil error Error message if highlighting failed
function M.highlight_buffer(bufnr)
	local cfg = require("color_my_ascii.config").get()
	bufnr = bufnr or api.nvim_get_current_buf()

	if not state.enabled or not state.buffers[bufnr] then
		return false, "Buffer not managed or plugin disabled"
	end

	-- Validate buffer
	if not safe_api.is_valid_buffer(bufnr) then
		return false, string.format("Invalid buffer: %d", bufnr)
	end

	-- Try cache first
	local cached_blocks, _, cache_hit = cache_manager.get(bufnr)

	if cache_hit then
		-- Use cached data
		local success, err = highlighter.clear_buffer(bufnr)
		if not success then
			return false, string.format("Failed to clear buffer: %s", err)
		end

		-- Check if cached_blocks is valid
		if type(cached_blocks) ~= "table" or vim.tbl_isempty(cached_blocks) and cfg.debug_enabled then
			notify(
				string.format("Cache for buffer %d is empty or invalid, skipping block highlighting", bufnr),
				levels.WARN
			)
		else
			-- Highlight cached blocks safely
			for _, block in ipairs(cached_blocks) do
				if type(block) == "table" then
					success, err = highlighter.highlight_block(bufnr, block)
					if not success then
						notify(string.format("Failed to highlight block: %s", err), levels.ERROR)
					end
				else
					notify("Skipped invalid block in cache (not a table)", levels.WARN)
				end
			end
		end

		-- Highlight inline codes
		success, err = highlighter.highlight_inline_codes(bufnr)
		if not success then
			return false, string.format("Failed to highlight inline codes: %s", err)
		end

		return true, nil
	end

	-- Cache miss - parse and highlight
	local success, err = highlighter.clear_buffer(bufnr)
	if not success then
		return false, string.format("Failed to clear buffer: %s", err)
	end

	-- Parse blocks
	local blocks, parse_err = parser.find_ascii_blocks(bufnr)
	if parse_err then
		return false, string.format("Failed to parse blocks: %s", parse_err)
	end

	-- Parse inline codes
	local inline_codes, inline_err = parser.find_inline_codes(bufnr)
	if inline_err then
		return false, string.format("Failed to parse inline codes: %s", inline_err)
	end

	-- Cache parsed data
	cache_manager.set(bufnr, blocks, inline_codes)

	-- Highlight each block
	for _, block in ipairs(blocks) do
		success, err = highlighter.highlight_block(bufnr, block)
		if not success and cfg.debug_enabled then
			-- Log error but continue with other blocks
			notify(string.format("color_my_ascii: Block highlighting error: %s", err), levels.WARN)
		end
	end

	-- Highlight inline codes
	success, err = highlighter.highlight_inline_codes(bufnr)
	if not success and cfg.debug_enabled then
		notify(string.format("color_my_ascii: Inline code highlighting error: %s", err), levels.WARN)
	end

	return true, nil
end

--- Toggle the plugin on/off
---@return boolean enabled New state (true = enabled, false = disabled)
function M.toggle()
	state.enabled = not state.enabled

	if state.enabled then
		-- Re-enable: highlight all managed buffers
		for bufnr, _ in pairs(state.buffers) do
			if safe_api.is_valid_buffer(bufnr) then
				M.highlight_buffer(bufnr)
			end
		end
			notify("color_my_ascii.nvim enabled", levels.INFO)
	else
		-- Disable: clear all highlights
		for bufnr, _ in pairs(state.buffers) do
			if safe_api.is_valid_buffer(bufnr) then
				highlighter.clear_buffer(bufnr)
			end
		end
			notify("color_my_ascii.nvim disabled", levels.INFO)
	end

	return state.enabled
end

--- Get current plugin state
---@return ColorMyAscii.State
function M.get_state()
	return vim.deepcopy(state)
end

--- Get cache statistics
---@return CacheStats stats Cache statistics
function M.get_cache_stats()
	return cache_manager.get_stats()
end

--- Get cache hit rate
---@return number hit_rate Hit rate as percentage (0-100)
function M.get_cache_hit_rate()
	return cache_manager.get_hit_rate()
end

--- Clear all caches
---@return integer count Number of cleared entries
function M.clear_caches()
	return cache_manager.clear_all()
end

--- Get debounce configuration
---@return DebounceConfig config Debounce configuration
function M.get_debounce_config()
	return debounce_manager.get_config()
end

--- Configure cache behavior
---@param opts CacheConfig Cache configuration
---@return nil
function M.configure_cache(opts)
	cache_manager.configure(opts)
end

--- Configure debounce behavior
---@param opts DebounceConfig Debounce configuration
---@return nil
function M.configure_debounce(opts)
	debounce_manager.configure(opts)
end

return M
