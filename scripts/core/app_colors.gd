extends Node

# Block Colors (Luminous on dark)
var CORAL := Color("EF4444")
var CORAL_LIGHT := Color("FCA5A5")
var CORAL_GLOW := Color(Color("EF4444"), 0.35)

var AMBER := Color("F59E0B")
var AMBER_LIGHT := Color("FCD34D")
var AMBER_GLOW := Color(Color("F59E0B"), 0.35)

var LEMON := Color("EAB308")
var LEMON_LIGHT := Color("FDE047")
var LEMON_GLOW := Color(Color("EAB308"), 0.35)

var MINT := Color("10B981")
var MINT_LIGHT := Color("6EE7B7")
var MINT_GLOW := Color(Color("10B981"), 0.35)

var SKY := Color("06B6D4")
var SKY_LIGHT := Color("67E8F9")
var SKY_GLOW := Color(Color("06B6D4"), 0.35)

var LAVENDER := Color("8B5CF6")
var LAVENDER_LIGHT := Color("C4B5FD")
var LAVENDER_GLOW := Color(Color("8B5CF6"), 0.35)

var SPECIAL := Color("FFD700")

# Dark Theme UI
var BACKGROUND := Color("0D1B2A")
var CARD_SURFACE := Color("162236")
var CARD_BORDER := Color("1E3148")
var ACCENT := Color("14B8A6")
var ACCENT_TEXT := Color("2DD4BF")
var TEXT_PRIMARY := Color("FFFFFF")
var TEXT_SECONDARY := Color("6B8A9E")
var TEXT_MUTED := Color("4A6577")
var BORDER := Color("243B53")
var GRID_LINE := Color("1A2940")

# Ghost/highlight
var HIGHLIGHT_VALID := Color(Color("10B981"), 0.25)
var HIGHLIGHT_INVALID := Color(Color("EF4444"), 0.25)

# Empty cell (matches board background)
var EMPTY_CELL := Color("0F1D32")
var EMPTY_BORDER := Color("1C2E45")

# Board
var BOARD_BG := Color("0F1D32")
var BOARD_BORDER := Color("1C2E45")


func get_block_color(block_color: int) -> Color:
	match block_color:
		Enums.BlockColor.CORAL: return CORAL
		Enums.BlockColor.AMBER: return AMBER
		Enums.BlockColor.LEMON: return LEMON
		Enums.BlockColor.MINT: return MINT
		Enums.BlockColor.SKY: return SKY
		Enums.BlockColor.LAVENDER: return LAVENDER
		Enums.BlockColor.SPECIAL: return SPECIAL
	return Color.GRAY


func get_block_light_color(block_color: int) -> Color:
	match block_color:
		Enums.BlockColor.CORAL: return CORAL_LIGHT
		Enums.BlockColor.AMBER: return AMBER_LIGHT
		Enums.BlockColor.LEMON: return LEMON_LIGHT
		Enums.BlockColor.MINT: return MINT_LIGHT
		Enums.BlockColor.SKY: return SKY_LIGHT
		Enums.BlockColor.LAVENDER: return LAVENDER_LIGHT
		Enums.BlockColor.SPECIAL: return SPECIAL
	return Color.WHITE


func get_block_glow_color(block_color: int) -> Color:
	match block_color:
		Enums.BlockColor.CORAL: return CORAL_GLOW
		Enums.BlockColor.AMBER: return AMBER_GLOW
		Enums.BlockColor.LEMON: return LEMON_GLOW
		Enums.BlockColor.MINT: return MINT_GLOW
		Enums.BlockColor.SKY: return SKY_GLOW
		Enums.BlockColor.LAVENDER: return LAVENDER_GLOW
		Enums.BlockColor.SPECIAL: return Color(1.0, 0.84, 0.0, 0.35)
	return Color.TRANSPARENT
