---@module 'color_my_ascii.language_detector'
--- Language detection module for determining the programming language
--- used in ASCII code blocks through heuristic analysis.

local M = {}

local config = require("color_my_ascii.config")
local parser = require("color_my_ascii.parser")

--- Detect language from explicit block marker
--- Supports formats: ```ascii-c, ```ascii lua, ```ascii:python
---@param fence_line string The opening fence line
---@return string? language Detected language name or nil
local function detect_from_fence(fence_line)
	-- Pattern 1: ascii-language (e.g., ascii-c, ascii-lua)
	local lang = fence_line:match("ascii%-([%w_]+)")
	if lang then
		return lang
	end

	-- Pattern 2: ascii language (e.g., ascii c, ascii lua)
	lang = fence_line:match("ascii%s+([%w_]+)")
	if lang then
		return lang
	end

	-- Pattern 3: ascii:language (e.g., ascii:c, ascii:lua)
	lang = fence_line:match("ascii:([%w_]+)")
	if lang then
		return lang
	end

	return nil
end

--- Detect language using heuristic analysis of keywords
--- Counts unique keyword matches per language and selects the best match
---@param block_lines string[] Lines of the ASCII block
---@return string? language Detected language name or nil
local function detect_from_content(block_lines)
	local user_config = config.get()

	if not user_config.enable_language_detection then
		return nil
	end

	-- Score counter for each language
	local scores = {}
	for lang_name, _ in pairs(user_config.keywords) do
		scores[lang_name] = {
			unique = 0, -- Count of unique keywords found
			total = 0, -- Count of all keywords found
		}
	end

	-- Scan all lines for keywords
	for _, line in ipairs(block_lines) do
		local tokens = parser.tokenize_line(line)

		for _, token in ipairs(tokens) do
			-- Check if this is a unique keyword
			local unique_lang = config.get_unique_language(token)
			if unique_lang then
				scores[unique_lang].unique = scores[unique_lang].unique + 1
				scores[unique_lang].total = scores[unique_lang].total + 1
			else
				-- Check if this is a regular keyword in any language
				local langs = config.get_keyword_languages(token)
				if langs then
					for _, lang_info in ipairs(langs) do
						scores[lang_info.language].total = scores[lang_info.language].total + 1
					end
				end
			end
		end
	end

	-- Find language with highest unique keyword count
	local best_lang = nil
	local best_unique = 0
	local best_total = 0

	for lang_name, score in pairs(scores) do
		-- Prioritize unique keywords, use total as tiebreaker
		if score.unique > best_unique or (score.unique == best_unique and score.total > best_total) then
			best_lang = lang_name
			best_unique = score.unique
			best_total = score.total
		end
	end

	-- Only return language if we have enough confidence
	if best_unique >= user_config.language_detection_threshold then
		return best_lang
	end

	return nil
end

--- Detect language from buffer filetype context
--- Uses the filetype of the buffer containing the ASCII block
---@param bufnr integer Buffer number
---@return string? language Detected language name or nil
local function detect_from_buffer(bufnr)
	local ft = vim.bo[bufnr].filetype

	-- Map common filetypes to language names
	local ft_map = {
		c = "c",
		cpp = "cpp",
		lua = "lua",
		go = "go",
		typescript = "typescript",
		javascript = "typescript", -- Use TS keywords for JS
		bash = "bash",
		sh = "bash",
		zsh = "bash",
		zig = "zig",
		rust = "rust",
		python = "python",
		llvm = "llvm",
	}

	local lang = ft_map[ft]

	-- Verify language is actually available
	if lang then
		local available = config.get_available_languages()
		for _, available_lang in ipairs(available) do
			if available_lang == lang then
				return lang
			end
		end
	end

	return nil
end

--- Detect the programming language for an ASCII block
--- Uses multiple strategies in priority order:
--- 1. Explicit fence marker (e.g., ```ascii-c)
--- 2. Heuristic content analysis
--- 3. Buffer filetype context
--- 4. nil (no detection, use all keywords)
---@param bufnr integer Buffer number containing the block
---@param block ColorMyAscii.Block The ASCII block to analyze
---@param fence_line string The opening fence line
---@return string? language Detected language name or nil
function M.detect_language(bufnr, block, fence_line)
	-- Strategy 1: Explicit marker (highest priority)
	local lang = detect_from_fence(fence_line)
	if lang then
		return lang
	end

	-- Strategy 2: Heuristic analysis
	lang = detect_from_content(block.lines)
	if lang then
		return lang
	end

	-- Strategy 3: Buffer context (lowest priority)
	lang = detect_from_buffer(bufnr)
	if lang then
		return lang
	end

	-- Strategy 4: No detection (use all keywords)
	return nil
end

return M
