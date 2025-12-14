---@module 'color_my_ascii.schemes.solarized'
--- Solarized color scheme for color_my_ascii.nvim
--- Precision colors for readability, based on Solarized Dark

---@type ColorMyAscii.Config
return {
  groups = {
    box_drawing = {
      chars = "─│┌┐└┘├┤┬┴┼═║╔╗╚╝╠╣╦╩╬╒╓╕╖╘╙╛╜╞╟╡╢╤╥╧╨╪╫╭╮╯╰╱╲╳╴╵╶╷",
      hl = { fg = '#268bd2' }, -- Solarized blue
    },
    blocks = {
      chars = "█▓▒░▀▄▌▐▖▗▘▝▞▟■□▪▫▬▭▮▯▰▱",
      hl = { fg = '#2aa198' }, -- Solarized cyan
    },
    arrows = {
      chars = "←→↑↓⇐⇒⇑⇓↖↗↘↙⇖⇗⇘⇙⇠⇢⇡⇣⟵⟶⟷↰↱↲↳↴↵⤴⤵↼⇀↽⇁↶↷↺↻↔⇔⇄⇅⇆⇵➔➘➙➚➛➜➝➞➟➠➡➢➣➤➥➦➧➨",
      hl = { fg = '#d33682', bold = true }, -- Solarized magenta
    },
    symbols = {
      chars = "•·∙●○◦‣▸▹►▻◂◃◄◅▲△▴▵▶▷▼▽▾▿◀◁◆◇★☆✦✧✶✴✵✷✸✓✔✗✘✕✖♠♣♥♦♩♪♫♬⊕⊗⊙⊚⊛※⁂⁎⁕℃℉°∞√∑∏∫≈≠≤≥",
      hl = { fg = '#6c71c4' }, -- Solarized violet
    },
    operators = {
      chars = "+-*/%=<>!&|^~()[]{}:;,.?\"'`@#\\",
      hl = { fg = '#859900' }, -- Solarized green
    },
  },

  overrides = {},

  default_hl = 'Normal',
  default_text_hl = { fg = '#586e75' }, -- Solarized base01

  enable_keywords = true,
  enable_language_detection = true,
  language_detection_threshold = 2,
  enable_function_names = false,
  enable_bracket_highlighting = false,
  treat_empty_fence_as_ascii = false,
  enable_inline_code = false,
}
