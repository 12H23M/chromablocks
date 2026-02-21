class_name ThemeSystem
## 블록 테마 시스템 — 코스메틱 블록 팔레트(테마) 관리
## 플레이어가 여러 색상 팔레트 중 선택할 수 있다.

const SECTION := "settings"
const KEY := "theme"
const DEFAULT_THEME := "default"

# 테마 정의
# 각 테마의 colors는 Enums.BlockColor 7개 값에 대응
# 각 색상은 {"bg": Color, "light": Color, "bright": Color} 구조
const THEMES: Dictionary = {
	"default": {
		"name": "기본",
		"colors": {
			Enums.BlockColor.CORAL: {
				"bg": Color("FF8A8A"),
				"light": Color("FFB8B8"),
				"bright": Color("FF8A8A"),
			},
			Enums.BlockColor.AMBER: {
				"bg": Color("FFB347"),
				"light": Color("FFD08A"),
				"bright": Color("FFB347"),
			},
			Enums.BlockColor.LEMON: {
				"bg": Color("FFD93D"),
				"light": Color("FFE57A"),
				"bright": Color("FFD93D"),
			},
			Enums.BlockColor.MINT: {
				"bg": Color("6BCB77"),
				"light": Color("A8E6A3"),
				"bright": Color("6BCB77"),
			},
			Enums.BlockColor.SKY: {
				"bg": Color("4FC3F7"),
				"light": Color("8AD4F8"),
				"bright": Color("4FC3F7"),
			},
			Enums.BlockColor.LAVENDER: {
				"bg": Color("9B8EC4"),
				"light": Color("C5BBE0"),
				"bright": Color("9B8EC4"),
			},
			Enums.BlockColor.SPECIAL: {
				"bg": Color("FFD700"),
				"light": Color("FFD700"),
				"bright": Color("FFD700"),
			},
		},
		"unlocked": true,
	},
	"pastel": {
		"name": "파스텔",
		"colors": {
			Enums.BlockColor.CORAL: {
				"bg": Color("F8A4B8"),
				"light": Color("FCD5DF"),
				"bright": Color("F8A4B8"),
			},
			Enums.BlockColor.AMBER: {
				"bg": Color("F7C97E"),
				"light": Color("FDEACC"),
				"bright": Color("F7C97E"),
			},
			Enums.BlockColor.LEMON: {
				"bg": Color("F5E6A3"),
				"light": Color("FBF4D6"),
				"bright": Color("F5E6A3"),
			},
			Enums.BlockColor.MINT: {
				"bg": Color("A8E6CF"),
				"light": Color("D4F5E4"),
				"bright": Color("A8E6CF"),
			},
			Enums.BlockColor.SKY: {
				"bg": Color("A8D8EA"),
				"light": Color("D4EEF5"),
				"bright": Color("A8D8EA"),
			},
			Enums.BlockColor.LAVENDER: {
				"bg": Color("C3B1E1"),
				"light": Color("E1D8F0"),
				"bright": Color("C3B1E1"),
			},
			Enums.BlockColor.SPECIAL: {
				"bg": Color("FFE4B5"),
				"light": Color("FFF2DA"),
				"bright": Color("FFE4B5"),
			},
		},
		"unlocked": true,
	},
	"neon": {
		"name": "네온",
		"colors": {
			Enums.BlockColor.CORAL: {
				"bg": Color("FF1744"),
				"light": Color("FF616F"),
				"bright": Color("FF1744"),
			},
			Enums.BlockColor.AMBER: {
				"bg": Color("FF9100"),
				"light": Color("FFB74D"),
				"bright": Color("FF9100"),
			},
			Enums.BlockColor.LEMON: {
				"bg": Color("EEFF41"),
				"light": Color("F4FF81"),
				"bright": Color("EEFF41"),
			},
			Enums.BlockColor.MINT: {
				"bg": Color("00E676"),
				"light": Color("69F0AE"),
				"bright": Color("00E676"),
			},
			Enums.BlockColor.SKY: {
				"bg": Color("00E5FF"),
				"light": Color("84FFFF"),
				"bright": Color("00E5FF"),
			},
			Enums.BlockColor.LAVENDER: {
				"bg": Color("D500F9"),
				"light": Color("EA80FC"),
				"bright": Color("D500F9"),
			},
			Enums.BlockColor.SPECIAL: {
				"bg": Color("FFEA00"),
				"light": Color("FFFF8D"),
				"bright": Color("FFEA00"),
			},
		},
		"unlock_condition": "score_5000",
	},
	"ocean": {
		"name": "오션",
		"colors": {
			Enums.BlockColor.CORAL: {
				"bg": Color("FF6B6B"),
				"light": Color("FFA8A8"),
				"bright": Color("FF6B6B"),
			},
			Enums.BlockColor.AMBER: {
				"bg": Color("48BFE3"),
				"light": Color("89D4F0"),
				"bright": Color("48BFE3"),
			},
			Enums.BlockColor.LEMON: {
				"bg": Color("72EFDD"),
				"light": Color("B5F8EE"),
				"bright": Color("72EFDD"),
			},
			Enums.BlockColor.MINT: {
				"bg": Color("56CFE1"),
				"light": Color("9AE3EE"),
				"bright": Color("56CFE1"),
			},
			Enums.BlockColor.SKY: {
				"bg": Color("5390D9"),
				"light": Color("90B8E8"),
				"bright": Color("5390D9"),
			},
			Enums.BlockColor.LAVENDER: {
				"bg": Color("6930C3"),
				"light": Color("A47FDB"),
				"bright": Color("6930C3"),
			},
			Enums.BlockColor.SPECIAL: {
				"bg": Color("64DFDF"),
				"light": Color("B0EFEF"),
				"bright": Color("64DFDF"),
			},
		},
		"unlock_condition": "level_10",
	},
	"sunset": {
		"name": "선셋",
		"colors": {
			Enums.BlockColor.CORAL: {
				"bg": Color("E63946"),
				"light": Color("F08890"),
				"bright": Color("E63946"),
			},
			Enums.BlockColor.AMBER: {
				"bg": Color("F4845F"),
				"light": Color("F9B9A3"),
				"bright": Color("F4845F"),
			},
			Enums.BlockColor.LEMON: {
				"bg": Color("F7B267"),
				"light": Color("FBD7AB"),
				"bright": Color("F7B267"),
			},
			Enums.BlockColor.MINT: {
				"bg": Color("D4A373"),
				"light": Color("E8CBB0"),
				"bright": Color("D4A373"),
			},
			Enums.BlockColor.SKY: {
				"bg": Color("E07A5F"),
				"light": Color("EDB4A3"),
				"bright": Color("E07A5F"),
			},
			Enums.BlockColor.LAVENDER: {
				"bg": Color("BC4749"),
				"light": Color("D6908D"),
				"bright": Color("BC4749"),
			},
			Enums.BlockColor.SPECIAL: {
				"bg": Color("F2CC8F"),
				"light": Color("F9E5C5"),
				"bright": Color("F2CC8F"),
			},
		},
		"unlock_condition": "games_50",
	},
}


## 현재 선택된 테마 ID 반환
static func get_current_theme() -> String:
	var theme_id: String = SaveManager.get_value(SECTION, KEY, DEFAULT_THEME)
	# 저장된 테마가 유효하지 않으면 기본 테마 사용
	if not THEMES.has(theme_id):
		return DEFAULT_THEME
	return theme_id


## 테마 변경 및 SaveManager에 저장
static func set_theme(theme_id: String) -> void:
	if not THEMES.has(theme_id):
		return
	if not is_unlocked(theme_id):
		return
	SaveManager.set_value(SECTION, KEY, theme_id)
	SaveManager.flush()


## 업적 기반 잠금 해제 확인
static func is_unlocked(theme_id: String) -> bool:
	if not THEMES.has(theme_id):
		return false
	var theme: Dictionary = THEMES[theme_id]
	# unlocked: true 가 명시된 경우 항상 해제
	if theme.get("unlocked", false):
		return true
	# unlock_condition 이 있으면 해당 업적 달성 여부 확인
	var condition: String = theme.get("unlock_condition", "")
	if condition.is_empty():
		return false
	return AchievementSystem.is_unlocked(condition)


## 테마 색상 딕셔너리 반환 (BlockColor -> {bg, light, bright})
static func get_theme_colors(theme_id: String) -> Dictionary:
	if not THEMES.has(theme_id):
		return THEMES[DEFAULT_THEME]["colors"]
	return THEMES[theme_id]["colors"]


## 모든 테마 정보 배열 반환
## 각 항목: {id, name, unlocked, unlock_condition, colors}
static func get_all_themes() -> Array:
	var result: Array = []
	for theme_id in THEMES:
		var theme: Dictionary = THEMES[theme_id]
		result.append({
			"id": theme_id,
			"name": theme.get("name", theme_id),
			"unlocked": is_unlocked(theme_id),
			"unlock_condition": theme.get("unlock_condition", ""),
			"colors": theme["colors"],
		})
	return result


## 해제 조건에 대한 사람이 읽을 수 있는 설명 반환
static func get_unlock_description(condition: String) -> String:
	if condition.is_empty():
		return ""
	# AchievementSystem 에서 해당 업적 설명을 가져옴
	if AchievementSystem.ACHIEVEMENTS.has(condition):
		return AchievementSystem.ACHIEVEMENTS[condition]["desc"]
	return condition
