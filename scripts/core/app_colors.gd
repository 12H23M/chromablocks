extends Node

# 기본 블록 색상 (default 테마 — Prismatic Pop)
var CORAL := Color("FF6B6B")           # 리빙 코랄
var CORAL_LIGHT := Color("FF9E9E")
var CORAL_GLOW := Color(Color("FF6B6B"), 0.40)

var AMBER := Color("4ECDC4")           # 스카이 블루 (Enums.BlockColor.AMBER 유지)
var AMBER_LIGHT := Color("7EDED8")
var AMBER_GLOW := Color(Color("4ECDC4"), 0.40)

var LEMON := Color("FFE66D")           # 선샤인 옐로우
var LEMON_LIGHT := Color("FFF0A0")
var LEMON_GLOW := Color(Color("FFE66D"), 0.40)

var MINT := Color("A8A4FF")            # 라벤더 블록 (Enums.BlockColor.MINT 유지)
var MINT_LIGHT := Color("C8C5FF")
var MINT_GLOW := Color(Color("A8A4FF"), 0.40)

var SKY := Color("6BCB77")             # 민트 프레시 (Enums.BlockColor.SKY 유지)
var SKY_LIGHT := Color("98E0A0")
var SKY_GLOW := Color(Color("6BCB77"), 0.40)

var LAVENDER := Color("FF9A9E")        # 피치 (Enums.BlockColor.LAVENDER 유지)
var LAVENDER_LIGHT := Color("FFBFC2")
var LAVENDER_GLOW := Color(Color("FF9A9E"), 0.40)

var SPECIAL := Color("FFD700")

# Dark Theme UI — Midnight Prism
var BACKGROUND := Color("1C1C2E")      # 소프트 다크
var CARD_SURFACE := Color("252540")     # 미드 네이비
var CARD_BORDER := Color("3D3D5C")
var ACCENT := Color("A8A4FF")           # 라벤더 악센트
var ACCENT_TEXT := Color("C8C5FF")
var TEXT_PRIMARY := Color("F0F0FF")     # 스타라이트
var TEXT_SECONDARY := Color("8B8FB0")   # 문스톤
var TEXT_MUTED := Color("5A5A80")
var BORDER := Color("3D3D5C")
var GRID_LINE := Color("2E2E4A")

# Score popup accents
var GOLDEN := Color("FFD700")
var SAGE_GREEN := Color("6BCB77")

# Ghost/highlight
var HIGHLIGHT_VALID := Color(Color("6BCB77"), 0.30)
var HIGHLIGHT_INVALID := Color(Color("FF6B6B"), 0.30)

# Empty cell (dark well)
var EMPTY_CELL := Color(Color("2E2E4A"), 0.15)
var EMPTY_BORDER := Color(Color("2E2E4A"), 0.10)

# Board
var BOARD_BG := Color("252540")         # 미드 네이비
var BOARD_BORDER := Color(Color("3D3D5C"), 0.3)

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
