---@module 'color_my_ascii.languages.html'
--- HTML keyword definitions for ASCII art highlighting
--- HTML has no control-flow keywords - "words" here are common tag names and
--- attributes instead, since that's what identifies HTML content.

---@type ColorMyAscii.KeywordGroup
return {
  words = {
    -- Document structure
    'html',
    'head',
    'body',
    'title',
    'meta',
    'link',
    'script',
    'style',
    -- Sectioning
    'div',
    'span',
    'header',
    'footer',
    'nav',
    'main',
    'section',
    'article',
    'aside',
    -- Text content
    'p',
    'a',
    'ul',
    'ol',
    'li',
    'table',
    'tr',
    'td',
    'th',
    'thead',
    'tbody',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    -- Forms and media
    'form',
    'input',
    'button',
    'label',
    'select',
    'option',
    'textarea',
    'img',
    'video',
    'audio',
    'canvas',
    'svg',
    -- Common attributes
    'class',
    'id',
    'href',
    'src',
    'alt',
    'type',
    'name',
    'value',
    'placeholder',
    'DOCTYPE',
  },

  -- Keywords unique to HTML
  unique_words = {
    'DOCTYPE',
    'textarea',
    'placeholder',
    'thead',
    'tbody',
  },

  hl = 'Statement',
}
