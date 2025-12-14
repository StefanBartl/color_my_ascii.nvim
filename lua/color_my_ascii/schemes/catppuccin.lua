---@module 'color_my_ascii.schemes.catppuccin'
--- Catppuccin color scheme for color_my_ascii.nvim
--- Soft pastel colors with warm undertones, based on Catppuccin Mocha

---@type ColorMyAscii.Config
return {
  groups = {
    box_drawing = {
      chars = "─│┌┐└┘├┤┬┴┼═║╔╗╚╝╠╣╦╩╬╒╓╕╖╘╙╛╜╞╟╡╢╤╥╧╨╪╫╭╮╯╰╱╲╳╴╵╶╷",
      hl = { fg = '#89b4fa' }, -- Catppuccin blue
    },
    blocks = {
      chars = "█▓▒░▀▄▌▐▖▗▘▝▞▟■□▪▫▬▭▮▯▰▱",
      hl = { fg = '#74c7ec' }, -- Catppuccin sapphire
    },
    arrows = {
      chars = "←→↑↓⇐⇒⇑⇓↖↗↘↙⇖⇗⇘⇙⇠⇢⇡⇣⟵⟶⟷↰↱↲↳↴↵⤴⤵↼⇀↽⇁↶↷↺↻↔⇔⇄⇅⇆⇵➔➘➙➚➛➜➝➞➟➠➡➢➣➤➥➦➧➨",
      hl = { fg = '#f5c2e7', bold = true }, -- Catppuccin pink
    },
    symbols = {
      chars = "•·∙●○◦‣▸▹►▻◂◃◄◅▲△▴▵▶▷▼▽▾▿◀◁◆◇★☆✦✧✶✴✵✷✸✓✔✗✘✕✖♠♣♥♦♩♪♫♬⊕⊗⊙⊚⊛※⁂⁎⁕℃℉°∞√∑∏∫≈≠≤≥",
      hl = { fg = '#cba6f7' }, -- Catppuccin mauve
    },
    operators = {
      chars = "+-*/%=<>!&|^~()[]{}:;,.?\"'`@#\\",
      hl = { fg = '#89dceb' }, -- Catppuccin sky
    },
  },

  overrides = {},

  default_hl = 'Normal',
  default_text_hl = { fg = '#585b70' }, -- Catppuccin surface2

  enable_keywords = true,
  enable_language_detection = true,
  language_detection_threshold = 2,
  enable_function_names = true,
  enable_bracket_highlighting = false,
  treat_empty_fence_as_ascii = false,
  enable_inline_code = true,
}
