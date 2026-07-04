---@module 'color_my_ascii.languages.css'
--- CSS keyword definitions for ASCII art highlighting
--- CSS has no control-flow keywords - "words" here are common property names,
--- values, and at-rules instead, since that's what identifies CSS content.
--- Hyphenated names (nth-child, font-face) are split into their parts since
--- the plugin's tokenizer treats hyphens as word boundaries.

---@type ColorMyAscii.KeywordGroup
return {
  words = {
    -- Layout properties
    'display', 'position', 'flex', 'grid', 'float', 'clear',
    'width', 'height', 'margin', 'padding', 'border',
    -- Typography
    'color', 'background', 'font', 'text', 'align',
    -- Values
    'block', 'inline', 'absolute', 'relative', 'fixed', 'sticky',
    'none', 'auto', 'inherit', 'initial',
    -- At-rules
    'media', 'import', 'keyframes', 'supports',
    -- Pseudo-classes/elements
    'hover', 'focus', 'active', 'before', 'after', 'nth', 'child',
    -- Units/functions
    'calc', 'var', 'rgba', 'rgb', 'url',
    -- Important
    'important',
  },

  -- Keywords unique to CSS
  unique_words = {
    'keyframes', 'rgba', 'important',
  },

  hl = 'Type',
}
