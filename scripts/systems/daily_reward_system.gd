class_name DailyRewardSystem
## 일일 출석 보상 시스템 — 7일 주기로 매일 출석 시 보상을 지급하는
## 정적 유틸리티 클래스.

const SECTION := "daily_reward"

## 7일 사이클 보상 정의
## score_multiplier: 다음 게임 점수 배율, bonus_swaps: 다음 게임 추가 Swap 횟수
const REWARDS: Dictionary = {
	1: {"score_multiplier": 1.2, "bonus_swaps": 0},
	2: {"score_multiplier": 1.2, "bonus_swaps": 0},
	3: {"score_multiplier": 1.0, "bonus_swaps": 1},
	4: {"score_multiplier": 1.3, "bonus_swaps": 0},
	5: {"score_multiplier": 1.0, "bonus_swaps": 1},
	6: {"score_multiplier": 1.5, "bonus_swaps": 0},
	7: {"score_multiplier": 2.0, "bonus_swaps": 1},
}


## 오늘 출석 체크 — 보상 딕셔너리 반환. 이미 출석한 경우 빈 딕셔너리 반환
static func check_in() -> Dictionary:
	if has_checked_in_today():
		return {}

	var today := _get_today_seed()
	var last_checkin: int = SaveManager.get_value(SECTION, "last_checkin", 0)
	var cycle_day: int = SaveManager.get_value(SECTION, "cycle_day", 0)
	var streak: int = SaveManager.get_value(SECTION, "streak", 0)

	# 어제 출석했는지 확인
	var yesterday := _previous_date(today)
	if last_checkin == yesterday:
		# 연속 출석 — streak 증가, 사이클 진행
		streak += 1
		cycle_day = (cycle_day % 7) + 1
	else:
		# 연속 끊김 또는 첫 출석 — 리셋
		streak = 1
		cycle_day = 1

	# 저장
	SaveManager.set_value(SECTION, "last_checkin", today)
	SaveManager.set_value(SECTION, "cycle_day", cycle_day)
	SaveManager.set_value(SECTION, "streak", streak)
	SaveManager.flush()

	# 보상 딕셔너리 반환
	var reward: Dictionary = REWARDS[cycle_day]
	return {
		"score_multiplier": reward["score_multiplier"],
		"bonus_swaps": reward["bonus_swaps"],
		"day": cycle_day,
	}


## 오늘 이미 출석했는지 확인
static func has_checked_in_today() -> bool:
	var last_checkin: int = SaveManager.get_value(SECTION, "last_checkin", 0)
	return last_checkin == _get_today_seed()


## 현재 사이클 내 일차 반환 (1~7)
static func get_current_day() -> int:
	var day: int = SaveManager.get_value(SECTION, "cycle_day", 0)
	if day <= 0 or day > 7:
		return 1
	return day


## 연속 출석 일수 반환
static func get_streak() -> int:
	var streak: int = SaveManager.get_value(SECTION, "streak", 0)
	return maxi(streak, 0)


## 오늘 날짜를 YYYYMMDD 정수로 반환
static func _get_today_seed() -> int:
	var now := Time.get_date_dict_from_system()
	return now["year"] * 10000 + now["month"] * 100 + now["day"]


## 오늘 날짜 문자열 반환 (SaveManager 키 호환용)
static func _get_today_key() -> String:
	return str(_get_today_seed())


## YYYYMMDD 형식 날짜에서 전날 날짜 계산
static func _previous_date(date_seed: int) -> int:
	var year := date_seed / 10000
	var month := (date_seed % 10000) / 100
	var day := date_seed % 100

	day -= 1
	if day <= 0:
		month -= 1
		if month <= 0:
			year -= 1
			month = 12
		day = _days_in_month(year, month)

	return year * 10000 + month * 100 + day


## 해당 월의 일수 반환 (윤년 처리 포함)
static func _days_in_month(year: int, month: int) -> int:
	match month:
		1, 3, 5, 7, 8, 10, 12:
			return 31
		4, 6, 9, 11:
			return 30
		2:
			if year % 4 == 0 and (year % 100 != 0 or year % 400 == 0):
				return 29
			return 28
	return 30
