---@module 'color_my_ascii.languages.json'
--- JSON keyword definitions for ASCII art highlighting
--- JSON has no control-flow keywords, only three literal values. It relies on
--- explicit tagging (```json or ```ascii-json, or fence_language_map) rather
--- than heuristic detection - no unique_words are registered since these
--- three values are common to many other languages too.

---@type ColorMyAscii.KeywordGroup
return {
  words = {
    'true', 'false', 'null',
  },

  hl = 'Constant',
}
