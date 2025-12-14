---@module 'color_my_ascii.schemes.onedark'
--- One Dark color scheme for color_my_ascii.nvim
--- Atom-inspired dark theme with vibrant syntax colors

---@type ColorMyAscii.Config
return {
  groups = {
    box_drawing = {
      chars = "─│┌┐└┘├┤┬┴┼═║╔╗╚╝╠╣╦╩╬╒╓╕╖╘╙╛╜╞╟╡╢╤╥╧╨╪╫╭╮╯╰╱╲╳╴╵╶╷",
      hl = { fg = '#61afef', bold = true }, -- One Dark blue
    },
    blocks = {
      chars = "█▓▒░▀▄▌▐▖▗▘▝▞▟■□▪▫▬▭▮▯▰▱",
      hl = { fg = '#56b6c2' }, -- One Dark cyan
    },
    arrows = {
      chars = "←→↑↓⇐⇒⇑⇓↖↗↘↙⇖⇗⇘⇙⇠⇢⇡⇣⟵⟶⟷↰↱↲↳↴↵⤴⤵↼⇀↽⇁↶↷↺↻↔⇔⇄⇅⇆⇵➔➘➙➚➛➜➝➞➟➠➡➢➣➤➥➦➧➨",
      hl = { fg = '#c678dd', bold = true }, -- One Dark purple
    },
    symbols = {
      chars = "•·∙●○◦‣▸▹►▻◂◃◄◅▲△▴▵▶▷▼▽▾▿◀◁◆◇★☆✦✧✶✴✵✷✸✓✔✗✘✕✖♠♣♥♦♩♪♫♬⊕⊗⊙⊚⊛※⁂⁎⁕℃℉°∞√∑∏∫≈≠≤≥",
      hl = { fg = '#e5c07b' }, -- One Dark yellow
    },
    operators = {
      chars = "+-*/%=<>!&|^~()[]{}:;,.?\"'`@#\\",
      hl = { fg = '#98c379' }, -- One Dark green
    },
  },

  overrides = {},

  default_hl = 'Normal',
  default_text_hl = { fg = '#5c6370' }, -- One Dark comment

  enable_keywords = true,
  enable_language_detection = true,
  language_detection_threshold = 2,
  enable_function_names = true,
  enable_bracket_highlighting = true,
  treat_empty_fence_as_ascii = false,
  enable_inline_code = true,
}
