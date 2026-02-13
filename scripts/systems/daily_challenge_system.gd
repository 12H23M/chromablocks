class_name DailyChallengeSystem
## 일일 챌린지 시스템 — 매일 동일한 시드를 사용해 모든 플레이어가
## 같은 퍼즐을 풀 수 있도록 하는 정적 유틸리티 클래스.

const SECTION := "daily_challenge"


## 오늘 날짜 기반의 결정론적 시드 반환 (YYYYMMDD 형식)
static func get_today_seed() -> int:
	var now := Time.get_date_dict_from_system()
	return now["year"] * 10000 + now["month"] * 100 + now["day"]


## 오늘 날짜 문자열 반환 (저장 키로 사용)
static func _get_today_key() -> String:
	return str(get_today_seed())


## 오늘 이미 플레이했는지 확인
static func has_played_today() -> bool:
	var key := _get_today_key()
	return SaveManager.get_value(SECTION, key, -1) >= 0


## 일일 챌린지 결과 저장 (최고 점수만 유지)
static func save_daily_result(score: int) -> void:
	var key := _get_today_key()
	var current_best: int = SaveManager.get_value(SECTION, key, -1)
	if score > current_best:
		SaveManager.set_value(SECTION, key, score)

	# 마지막 플레이 날짜 갱신 (연속 기록 계산용)
	SaveManager.set_value(SECTION, "last_played_date", get_today_seed())
	SaveManager.flush()


## 오늘의 일일 최고 점수 반환
static func get_daily_best() -> int:
	var key := _get_today_key()
	var val: int = SaveManager.get_value(SECTION, key, -1)
	return maxi(val, 0)


## 연속 플레이 일수 계산 (오늘 포함)
static func get_streak() -> int:
	var today := get_today_seed()
	var streak := 0

	# 오늘부터 역순으로 연속 날짜 체크
	var check_date := today
	while true:
		var key := str(check_date)
		var val: int = SaveManager.get_value(SECTION, key, -1)
		if val < 0:
			break
		streak += 1
		check_date = _previous_date(check_date)

	return streak


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
