---@module 'color_my_ascii.groups.symbols'
--- Miscellaneous symbol character group definitions

---@type ColorMyAscii.CharGroup
local group = {
	chars = "",
	hl = "Delimiter",
}

-- Build character string
local chars = {
	-- Bullets and dots
	"•",
	"·",
	"∙",
	"●",
	"○",
	"◦",
	"‣",
	-- Triangles and pointers
	"▸",
	"▹",
	"►",
	"▻",
	"◂",
	"◃",
	"◄",
	"◅",
	"▲",
	"△",
	"▴",
	"▵",
	"▶",
	"▷",
	"▼",
	"▽",
	"▾",
	"▿",
	"◀",
	"◁",
	"◆",
	"◇",
	-- Stars
	"★",
	"☆",
	"✦",
	"✧",
	"✶",
	"✴",
	"✵",
	"✷",
	"✸",
	-- Checkmarks and crosses
	"✓",
	"✔",
	"✗",
	"✘",
	"✕",
	"✖",
	-- Card suits
	"♠",
	"♣",
	"♥",
	"♦",
	-- Musical symbols
	"♩",
	"♪",
	"♫",
	"♬",
	-- Miscellaneous
	"⊕",
	"⊗",
	"⊙",
	"⊚",
	"⊛",
	"※",
	"⁂",
	"⁎",
	"⁕",
	"℃",
	"℉",
	"°",
	"∞",
	"√",
	"∑",
	"∏",
	"∫",
	"≈",
	"≠",
	"≤",
	"≥",
}

group.chars = table.concat(chars, "")

return group
