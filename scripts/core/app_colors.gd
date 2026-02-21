extends Node

# 기본 블록 색상 (default 테마 — Soft & Bright)
var CORAL := Color("FF8A8A")
var CORAL_LIGHT := Color("FFB8B8")
var CORAL_GLOW := Color(Color("FF8A8A"), 0.35)

var AMBER := Color("FFB347")
var AMBER_LIGHT := Color("FFD08A")
var AMBER_GLOW := Color(Color("FFB347"), 0.35)

var LEMON := Color("FFD93D")
var LEMON_LIGHT := Color("FFE57A")
var LEMON_GLOW := Color(Color("FFD93D"), 0.35)

var MINT := Color("6BCB77")
var MINT_LIGHT := Color("A8E6A3")
var MINT_GLOW := Color(Color("6BCB77"), 0.35)

var SKY := Color("4FC3F7")
var SKY_LIGHT := Color("8AD4F8")
var SKY_GLOW := Color(Color("4FC3F7"), 0.35)

var LAVENDER := Color("9B8EC4")
var LAVENDER_LIGHT := Color("C5BBE0")
var LAVENDER_GLOW := Color(Color("9B8EC4"), 0.35)

var SPECIAL := Color("FFD700")

# Light Theme UI — Soft & Bright
var BACKGROUND := Color("F5F0EB")
var CARD_SURFACE := Color("FFFFFF")
var CARD_BORDER := Color("E8E0D8")
var ACCENT := Color("FF6B6B")
var ACCENT_TEXT := Color("FF8A8A")
var TEXT_PRIMARY := Color("2D2D2D")
var TEXT_SECONDARY := Color("8E8E93")
var TEXT_MUTED := Color("AEAEB2")
var BORDER := Color("E8E0D8")
var GRID_LINE := Color("DDD5CC")

# Score popup accents
var GOLDEN := Color("FFD700")
var SAGE_GREEN := Color("6BCB77")

# Ghost/highlight
var HIGHLIGHT_VALID := Color(Color("6BCB77"), 0.30)
var HIGHLIGHT_INVALID := Color(Color("FF8A8A"), 0.30)

# Empty cell (warm beige)
var EMPTY_CELL := Color("EDE7E0")
var EMPTY_BORDER := Color("DDD5CC")

# Board
var BOARD_BG := Color("E8E0D8")
var BOARD_BORDER := Color("DDD5CC")

# 테마 변경 시그널 — UI 갱신에 사용
signal theme_changed()

# 현재 적용 중인 테마 ID 캐시 (성능 최적화)
var _current_theme_id: String = "default"
# 현재 테마 색상 캐시
var _cached_colors: Dictionary = {}


func _ready() -> void:
	# 저장된 테마를 로드하여 적용
	_apply_theme(ThemeSystem.get_current_theme())


## 테마를 변경하고 색상 캐시를 갱신
func apply_theme(theme_id: String) -> void:
	if theme_id == _current_theme_id:
		return
	_apply_theme(theme_id)
	theme_changed.emit()


## 내부: 테마 색상 적용
func _apply_theme(theme_id: String) -> void:
	_current_theme_id = theme_id
	if theme_id == "default":
		_cached_colors = {}
	else:
		_cached_colors = ThemeSystem.get_theme_colors(theme_id)


func get_block_color(block_color: int) -> Color:
	# default 테마이면 기존 하드코딩 색상 사용 (성능 최적화)
	if _current_theme_id == "default":
		return _get_default_block_color(block_color)
	# 테마 색상에서 bg 값 반환
	if _cached_colors.has(block_color):
		return _cached_colors[block_color]["bg"]
	return _get_default_block_color(block_color)


func get_block_light_color(block_color: int) -> Color:
	if _current_theme_id == "default":
		return _get_default_block_light_color(block_color)
	if _cached_colors.has(block_color):
		return _cached_colors[block_color]["light"]
	return _get_default_block_light_color(block_color)


func get_block_glow_color(block_color: int) -> Color:
	if _current_theme_id == "default":
		return _get_default_block_glow_color(block_color)
	# glow 색상은 bg에 알파 0.35 적용
	if _cached_colors.has(block_color):
		var bg_color: Color = _cached_colors[block_color]["bg"]
		return Color(bg_color.r, bg_color.g, bg_color.b, 0.35)
	return _get_default_block_glow_color(block_color)


# --- 기본 테마 색상 (원본 하드코딩) ---

func _get_default_block_color(block_color: int) -> Color:
	match block_color:
		Enums.BlockColor.CORAL: return CORAL
		Enums.BlockColor.AMBER: return AMBER
		Enums.BlockColor.LEMON: return LEMON
		Enums.BlockColor.MINT: return MINT
		Enums.BlockColor.SKY: return SKY
		Enums.BlockColor.LAVENDER: return LAVENDER
		Enums.BlockColor.SPECIAL: return SPECIAL
	return Color.GRAY


func _get_default_block_light_color(block_color: int) -> Color:
	match block_color:
		Enums.BlockColor.CORAL: return CORAL_LIGHT
		Enums.BlockColor.AMBER: return AMBER_LIGHT
		Enums.BlockColor.LEMON: return LEMON_LIGHT
		Enums.BlockColor.MINT: return MINT_LIGHT
		Enums.BlockColor.SKY: return SKY_LIGHT
		Enums.BlockColor.LAVENDER: return LAVENDER_LIGHT
		Enums.BlockColor.SPECIAL: return SPECIAL
	return Color.WHITE


func _get_default_block_glow_color(block_color: int) -> Color:
	match block_color:
		Enums.BlockColor.CORAL: return CORAL_GLOW
		Enums.BlockColor.AMBER: return AMBER_GLOW
		Enums.BlockColor.LEMON: return LEMON_GLOW
		Enums.BlockColor.MINT: return MINT_GLOW
		Enums.BlockColor.SKY: return SKY_GLOW
		Enums.BlockColor.LAVENDER: return LAVENDER_GLOW
		Enums.BlockColor.SPECIAL: return Color(1.0, 0.84, 0.0, 0.35)
	return Color.TRANSPARENT
