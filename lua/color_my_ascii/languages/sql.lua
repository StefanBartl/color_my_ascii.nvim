---@module 'color_my_ascii.languages.sql'
--- SQL keyword definitions for ASCII art highlighting

---@type ColorMyAscii.KeywordGroup
return {
  words = {
    -- Query structure
    'SELECT', 'FROM', 'WHERE', 'JOIN', 'INNER', 'LEFT', 'RIGHT', 'OUTER', 'ON',
    'GROUP', 'BY', 'ORDER', 'HAVING', 'DISTINCT', 'AS', 'LIMIT', 'OFFSET', 'UNION',
    -- Data manipulation
    'INSERT', 'INTO', 'VALUES', 'UPDATE', 'SET', 'DELETE',
    -- Schema
    'CREATE', 'TABLE', 'ALTER', 'DROP', 'INDEX',
    'PRIMARY', 'KEY', 'FOREIGN', 'REFERENCES', 'UNIQUE', 'DEFAULT',
    -- Conditions
    'AND', 'OR', 'NOT', 'IN', 'BETWEEN', 'LIKE', 'EXISTS', 'NULL',
    'CASE', 'WHEN', 'THEN', 'END',
  },

  -- Keywords unique to SQL
  unique_words = {
    'SELECT', 'INSERT', 'DELETE', 'JOIN', 'HAVING',
  },

  hl = 'Statement',
}
