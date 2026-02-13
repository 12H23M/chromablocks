class_name AchievementSystem
## 업적 시스템 — 게임 내 업적 달성 추적 및 잠금해제

const SECTION := "achievements"

# 업적 정의: id -> {name, desc, threshold}
const ACHIEVEMENTS: Dictionary = {
	"first_game": {
		"name": "첫 걸음",
		"desc": "첫 번째 게임을 완료하세요",
		"threshold": 1,
	},
	"score_1000": {
		"name": "천 점 돌파",
		"desc": "1,000점 달성",
		"threshold": 1000,
	},
	"score_5000": {
		"name": "고수의 길",
		"desc": "5,000점 달성",
		"threshold": 5000,
	},
	"score_10000": {
		"name": "만점 마스터",
		"desc": "10,000점 달성",
		"threshold": 10000,
	},
	"score_50000": {
		"name": "전설의 플레이어",
		"desc": "50,000점 달성",
		"threshold": 50000,
	},
	"combo_3": {
		"name": "콤보 입문",
		"desc": "3 콤보 달성",
		"threshold": 3,
	},
	"combo_5": {
		"name": "콤보 마스터",
		"desc": "5 콤보 달성",
		"threshold": 5,
	},
	"combo_7": {
		"name": "콤보 신",
		"desc": "7 콤보 달성",
		"threshold": 7,
	},
	"lines_50": {
		"name": "라인 사냥꾼",
		"desc": "누적 50줄 클리어",
		"threshold": 50,
	},
	"lines_200": {
		"name": "라인 전문가",
		"desc": "누적 200줄 클리어",
		"threshold": 200,
	},
	"lines_500": {
		"name": "라인 마스터",
		"desc": "누적 500줄 클리어",
		"threshold": 500,
	},
	"perfect_clear": {
		"name": "완벽주의자",
		"desc": "퍼펙트 클리어 달성",
		"threshold": 1,
	},
	"games_10": {
		"name": "단골 손님",
		"desc": "10판 플레이",
		"threshold": 10,
	},
	"games_50": {
		"name": "열혈 팬",
		"desc": "50판 플레이",
		"threshold": 50,
	},
	"games_100": {
		"name": "중독자",
		"desc": "100판 플레이",
		"threshold": 100,
	},
	"level_5": {
		"name": "레벨 5",
		"desc": "레벨 5 달성",
		"threshold": 5,
	},
	"level_10": {
		"name": "레벨 10",
		"desc": "레벨 10 달성",
		"threshold": 10,
	},
	"level_20": {
		"name": "레벨 20",
		"desc": "레벨 20 달성",
		"threshold": 20,
	},
	"daily_3": {
		"name": "일일 도전자",
		"desc": "일일 챌린지 3일 연속 플레이",
		"threshold": 3,
	},
	"daily_7": {
		"name": "일일 챌린저",
		"desc": "일일 챌린지 7일 연속 플레이",
		"threshold": 7,
	},
	"color_match_10": {
		"name": "컬러 헌터",
		"desc": "누적 10회 컬러 매치",
		"threshold": 10,
	},
}


## 업적이 이미 달성되었는지 확인
static func is_unlocked(achievement_id: String) -> bool:
	return SaveManager.get_value(SECTION, achievement_id, false)


## 업적 잠금해제 (이미 해제된 경우 무시)
## 새로 해제된 경우 true 반환 (알림 표시용)
static func try_unlock(achievement_id: String) -> bool:
	if is_unlocked(achievement_id):
		return false
	SaveManager.set_value(SECTION, achievement_id, true)
	SaveManager.flush()
	return true


## 모든 해제된 업적 ID 목록 반환
static func get_unlocked_ids() -> Array:
	var result: Array = []
	for id in ACHIEVEMENTS:
		if is_unlocked(id):
			result.append(id)
	return result


## 전체 업적 중 달성 비율 (0.0~1.0)
static func get_completion_ratio() -> float:
	var unlocked := get_unlocked_ids().size()
	return float(unlocked) / float(ACHIEVEMENTS.size())


## 게임 종료 시 호출 — 모든 관련 업적 한번에 체크
## 새로 해제된 업적 ID 배열 반환
static func check_end_of_game(score: int, combo_max: int, level: int,
		total_lines: int, total_color_matches: int, is_perfect: bool,
		games_played: int, daily_streak: int) -> Array:
	var newly_unlocked: Array = []

	# 점수 업적
	if score >= 1000:
		if try_unlock("score_1000"):
			newly_unlocked.append("score_1000")
	if score >= 5000:
		if try_unlock("score_5000"):
			newly_unlocked.append("score_5000")
	if score >= 10000:
		if try_unlock("score_10000"):
			newly_unlocked.append("score_10000")
	if score >= 50000:
		if try_unlock("score_50000"):
			newly_unlocked.append("score_50000")

	# 콤보 업적
	if combo_max >= 3:
		if try_unlock("combo_3"):
			newly_unlocked.append("combo_3")
	if combo_max >= 5:
		if try_unlock("combo_5"):
			newly_unlocked.append("combo_5")
	if combo_max >= 7:
		if try_unlock("combo_7"):
			newly_unlocked.append("combo_7")

	# 레벨 업적
	if level >= 5:
		if try_unlock("level_5"):
			newly_unlocked.append("level_5")
	if level >= 10:
		if try_unlock("level_10"):
			newly_unlocked.append("level_10")
	if level >= 20:
		if try_unlock("level_20"):
			newly_unlocked.append("level_20")

	# 누적 라인 클리어 (커리어 통산 기록)
	var total_career_lines: int = SaveManager.get_value("stats", "total_lines", 0) + total_lines
	SaveManager.set_value("stats", "total_lines", total_career_lines)
	if total_career_lines >= 50:
		if try_unlock("lines_50"):
			newly_unlocked.append("lines_50")
	if total_career_lines >= 200:
		if try_unlock("lines_200"):
			newly_unlocked.append("lines_200")
	if total_career_lines >= 500:
		if try_unlock("lines_500"):
			newly_unlocked.append("lines_500")

	# 누적 컬러 매치
	var total_career_cm: int = SaveManager.get_value("stats", "total_color_matches", 0) + total_color_matches
	SaveManager.set_value("stats", "total_color_matches", total_career_cm)
	if total_career_cm >= 10:
		if try_unlock("color_match_10"):
			newly_unlocked.append("color_match_10")

	# 퍼펙트 클리어
	if is_perfect:
		if try_unlock("perfect_clear"):
			newly_unlocked.append("perfect_clear")

	# 게임 플레이 횟수
	if try_unlock("first_game"):
		newly_unlocked.append("first_game")
	if games_played >= 10:
		if try_unlock("games_10"):
			newly_unlocked.append("games_10")
	if games_played >= 50:
		if try_unlock("games_50"):
			newly_unlocked.append("games_50")
	if games_played >= 100:
		if try_unlock("games_100"):
			newly_unlocked.append("games_100")

	# 일일 챌린지 연속 기록
	if daily_streak >= 3:
		if try_unlock("daily_3"):
			newly_unlocked.append("daily_3")
	if daily_streak >= 7:
		if try_unlock("daily_7"):
			newly_unlocked.append("daily_7")

	SaveManager.flush()
	return newly_unlocked
