---@module 'color_my_ascii.groups.box_drawing'
--- Box drawing character group definitions

---@type ColorMyAscii.CharGroup
local group = {
	-- Unicode box drawing characters (light, heavy, double, rounded)
	chars = "",
	hl = "Keyword",
}

-- Build character string
local chars = {
	-- Light box drawing
	"─",
	"│",
	"┌",
	"┐",
	"└",
	"┘",
	"├",
	"┤",
	"┬",
	"┴",
	"┼",
	-- Heavy box drawing
	"═",
	"║",
	"╔",
	"╗",
	"╚",
	"╝",
	"╠",
	"╣",
	"╦",
	"╩",
	"╬",
	-- Light and heavy combinations
	"╒",
	"╓",
	"╕",
	"╖",
	"╘",
	"╙",
	"╛",
	"╜",
	"╞",
	"╟",
	"╡",
	"╢",
	"╤",
	"╥",
	"╧",
	"╨",
	"╪",
	"╫",
	-- Rounded corners
	"╭",
	"╮",
	"╯",
	"╰",
	-- Diagonal lines
	"╱",
	"╲",
	"╳",
	-- Arc corners
	"╴",
	"╵",
	"╶",
	"╷",
}

group.chars = table.concat(chars, "")

return group
