---@module 'color_my_ascii.@types'
---@meta
--- Shared LuaCATS type declarations for color_my_ascii.nvim: config shape, cache/debounce
--- settings, and the block/highlight descriptors passed between the parser, highlighter,
--- and public fence API.

---@alias ColorMyAscii.SchemeName
---| "default"    # Uses built-in Neovim highlights
---| "matrix"     # Dark with bright green (hacker style)
---| "nord"       # Cool blue/cyan colors
---| "gruvbox"    # Warm, retro colors
---| "dracula"    # Vibrant purple and pink
---| "catppuccin" # Soft pastel colors
---| "onedark"    # Dark theme with subtle highlights
---| "solarized"  # Solarized color palette
---| "tokyonight" # Dark theme with blue accents
---| "monokai"    # Classic Monokai color scheme

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

--- Fence-line look. "auto" matches the current colorscheme (falling back to
--- "subtle"); the generic looks are theme-adaptive links; the theme names apply
--- a hand-tuned palette (see color_my_ascii/theme_presets.lua).
---@alias ColorMyAscii.FencePreset
---| "auto"
---| "subtle"
---| "accent"
---| "underline"
---| "bar"
---| "catppuccin"
---| "tokyonight"
---| "gruvbox"
---| "gruvbox-material"
---| "nord"
---| "onedark"
---| "dracula"
---| "kanagawa"
---| "rose-pine"
---| "everforest"
---| "nightfox"
---| "material"
---| "sonokai"
---| "monokai"
---| "solarized"
---| "github"
---| "oxocarbon"

---@class ColorMyAscii.FenceLineHighlight
---@field enable? boolean Highlight the whole opening/closing fence delimiter line (default true)
---@field preset? ColorMyAscii.FencePreset Look for the fence lines (default "auto")
---@field open? string|ColorMyAscii.CustomHighlight Override for the opening fence line (hl group name or attr table)
---@field close? string|ColorMyAscii.CustomHighlight Override for the closing fence line (hl group name or attr table)
---@field apply_to? "all"|"ascii" Which blocks get the highlight: every fenced block or only ASCII ones
---@field respect_indent? boolean Start the highlight at the block's own indent column (opening fence's first backtick) instead of column 0, and hold a gap off the window's right edge (default true); false paints the whole screen line from column 0
---@field right_pad? integer Screen columns to leave between the highlight and the window's right edge when respect_indent is on (default 1, clamped 0-20; needs the buffer to be displayed in a window)

--- Background-only highlight of a fenced block's interior (between the
--- delimiter lines), painted full-width via `line_hl_group` extmarks so it
--- covers trailing whitespace and blank lines too, not just characters.
--- Derived by shading the resolved fence_line_highlight color darker/lighter
--- so the two stay visually related but distinguishable; `hl` bypasses that
--- and sets an explicit look instead.
---@class ColorMyAscii.FenceContentHighlight
---@field enable? boolean Paint the interior of fenced blocks (default true)
---@field preset? ColorMyAscii.FencePreset Base look to shade from (default: nil, i.e. follow fence_line_highlight.preset)
---@field hl? string|ColorMyAscii.CustomHighlight Explicit override (hl group name or attr table); bypasses shading entirely
---@field shade? "auto"|"darken"|"lighten"|"none" Shade direction relative to the resolved base color (default "auto": darken on dark backgrounds, lighten on light; "none" uses the base color unshaded)
---@field amount? integer 0-100 blend strength toward black/white (default 6)
---@field apply_to? "all"|"ascii" Which blocks' interior gets painted (default "all")
---@field respect_indent? boolean Like FenceLineHighlight.respect_indent, for the interior rows (default true)
---@field right_pad? integer Like FenceLineHighlight.right_pad, for the interior rows (default 1)

---@class ColorMyAscii.FenceRun
---@field runners? table<string, string|string[]> Interpreter per language tag (temp file appended)

---@class ColorMyAscii.FenceFormat
---@field formatters? table<string, string[]> stdin/stdout formatter command per language tag

---@class ColorMyAscii.FenceExport
---@field default_dir? "buffer"|"cwd" Where the suggested export path lives (default "buffer")
---@field open_after? boolean Open the exported file afterwards (default false; --open forces it)
---@field open_cmd? string Command used to open ("edit"|"split"|"vsplit"|"tabedit", default "vsplit")
---@field replace? boolean Replace the fenced block with a link reference (default false; --replace forces it)
---@field replace_format? string string.format template for the reference; args are (filename, relpath)
---@field ext_map? table<string, string> Language-tag -> file-extension overrides

--- Extends ASCII-block detection to code comments outside markdown, via an
--- explicit marker (`-- ascii` … `-- /ascii`, using the buffer's own
--- line-comment prefix) instead of ``` fences. Off by default - unlike most
--- other features, this activates the plugin on non-markdown filetypes.
---@class ColorMyAscii.CommentAscii
---@field enable? boolean Detect and highlight `-- ascii` ... `-- /ascii` blocks in comments (default false)
---@field filetypes? string[] Filetypes to activate on when enabled (default: a broad built-in list of languages with a simple line-comment prefix)

---@class ColorMyAscii.TreesitterConfig
---@field enabled? boolean Master switch for both features below (default true; both sub-features fall back to heuristic-only behavior when no parser is installed)
---@field block_detection? boolean Use treesitter's markdown grammar to detect fenced code blocks instead of the heuristic line scanner (default true, only applies if enabled=true)
---@field syntax_highlight? boolean Use treesitter to highlight real syntax inside blocks with the target language's grammar, in addition to the heuristic character/keyword highlighting (default true, only applies if enabled=true). Best-effort: silently falls back to heuristic-only if no parser is available or the content doesn't parse.

---@class ColorMyAscii.Config
---@field scheme? ColorMyAscii.SchemeName Color scheme name to load (e.g., "nord", "gruvbox")
---@field debug_enabled? boolean Toggle debug mode
---@field debug_verbose? boolean Toggle write debug logs to file
---@field groups? table<string, ColorMyAscii.CharGroup> Named character groups with their highlight settings
---@field keywords? table<string, ColorMyAscii.KeywordGroup> Language-specific keyword definitions (built-ins + `languages`, merged; usually left alone in favor of `languages` below)
---@field languages? table<string, ColorMyAscii.KeywordGroup> User-defined languages, merged on top of the built-in languages/*.lua set at setup() (same entry shape: { words, unique_words?, hl }; reusing a built-in name overrides it). The intended extension point for adding a language without forking the plugin - see |color_my_ascii-config-languages|
---@field custom_groups? table<string, ColorMyAscii.CustomGroup> User-defined character groups with custom highlights
---@field overrides? table<string, string|ColorMyAscii.CustomHighlight> Individual character to highlight group mappings (highest priority)
---@field default_hl? string|ColorMyAscii.CustomHighlight Default highlight group for characters not matching any rules
---@field default_text_hl? string|ColorMyAscii.CustomHighlight Optional highlight group for normal text in blocks (nil = no change)
---@field enable_keywords? boolean Whether to highlight keywords in ASCII blocks
---@field enable_language_detection? boolean Whether to use heuristic language detection
---@field language_detection_threshold? integer Minimum unique keyword matches for language detection
---@field treesitter? ColorMyAscii.TreesitterConfig Optional treesitter-based block detection and syntax highlighting
---@field comment_ascii? ColorMyAscii.CommentAscii Optional detection/highlighting of explicitly-marked ASCII blocks inside code comments, outside markdown
---@field treat_empty_fence_as_ascii? boolean Treat `` without language as ASCII block
---@field enable_inline_code? boolean Enable highlighting in inline code ...`)
---@field enable_function_names? boolean Enable heuristic function name detection
---@field enable_bracket_highlighting? boolean Enable highlighting of brackets/parentheses
---@field fence_language_map? table<string, string> Map of markdown fence language tags to plugin language names (e.g., { vim = "vim" })
---@field fence_line_highlight? ColorMyAscii.FenceLineHighlight Optional full-line highlight of fence delimiter lines
---@field fence_content_highlight? ColorMyAscii.FenceContentHighlight Optional full-width background highlight of a fenced block's interior
---@field fence_export? ColorMyAscii.FenceExport Behaviour of the `:Fence export` command
---@field fence_run? ColorMyAscii.FenceRun Interpreter map for `:Fence run`
---@field fence_format? ColorMyAscii.FenceFormat Formatter map for `:Fence format`
---@field keymaps? false|table<string, string> Optional default keymaps (action name -> lhs). false (default) disables all keymaps. See lua/color_my_ascii/bindings/keymaps.lua
---@field cache? CacheConfig Optional override for cache_manager defaults
---@field debounce? DebounceConfig Optional override for debounce_manager defaults
---@field menu? ColorMyAscii.MenuConfig `color_my_ascii.integrations.menu` (nvzone/menu context-menu contribution) opt-out

--- Opt-out for `color_my_ascii.integrations.menu`. color_my_ascii.nvim has
--- no nvzone/menu dependency itself; this only gates whether
--- `M.items()`/`M.submenu()` return entries.
---@class ColorMyAscii.MenuConfig
---@field enable? boolean default true

---@class ColorMyAscii.State
---@field enabled boolean Whether the plugin is currently enabled
---@field buffers table<integer, boolean> Set of buffers with active highlighting

---@class ColorMyAscii.Block
---@field start_line integer Starting line number (0-indexed)
---@field end_line integer Ending line number (0-indexed, inclusive)
---@field lines string[] Content lines of the block (without fence markers)
---@field fence_line string Opening fence line (for language detection)

--- Rich, language-agnostic fenced-code-block descriptor returned by the public
--- fence API (`color_my_ascii.api.fences`) and the generic scanners in
--- `parser`/`parser_ts`. Superset of ColorMyAscii.Block: the `start_line`/
--- `end_line`/`lines`/`fence_line` fields are kept as aliases so existing
--- ASCII-highlighting consumers keep working unchanged.
---@class ColorMyAscii.HlRun
---@field text string A stretch of text sharing one highlight group
---@field group string|nil nil = no color_my_ascii highlight on this run

---@class ColorMyAscii.HlAttrs
---@field fg? string Foreground as "#rrggbb"
---@field bg? string Background as "#rrggbb"
---@field bold? boolean
---@field italic? boolean
---@field underline? boolean
---@field strikethrough? boolean

---@class ColorMyAscii.FenceBlock
---@field open_row integer 0-indexed row of the opening fence delimiter
---@field close_row integer 0-indexed row of the closing fence delimiter
---@field content_start integer 0-indexed first content row (== open_row + 1)
---@field content_end integer 0-indexed exclusive end of content (== close_row); content rows are [content_start, content_end)
---@field lang string Trimmed fence language tag ("" if none)
---@field fence_char string Fence delimiter character ("`" or "~")
---@field fence_len integer Number of delimiter characters in the opening fence
---@field is_ascii boolean Whether color_my_ascii classifies this block as ASCII
---@field lines? string[] Content lines (populated only when requested via `lines` opt)
---@field fence_line string Opening fence line text (for language detection)
---@field start_line integer Alias of open_row (ColorMyAscii.Block compat)
---@field end_line integer Alias of close_row (ColorMyAscii.Block compat)

---@class ColorMyAscii.InlineCode
---@field line integer Line number (0-indexed)
---@field start_col integer Start column (0-indexed, byte offset)
---@field end_col integer End column (0-indexed, byte offset, exclusive)
---@field content string Content inside backticks

---@class OpenFenceInfo
---@field start_line integer Line number where block starts (1-indexed)
---@field fence_line string The opening fence line content
---@field fence_length integer Length of the fence sequence
---@field is_ascii boolean Whether this is an ASCII block we want to highlight
---@field block_lines string[] Accumulated block content lines (only for ASCII blocks)

---@class CacheEntry
---@field blocks ColorMyAscii.Block[] Parsed ASCII blocks
---@field inline_codes ColorMyAscii.InlineCode[] Parsed inline code segments
---@field timestamp number Cache creation timestamp (ms)
---@field changedtick number Buffer changedtick at cache time
---@field line_count integer Number of lines in buffer at cache time

---@class CacheConfig
---@field timeout? integer Cache validity timeout in milliseconds
---@field max_size? integer Maximum number of cached buffers
---@field enable_stats? boolean Whether to collect statistics

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
