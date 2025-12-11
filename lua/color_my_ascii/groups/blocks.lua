---@module 'color_my_ascii.groups.blocks'
--- Block element character group definitions

---@type ColorMyAscii.CharGroup
local group = {
	chars = "",
	hl = "Type",
}

-- Build character string
local chars = {
	-- Full and partial blocks
	"█",
	"▓",
	"▒",
	"░",
	-- Half blocks
	"▀",
	"▄",
	"▌",
	"▐",
	-- Quarter and eighth blocks
	"▖",
	"▗",
	"▘",
	"▝",
	"▞",
	"▟",
	-- Small blocks
	"■",
	"□",
	"▪",
	"▫",
	"▬",
	"▭",
	"▮",
	"▯",
	-- Shaded blocks
	"▰",
	"▱",
}

group.chars = table.concat(chars, "")

return group
