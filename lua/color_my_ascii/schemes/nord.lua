---@module 'color_my_ascii.schemes.nord'
--- Nord color scheme for color_my_ascii.nvim
--- Based on the popular Nord theme with cool blue/cyan colors

---@type ColorMyAscii.Config
return {
  groups = {
    box_drawing = {
      chars = "─│┌┐└┘├┤┬┴┼═║╔╗╚╝╠╣╦╩╬╒╓╕╖╘╙╛╜╞╟╡╢╤╥╧╨╪╫╭╮╯╰╱╲╳╴╵╶╷",
      hl = { fg = '#88c0d0' }, -- Nord Frost (cyan)
    },
    blocks = {
      chars = "█▓▒░▀▄▌▐▖▗▘▝▞▟■□▪▫▬▭▮▯▰▱",
      hl = { fg = '#81a1c1' }, -- Nord Frost (blue)
    },
    arrows = {
      chars = "←→↑↓⇐⇒⇑⇓↖↗↘↙⇖⇗⇘⇙⇠⇢⇡⇣⟵⟶⟷↰↱↲↳↴↵⤴⤵↼⇀↽⇁↶↷↺↻↔⇔⇄⇅⇆⇵➔➘➙➚➛➜➝➞➟➠➡➢➣➤➥➦➧➨",
      hl = { fg = '#8fbcbb', bold = true }, -- Nord Frost (bright cyan)
    },
    symbols = {
      chars = "•·∙●○◦‣▸▹►▻◂◃◄◅▲△▴▵▶▷▼▽▾▿◀◁◆◇★☆✦✧✶✴✵✷✸✓✔✗✘✕✖♠♣♥♦♩♪♫♬⊕⊗⊙⊚⊛※⁂⁎⁕℃℉°∞√∑∏∫≈≠≤≥",
      hl = { fg = '#b48ead' }, -- Nord Aurora (purple)
    },
    operators = {
      chars = "+-*/%=<>!&|^~()[]{}:;,.?\"'`@#\\",
      hl = { fg = '#81a1c1' }, -- Nord Frost (blue)
    },
  },

  overrides = {
    -- Highlight corners specially
    ['┌'] = { fg = '#88c0d0', bold = true },
    ['┐'] = { fg = '#88c0d0', bold = true },
    ['└'] = { fg = '#88c0d0', bold = true },
    ['┘'] = { fg = '#88c0d0', bold = true },
  },

  default_hl = 'Normal',
  default_text_hl = { fg = '#616e88' }, -- Nord dimmed text

  enable_keywords = true,
  enable_language_detection = true,
  language_detection_threshold = 2,
  enable_function_names = true,
  enable_bracket_highlighting = false,
  treat_empty_fence_as_ascii = false,
  enable_inline_code = false,
}
