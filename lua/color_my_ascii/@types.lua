---@module 'color_my_ascii.@types'

---@class ColorMyAscii.CharGroup
---@field chars string String containing all characters in this group
---@field hl string|ColorMyAscii.CustomHighlight Highlight group name or custom highlight definition

---@class ColorMyAscii.CustomHighlight
---@field fg? string Foreground color (hex like "#ff0000" or color name like "red")
---@field bg? string Background color
---@field bold? boolean Bold text
---@field italic? boolean Italic text
---@field underline? boolean Underlined text
---@field undercurl? boolean Undercurl text
---@field strikethrough? boolean Strikethrough text

---@class ColorMyAscii.KeywordGroup
---@field words string[] List of keywords to highlight
---@field hl string|ColorMyAscii.CustomHighlight Highlight group name or custom highlight definition
---@field unique_words? string[] Keywords unique to this language (for heuristic detection)

---@class ColorMyAscii.CustomGroup
---@field chars string Characters to highlight with this group
---@field hl string|ColorMyAscii.CustomHighlight Highlight specification

---@class ColorMyAscii.Config
---@field debug_enabled? boolean Toggle debug mode (usercommands)
---@field debug_verbose? boolean Toggle write debug logs to file
---@field groups? table<string, ColorMyAscii.CharGroup> Named character groups with their highlight settings
---@field keywords? table<string, ColorMyAscii.KeywordGroup> Language-specific keyword definitions
---@field custom_groups? table<string, ColorMyAscii.CustomGroup> User-defined character groups with custom highlights
---@field overrides? table<string, string|ColorMyAscii.CustomHighlight> Individual character to highlight group mappings (highest priority)
---@field default_hl? string|ColorMyAscii.CustomHighlight Default highlight group for characters not matching any rules
---@field default_text_hl? string|ColorMyAscii.CustomHighlight Optional highlight group for normal text in blocks (nil = no change)
---@field enable_keywords? boolean Whether to highlight keywords in ASCII blocks
---@field enable_language_detection? boolean Whether to use heuristic language detection
---@field language_detection_threshold? integer Minimum unique keyword matches for language detection
---@field enable_treesitter? boolean Whether to use treesitter for additional syntax highlighting
---@field treat_empty_fence_as_ascii? boolean Treat `` without language as ASCII block
---@field enable_inline_code? boolean Enable highlighting in inline code ...`)
---@field enable_function_names? boolean Enable heuristic function name detection
---@field enable_bracket_highlighting? boolean Enable highlighting of brackets/parentheses
---@field scheme? string Color scheme name to load (e.g., "nord", "gruvbox")

---@class ColorMyAscii.State
---@field enabled boolean Whether the plugin is currently enabled
---@field buffers table<integer, boolean> Set of buffers with active highlighting

---@class ColorMyAscii.Block
---@field start_line integer Starting line number (0-indexed)
---@field end_line integer Ending line number (0-indexed, inclusive)
---@field lines string[] Content lines of the block (without fence markers)
---@field fence_line string Opening fence line (for language detection)

---@class ColorMyAscii.InlineCode
---@field line integer Line number (0-indexed)
---@field start_col integer Start column (0-indexed, byte offset)
---@field end_col integer End column (0-indexed, byte offset, exclusive)
---@field content string Content inside backticks

---@class OpenFenceInfo
---@field start_line integer Line number where block starts (1-indexed)
---@field fence_line string The opening fence line content
---@field fence_length integer Length of the fence sequence
---@field is_ascii boolean? Whether this is an ASCII block we want to highlight
---@field block_lines string[] Accumulated block content lines (only for ASCII blocks)

---@class CacheEntry
---@field blocks ColorMyAscii.Block[] Parsed ASCII blocks
---@field inline_codes ColorMyAscii.InlineCode[] Parsed inline code segments
---@field timestamp number Cache creation timestamp (ms)
---@field changedtick number Buffer changedtick at cache time
---@field line_count integer Number of lines in buffer at cache time

---@class CacheConfig
---@field timeout integer Cache validity timeout in milliseconds
---@field max_size integer Maximum number of cached buffers
---@field enable_stats boolean Whether to collect statistics

---@class CacheStats
---@field hits integer Number of cache hits
---@field misses integer Number of cache misses
---@field invalidations integer Number of cache invalidations
---@field evictions integer Number of cache evictions

---@class DebounceConfig
---@field small_file_threshold integer? Line count threshold for small files
---@field medium_file_threshold integer? Line count threshold for medium files
---@field small_delay integer? Delay for small files (ms)
---@field medium_delay integer? Delay for medium files (ms)
---@field large_delay integer? Delay for large files (ms)
---@field min_delay integer? Minimum debounce delay (ms)
---@field max_delay integer? Maximum debounce delay (ms)

---@class SafeApiResult
---@field success boolean Whether the operation succeeded
---@field result any|nil The result of the operation if successful
---@field error string|nil Error message if operation failed

---@alias HighlightSpec string|ColorMyAscii.CustomHighlight
---@alias KeywordLookup table<string, {language: string, hl: string}[]>
---@alias CharLookup table<string, string>
---@alias UniqueKeywordLookup table<string, string>
