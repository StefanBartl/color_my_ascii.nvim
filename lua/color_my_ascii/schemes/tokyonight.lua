---@module 'color_my_ascii.schemes.tokyonight'
--- Tokyo Night color scheme for color_my_ascii.nvim
--- Deep blue night colors with vibrant accents, based on Tokyo Night Storm

---@type ColorMyAscii.Config
return {
  groups = {
    box_drawing = {
      chars = "─│┌┐└┘├┤┬┴┼═║╔╗╚╝╠╣╦╩╬╒╓╕╖╘╙╛╜╞╟╡╢╤╥╧╨╪╫╭╮╯╰╱╲╳╴╵╶╷",
      hl = { fg = '#7aa2f7', bold = true }, -- Tokyo Night blue
    },
    blocks = {
      chars = "█▓▒░▀▄▌▐▖▗▘▝▞▟■□▪▫▬▭▮▯▰▱",
      hl = { fg = '#2ac3de' }, -- Tokyo Night cyan
    },
    arrows = {
      chars = "←→↑↓⇐⇒⇑⇓↖↗↘↙⇖⇗⇘⇙⇠⇢⇡⇣⟵⟶⟷↰↱↲↳↴↵⤴⤵↼⇀↽⇁↶↷↺↻↔⇔⇄⇅⇆⇵➔➘➙➚➛➜➝➞➟➠➡➢➣➤➥➦➧➨",
      hl = { fg = '#bb9af7', bold = true }, -- Tokyo Night purple
    },
    symbols = {
      chars = "•·∙●○◦‣▸▹►▻◂◃◄◅▲△▴▵▶▷▼▽▾▿◀◁◆◇★☆✦✧✶✴✵✷✸✓✔✗✘✕✖♠♣♥♦♩♪♫♬⊕⊗⊙⊚⊛※⁂⁎⁕℃℉°∞√∑∏∫≈≠≤≥",
      hl = { fg = '#ff9e64' }, -- Tokyo Night orange
    },
    operators = {
      chars = "+-*/%=<>!&|^~()[]{}:;,.?\"'`@#\\",
      hl = { fg = '#9ece6a' }, -- Tokyo Night green
    },
  },

  overrides = {},

  default_hl = 'Normal',
  default_text_hl = { fg = '#565f89' }, -- Tokyo Night comment

  enable_keywords = true,
  enable_language_detection = true,
  language_detection_threshold = 2,
  enable_function_names = true,
  enable_bracket_highlighting = true,
  treat_empty_fence_as_ascii = false,
  enable_inline_code = true,
}
