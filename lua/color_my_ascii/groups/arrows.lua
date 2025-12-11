---@module 'color_my_ascii.groups.arrows'
--- Arrow character group definitions

---@type ColorMyAscii.CharGroup
local group = {
	chars = "",
	hl = "Special",
}

-- Build character string
local chars = {
	-- Basic arrows
	"←",
	"→",
	"↑",
	"↓",
	-- Double arrows
	"⇐",
	"⇒",
	"⇑",
	"⇓",
	-- Diagonal arrows
	"↖",
	"↗",
	"↘",
	"↙",
	"⇖",
	"⇗",
	"⇘",
	"⇙",
	-- Heavy arrows
	"⇠",
	"⇢",
	"⇡",
	"⇣",
	-- Long arrows
	"⟵",
	"⟶",
	"⟷",
	-- Curved arrows
	"↰",
	"↱",
	"↲",
	"↳",
	"↴",
	"↵",
	"⤴",
	"⤵",
	-- Harpoons
	"↼",
	"⇀",
	"↽",
	"⇁",
	-- Circular arrows
	"↶",
	"↷",
	"↺",
	"↻",
	-- Double-headed arrows
	"↔",
	"⇔",
	"⇄",
	"⇅",
	"⇆",
	"⇵",
	-- Special arrows
	"➔",
	"➘",
	"➙",
	"➚",
	"➛",
	"➜",
	"➝",
	"➞",
	"➟",
	"➠",
	"➡",
	"➢",
	"➣",
	"➤",
	"➥",
	"➦",
	"➧",
	"➨",
}

group.chars = table.concat(chars, "")

return group
