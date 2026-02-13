class_name TestDailyChallenge
extends RefCounted
## DailyChallengeSystem 유닛 테스트
## 주의: SaveManager 의존 메서드(has_played_today, save_daily_result 등)는
## 오토로드 없이 실행 불가하므로 테스트에서 제외합니다.

const TEST_NAME := "TestDailyChallenge"


# ── 테스트 케이스 ──

## get_today_seed()가 YYYYMMDD 형식 정수를 반환해야 한다
func test_today_seed_format() -> String:
	var seed_val := DailyChallengeSystem.get_today_seed()

	# 최소 8자리 숫자여야 한다 (20260101 ~ 99991231)
	var r := TestRunner.assert_true(seed_val >= 20000101,
		"시드가 20000101 이상이어야 합니다: %d" % seed_val)
	if r != "":
		return r
	r = TestRunner.assert_true(seed_val <= 99991231,
		"시드가 99991231 이하여야 합니다: %d" % seed_val)
	if r != "":
		return r

	# YYYYMMDD 파싱 검증
	var year := seed_val / 10000
	var month := (seed_val % 10000) / 100
	var day := seed_val % 100

	r = TestRunner.assert_true(year >= 2024 and year <= 9999,
		"연도 범위: %d" % year)
	if r != "":
		return r
	r = TestRunner.assert_true(month >= 1 and month <= 12,
		"월 범위: %d" % month)
	if r != "":
		return r
	r = TestRunner.assert_true(day >= 1 and day <= 31,
		"일 범위: %d" % day)
	return r


## _previous_date가 월 경계를 올바르게 처리해야 한다
func test_previous_date_month_boundary() -> String:
	# 3월 1일 → 2월 28일 (평년 2025)
	var prev := DailyChallengeSystem._previous_date(20250301)
	var r := TestRunner.assert_eq(prev, 20250228,
		"2025-03-01의 전날 = 2025-02-28")
	if r != "":
		return r

	# 1월 1일 → 전년도 12월 31일
	prev = DailyChallengeSystem._previous_date(20250101)
	r = TestRunner.assert_eq(prev, 20241231,
		"2025-01-01의 전날 = 2024-12-31")
	if r != "":
		return r

	# 5월 1일 → 4월 30일
	prev = DailyChallengeSystem._previous_date(20250501)
	r = TestRunner.assert_eq(prev, 20250430,
		"2025-05-01의 전날 = 2025-04-30")
	return r


## _previous_date가 윤년 2월을 올바르게 처리해야 한다
func test_previous_date_leap_year() -> String:
	# 윤년 2024: 3월 1일 → 2월 29일
	var prev := DailyChallengeSystem._previous_date(20240301)
	var r := TestRunner.assert_eq(prev, 20240229,
		"윤년 2024-03-01의 전날 = 2024-02-29")
	if r != "":
		return r

	# 평년 2023: 3월 1일 → 2월 28일
	prev = DailyChallengeSystem._previous_date(20230301)
	r = TestRunner.assert_eq(prev, 20230228,
		"평년 2023-03-01의 전날 = 2023-02-28")
	if r != "":
		return r

	# 윤년 2000 (400으로 나누어짐): 3월 1일 → 2월 29일
	prev = DailyChallengeSystem._previous_date(20000301)
	r = TestRunner.assert_eq(prev, 20000229,
		"윤년 2000-03-01의 전날 = 2000-02-29")
	if r != "":
		return r

	# 평년 1900 (100으로 나누어지지만 400은 아님): 3월 1일 → 2월 28일
	prev = DailyChallengeSystem._previous_date(19000301)
	r = TestRunner.assert_eq(prev, 19000228,
		"평년 1900-03-01의 전날 = 1900-02-28")
	return r
